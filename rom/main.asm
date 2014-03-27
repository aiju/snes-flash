.INCLUDE "dat.inc"

.SECTION "CODE"
main:
	jsr consinit
	rep #$30
	ldx #title
	jsr puts
	jsr box
	ldx #busystr
	jsr puts
	jsr busy
	bcs fatal
	
	rep #$20
	stz sdblk
	stz sdblk+2
	lda #$0100
	sta sdaddr
	jsr sdread
	bcs fatal
	
	rep #$30
	jsr endbox
	ldx #$0505
	jsr move
	lda #$0200
	sta tmp+1
	lda #$8000
	sta tmp
	sep #$20
	ldy #$0
-	lda [tmp],y
	jsr putbyte
	lda #$20
	jsr putc
	iny
	cpy #10
	bne -
	
	rts

fatal:	jmp sdfatal

title: .ASC 10, " SNES FLASH CART", 0
busystr: .ASC "BUSY", 0
nocard: .ASC "NO CARD", 0
error: .ASC "CARD ERROR", 10, "CMD ", 0
response: .ASC 10, "RESPONSE ", 0
.ENDS
