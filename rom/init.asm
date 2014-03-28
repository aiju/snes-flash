.INCLUDE "dat.inc"

.SNESEMUVECTOR
COP	noop
ABORT	noop
NMI	noop
RESET	init
IRQBRK	noop
.ENDEMUVECTOR

.SNESNATIVEVECTOR
COP	noop
ABORT	noop
NMI	vblank
IRQ	noop
BRK	noop
.ENDNATIVEVECTOR


.SECTION "CODE"
init:
	sei
	clc
	xce
	rep #$38
	ldx #$1fff
	txs
	phk
	plb
	lda #$0
	tcd
	sep #$20
	lda #$8f
	sta $2100
	stz $210d
	stz $211b
	ldx #$2101
-	stz $00,x
	inx
	cpx #$2134
	bne -
	lda #$80
	sta $2115
	lda #$ff
	sta $4201
	stz $420d

	stz $2116
	stz $2117
	ldx #$8000
-	stz $2118
	stz $2119
	dex
	bne -

	stz $2116
	lda #$41
	sta $2117
	lda #96
	sta tmp
	ldx #font
--	ldy #8
-	lda $00,x
	sta $2118
	lda $08,x
	sta $2119
	inx
	dey
	bne -
	rep #$21
	txa
	adc #$8
	tax
	sep #$20
	dec tmp
	bne --
	
	lda #HIROM
	sta dmactrl
	sta DMACTRL
	
	rep #$20
	lda #$FFFF
	sta ROMMASK
	lda #$FE80
	sta inf

	jsr main
loop:	wai
	pea $0000
	plb
	sep #$20
	lda #$0
	sta $4200
	jml inf

font:
.incbin "ascii.chr"
.ENDS
