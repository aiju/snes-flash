.INCLUDE "dat.inc"

.SECTION "CODE"
flash:
	rep #$30
	jsr box
	ldx #_flashname
	ldy #buf2
	lda #26
	mvn 0, 0
	jsr openfile
	bcc +
-	jsr box
	ldx #_nofirm
	jsr puts
	jmp confirm
+	ldx #_flashmsg
	jsr puts
	jsr waitkey
	lda #BTNA
	beq +
	lda $4218
	bit #$F
	bne +
	and #BTNLR
	eor #BTNLR
	bne +
	bra ++
+	jmp endbox
++	ldy #$1A
	lda [dent],y
	sta clust
	ldy #$14
	lda [dent],y
	sta clust+2
	ora clust
	beq -
	ldy #$1C
	lda [dent],y
	sta size
	bne -
	ldy #$1E
	lda [dent],y
	sta size+2
	cmp #$8
	bne -
	stz sdaddr
	jsr readfile
	bcc _try
	rts
_try	jsr endbox
	jsr clrscreen
	ldx #$0300
	jsr move
	ldx #_powermsg
	jsr puts
	
	sep #$20
	jsr ceoff
	jsr readid
	jsr putword
	jsr clrwp
	jsr erase
	jsr program
	ldx #$0300
	jsr move
	ldx #_vermsg
	jsr puts
	jsr verify
	bcs _try
	jsr clrscreen
	ldx #$0300
	jsr move
	ldx #_success
	jsr puts
	jmp loop


ceon:
	lda dmactrl
	ora #SPICE
	sta DMACTRL
	rts

ceoff:
	lda dmactrl
	sta DMACTRL
	rts

readid:
	jsr ceon
	lda #$AB
	sta SPI
	stz SPI
	stz SPI
	stz SPI
	stz SPI
	lda SPI
	stz SPI
	xba
	lda SPI
	pha
	jsr ceoff
	pla
	rts

_busy:
	jsr ceon
	lda #$05
	sta SPI
-	stz SPI
	lda SPI
	and #$1
	bne -
	jmp ceoff

we:
	jsr ceon
	lda #$06
	sta SPI
	jsr ceoff
	rts

clrwp:
	jsr we
	jsr ceon
	lda #$1
	sta SPI
	stz SPI
	jsr ceoff
	rts

erase:
	jsr we
	jsr ceon
	lda #$C7
	sta SPI
	jsr ceoff
	jmp _busy

program:
	jsr bar
	rep #$30
	lda #BARW
	sta progst
	stz ptr
	sep #$20
	lda #$40
	sta ptr+2

	jsr we
	jsr ceon
	lda #$AD
	sta SPI
	stz SPI
	stz SPI
	stz SPI
	
	ldy #$0
	bra +
-	jsr ceon
	lda #$AD
	sta SPI
+	lda [ptr],y
	sta SPI
	iny
	lda [ptr],y
	sta SPI
	iny
	jsr ceoff
	cpy #$200
	bne -
	jsr showprog
	ldy #$0
	rep #$20
	lda ptr+1
	clc
	adc #$2
	sta ptr+1
	cmp #$4800
	sep #$20
	bne -
	jsr ceon
	lda #$04
	sta SPI
	jsr ceoff
	rts

verify:
	jsr ceon
	lda #$03
	sta SPI
	stz SPI
	stz SPI
	stz SPI
	rep #$20
	stz ptr
	sep #$20
	lda #$40
	sta ptr+2
	ldy #$0
-	stz SPI
	lda [ptr],y
	cmp SPI
	bne +
	iny
	cpy #$200
	bne -
	jsr showprog
	ldy #$0
	rep #$20
	lda ptr+1
	clc
	adc #$2
	sta ptr+1
	cmp #$4800
	sep #$20
	bne -
	jsr ceoff
	clc
	rts
+	pha
	phy
	jsr ceoff
	ldx #$0300
	jsr move
	ldx #_vererr
	jsr puts
	rep #$20
	pla
	clc
	adc ptr
	sta ptr
	bcc +
	inc ptr+2
+	lda ptr+2
	and #$3F
	jsr putbyte
	lda ptr
	jsr putword
	ldx #_readmsg
	jsr puts
	sep #$20
	lda SPI
	jsr putbyte
	ldx #_insteadmsg
	jsr puts
	pla
	jsr putbyte
	jsr waitkey
	sec
	rts

_flashmsg: .ASC "TO FLASH FIRMWARE", 10, "PRESS L+R+A", 10, "TO ABORT PRESS B", 10, 0
_powermsg: .ASC "   FLASHING ...", 10, "   DO NOT RESET", 10, "   OR REMOVE POWER", 10, "   CHIP ID: ", 0
_vermsg: .ASC "   VERIFYING ...", 0
_vererr:  .ASC "   DATA FAILED TO VERIFY", 10, "   PRESS A TO TRY AGAIN", 10, "   DO NOT REMOVE POWER!", 10, "   AT ", 0
_success: .ASC "   SUCCESS!", 10, "   CYCLE POWER TO LOAD", 10, "   NEW FIRMWARE", 0
_readmsg: .ASC " READ ", 0
_insteadmsg: .ASC 10, "   INSTEAD OF ", 0
_nofirm: .ASC "SNESCART.BIN", 10, "NOT FOUND", 10, "OR INVALID", 0
_flashname: .DB 'S', 0, 'N', 0, 'E', 0, 'S', 0, 'C', 0, 'A', 0, 'R', 0, 'T', 0, '.', 0, 'B', 0, 'I', 0, 'N', 0, 0, 0
.ENDS
