.INCLUDE "dat.inc"

.SECTION "CODE"
fatal:	jmp sdfatal
main:
	jsr consinit
	rep #$30
	ldx #title
	jsr puts
	jsr box
	ldx #busystr
	jsr puts
	jsr busy
	bcc +
	sep #$20
	lda #RESETCMD
	sta SDCMD
	rep #$20
	jsr busy
+	jsr mbr
	jsr initfat
	jsr endbox
	jsr redraw

poll	rep #$30
-	lda btn
	beq -
	pea poll-1
	bit #BTNUP
	bne _up
	bit #BTNDOWN
	bne _down
	bit #BTNA
	bne loadgame
	bit #BTNB
	beq +
	jmp parent
+	rts
_up	ldy sel
	jsr prevshown
	sty sel
	jmp redraw
_down	ldy sel
	jsr nextshown
	sty sel
	jmp redraw

loadgame:
	rep #$30
	jsr box
	ldx #busystr
	jsr puts
	sep #$20
	stz gamectl
	jsr readheader
	bcs +
	sep #$20
	lda HEAD+$1D5
	and #$EF
	cmp #$20
	beq ++
	lda #HIROM
	sta gamectl
	jsr readheader
	bcs +
	sep #$20
	lda HEAD+$1D5
	and #$EF
	cmp #$21
	beq ++
	jsr box
	rep #$10
	ldx #hdmsg
	jsr puts
	jmp confirm
+	rts
++	rep #$30
	jsr box
	ldx #(HEAD+$1C0)&$FFFF
	ldy #buf
	lda #20
	mvn $00, HEAD>>16
	lda #$000A
	sta buf+21
	ldx #buf
	jsr puts
	jsr romregion
	jsr waitkey
	and #BTNA
	beq +
	jsr box
	ldx #busystr
	jsr puts
	jsr readrom
	jsr endbox
	rep #$30
	ldx #gamestart
	ldy #buf
	lda #gameend-gamestart
	mvn $00, $00

	sep #$20
	stz $4200
	stz $420c
	lda $4210

	rep #$20
	sep #$10
	lda HEAD+$1D7
	tax
	jsr mask
	sta ROMMASK
	jmp buf
+	rts

romregion:
	php
	sep #$20
	rep #$10
	lda HEAD+$1D9
	cmp #$E
	bcc +
	ldx #_unk
-	jsr puts
	plp
	rts
+	cmp #$D
	bne +
	cmp #$2
	bcc +
	ldx #_pal
	bra -
+	ldx #_ntsc
	bra -
_unk:	.ASC "???", 10, 0
_pal:	.ASC "PAL", 10, 0
_ntsc:	.ASC "NTSC", 10, 0

mask:
	rep #$20
	lda #$4
-	asl
	dex
	bne -
	dea
	rts

waitkey:
	php
	rep #$20
	wai
	lda #(BTNA|BTNB)
-	bit btn
	beq -
	lda btn
	wai
	plp
	rts
	
confirm:
	jsr waitkey
	jsr endbox
	sec
	rts
	
gamestart:
	sep #$20
	lda gamectl
	ora #ROMDIS
	sta DMACTRL
	sec
	xce
	jmp ($FFFC)
gameend:

title: .ASC 10, " SNES FLASH CART", 0
busystr: .ASC "BUSY", 10, 0
nocard: .ASC "NO CARD", 0
error: .ASC "CARD ERROR", 10, "CMD $", 0
response: .ASC 10, "RESPONSE ", 0
hdmsg: .ASC "INVALID HEADER", 0
.ENDS
