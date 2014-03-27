.INCLUDE "dat.inc"

digits: .db "0123456789abcdef"
palette: .dw 0, $FFFF, $FFFF, $FFFF, 0, $FFFF, $FFFF, $FFFF

consinit:
	sep #$30
	stz attrib
	stz window
	rep #$10
	lda #<pic
	sta pos
	lda #>pic
	sta pos+1
	lda #$7F
	sta pos+2
	rep #$30
	ldx #PICSIZ
	lda #$00
-	sta [pos]
	inc pos
	inc pos
	dex
	bne -
	lda #pic & $FFFF
	sta pos
	
	stz $2121
	stz $4300
	lda #$22
	sta $4301
	stz $4304
	rep #$20
	lda #palette
	sta $4302
	lda #16
	sta $4305
	sep #$20
	lda #1
	sta $420b

	lda #$ff
	sta $2112
	sta $2112

	stz $2116
	stz $2117

	lda #$1
	sta $2105
	lda #$4
	sta $210c
	lda #$4
	sta $212c

	lda #$20
	sta $2131
	lda #$EC
	sta $2132
	lda #$20
	sta $2125
	lda #$01
	sta $4370
	lda #$26
	sta $4371
	lda #<windowdata
	sta $4372
	lda #>windowdata
	sta $4373
	stz $4374
	lda #$80
	sta $420c

	lda #$80
	sta $4200

	lda #$f
	sta $2100
	rts

vblank:
	rep #$30
	pha
	phx
	phy
	phb
	phk
	plb
	
	jsr region

	stz $2116
	stz $2117
	lda #$1801
	sta $4300
	lda #$7F00
	sta $4303
	lda #pic & $FFFF
	sta $4302
	lda #PICSIZ
	sta $4305
	sep #$20
	lda #$01
	sta $420b

	lda window
	and #$20
	eor #$30
	sta $2130

	rep #$30
	plb
	ply
	plx
	pla
	rti
noop:
	rti

region:
	rep #$10
	sep #$20
	lda #$00
	xba
	lda $213f
	and #$10
	lsr
	rep #$20
	adc #_reg
	tax
	ldy #(pic + REGLOC) & $FFFF
	lda #7
	phb
	mvn $7F, $00
	plb
	rts
_reg:	.DB 'N', 0, 'T', 0, 'S', 0, 'C', 0
	.DB 'P', 0, 'A', 0, 'L', 0, 0, 0

return:
	php
	rep #$20
	stz pos
	plp
	rts

putc:
	php
	sep #$20
	cmp #$A
	beq newline
	xba
	lda attrib
	xba
	rep #$20
	sta [pos]
	inc pos
	inc pos
	plp
	rts
newline:
	rep #$20
	lda pos
	clc
	adc #$40
	and #$FFC0
	sep #$20
	bit window
	rep #$20
	bpl +
	clc
	adc #BOXL*2
+	sta pos
	plp
	rts

puts:
	php
	rep #$20
	pha
	sep #$20
-	lda $00,x
	beq +
	jsr putc
	inx
	bra -
+	rep #$20
	pla
	plp
	rts

putst:
	pla
	plx
	pha
	jmp puts

putbyte:
	pha
	php
	sep #$30
	pha
	lsr
	lsr
	lsr
	lsr
	tax
	lda digits.w,x
	jsr putc
	pla
	and #$F
	tax
	lda digits.w,x
	jsr putc
	plp
	pla
	rts
	
putword:
	php
	rep #$20
	pha
	xba
	jsr putbyte
	xba
	jsr putbyte
	pla
	plp
	rts

blanks:
	php
	sep #$30
	ldx #$20
-	lda #$20
	jsr putc
	dex
	bne -
	plp
	rts

move:
	php
	rep #$20
	txa
	sep #$20
	sta tmp
	lda #$00
	sta tmp+1
	xba
	rep #$20
	asl
	asl
	asl
	asl
	asl
	clc
	adc tmp
	asl
	clc
	adc #pic & $FFFF
	sta pos
	plp
	rts

box:
	php
	sep #$20
	lda window
	bne +
	dec window
	rep #$30
	lda #PICSIZ-1
	ldx #pic & $FFFF
	ldy #picbak & $FFFF
	phb
	mvn $7F, $7F
	plb
+	ldx #BOX
	phx
	sep #$20
	lda #BOXH
	sta tmp2
--	jsr move
	ldy #BOXW
-	lda #$00
	jsr putc
	dey
	bne -
	rep #$20
	txa
	clc
	adc #$100
	tax
	sep #$20
	dec tmp2
	bne --
	plx
	jsr move
	plp
	rts

endbox:
	php
	sep #$20
	stz window
	rep #$30
	lda #PICSIZ-1
	ldx #picbak & $FFFF
	ldy #pic & $FFFF
	phb
	mvn $7F, $7F
	plb
	plp
	rts

windowdata:
	.db BOXT*8-1, $FF, $00
	.db BOXH*8, BOXL*8, (BOXL+BOXW)*8
	.db $01, $FF, $00
	.db $00

die:
	jsr box
	rep #$10
	plx
	jsr puts
	jmp loop

nope:
	rep #$10
	ldx #_error
	jsr puts
	jmp loop
_error: .ASC 10, "ERROR", 0
