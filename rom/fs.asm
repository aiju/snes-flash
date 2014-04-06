.INCLUDE "dat.inc"

.SECTION "CODE"
mbr:
	sep #$20
	stz cardsw
	lda #MEMMODE
	sta sdmode
	rep #$30
	ldx #_mbrmsg
	jsr puts
	stz sdblk
	stz sdblk+2
	stz partoff
	stz partoff+2
	LDADDR BREC
	sta sdaddr
	jsr sdread
	bcc +
	jmp sdfatal
+	lda BREC+$1FE
	cmp #$AA55
	beq +
_out	jmp nope
+	sep #$20
	lda BREC+$1C2
	beq _out
	rep #$20
	lda BREC+$1C6
	sta partoff
	lda BREC+$1C8
	sta partoff+2
	rts
_mbrmsg: .ASC "MBR ", 0

initfat:
	rep #$30
	ldx #_fatmsg
	jsr puts
	jsr sdread
	bcc +
	jmp sdfatal
+	lda BREC+$00B
	cmp #512
	bne _out
	lda BREC+$011
	bne _out
	lda BREC+$02A
	bne _out

	sep #$30
	lda BREC+$00D
	beq _out
	sta clsiz
	ldx #$0
-	lsr
	beq +
	bcs _out
	inx
	bra -
+	stx clsh

	rep #$20
	stz fat
	stz fat+2
	lda BREC+$00E
	sta cloff
	stz cloff+2
	lda BREC+$010
	tax
	beq _out
-	clc
	lda cloff
	adc BREC+$024
	sta cloff
	lda cloff+2
	adc BREC+$026
	sta cloff+2
	dex
	bne -
	ldx clsiz
	txa
	asl
	bcs +
	sta tmp
	sec
	lda cloff
	sbc tmp
	sta cloff
	bcs ++
+	dec cloff+2
++	rep #$10
	ldx #_rootmsg
	jsr puts
	lda BREC+$02C
	sta dir
	lda BREC+$02E
	sta dir+2
	jsr readdir
	bcc +
	jmp sdfatal
+	rts
_fatmsg: .ASC "FAT ", 0
_rootmsg: .ASC "ROOT ", 0
	
readdir:
	php
	rep #$30
	lda dir
	sta clust
	lda dir+2
	sta clust+2
	LDADDR DIR
	sta sdaddr
-	jsr readclust
	bcs ++
	jsr nextclust
	bcc +
++	plp
	sec
	rts
+	bit eof-1
	bpl -
+	stz dirend
	lda sdaddr
	ora #ROMOFF>>8
	sta dirend+1
	jsr scandir
	jsr sort
	lda #$7F00
	sta scrtop+1
	lda #dirp&$FFFF
	sta scrtop
	ldy #$FFFD
	jsr nextshown
	tya
	bmi +
	clc
	adc scrtop
	sta scrtop
+	stz sel
	plp
	clc
	rts

clustsec:
	rep #$20
	sep #$10
	lda clust
	sta sdblk
	lda clust+2
	sta sdblk+2
	ldx clsh
-	asl sdblk
	rol sdblk+2
	dex
	bne -
	clc
	lda sdblk
	adc cloff
	sta sdblk
	lda sdblk+2
	adc cloff+2
	sta sdblk+2
	rts

readclust:
	php
	jsr clustsec
	ldx clsiz
-	beq ++
	jsr sdread
	bcs +++
	inc sdaddr
	inc sdaddr
	inc sdblk
	bne +
	inc sdblk+2
+	dex
	bra -
++	plp
	clc
	rts
+++	plp
	sec
	rts

nextclust:
	php
	sep #$30
	lda clust
	asl
	rep #$20
	lda clust+1
	rol
	sta sdblk
	ldx clust+3
	txa
	rol
	sta sdblk+2
	lda sdblk
	adc BREC+$00E
	sta sdblk
	bcc +
	inc sdblk+2	
+	cmp fat
	bne ++
	lda sdblk+2
	cmp fat+2
	beq +
++	lda sdblk
	sta fat
	lda sdblk+2
	sta fat+2
	lda sdaddr
	pha
	LDADDR FAT
	sta sdaddr
	jsr sdread
	pla
	sta sdaddr
	bcc +
	plp
	sec
	rts
+	rep #$10
	lda clust
	and #$7F
	asl
	asl
	tax
	lda FAT,x
	sta clust
	inx
	inx
	lda FAT,x
	and #$FFF
	sta clust+2
	
	sep #$10
	ldx #$0
	lda clust+2
	bne +
	lda clust
	cmp #$2
	bcs ++
-	dex
	bra ++
+	lda clust
	cmp #$FFF8
	bcs -
++	stx eof
	plp
	clc
	rts
	
scandir:
	php
	rep #$20
	lda #DIR>>8
	sta ptr+1
	lda #DIR & $FFFF
	sta ptr
	lda #$7F00
	sta dpend+1
	lda #dirp & $FFFF
	sta dpend
--	rep #$20
	lda #$01FF
	bit ptr
	bne +
	lda ptr+1
	cmp dirend+1
	bne +
---	rep #$30
	lda #$0
	sta [dpend]
	ldy #$1
	sta [dpend],y
	plp
	rts
+	sep #$30
	lda [ptr]
	beq +
	cmp #$E5
	beq +
	ldy #$B
	lda [ptr],y
	and #$C8
	bne +
	lda ptr+2
	ldy #$2
	sta [dpend],y
	rep #$20
	lda ptr
	sta [dpend]
	lda dpend
	cmp #DIRMAX*3
	beq ---
	clc
	lda dpend
	adc #$3
	sta dpend
+	rep #$20
	clc
	lda ptr
	adc #$20
	sta ptr
	bcc --
	sep #$20
	inc ptr+2
	bra --

getdent:
	php
	rep #$30
	tya
	bpl +
	dec scrtop+2
+	phy
	lda [scrtop],y
	sta dent
	iny
	iny
	sep #$20
	lda [scrtop],y
	sta dent+2
	ply
	bpl +
	inc scrtop+2
+	ora dent
	ora dent+1
	xba
	plp
	xba
	rts
	
isshown:
	php
	rep #$10
	sep #$20
	ldy #0
	lda [dent],y
	cmp #$2E
	beq +
	ldy #$B
	lda [dent],y
	bit #$02
	bne +
	bit #$10
	bne ++
	ldy #$8
	lda [dent],y
	cmp #'S'
	bne +
	ldy #$A
	lda [dent],y
	cmp #'C'
	bne +
	ldy #$9
	lda [dent],y
	cmp #'F'
	beq ++
	cmp #'M'
	bne +
++	plp
	sec
	rts
+	plp
	clc
	rts

nextshown:
	php
	rep #$30
	sty tmp
-	iny
	iny
	iny
	jsr getdent
	bne +
	ldy tmp
	bra ++
+	phy
	jsr isshown
	ply
	bcc -
++	plp
	rts
	
prevshown:
	php
	rep #$30
	sty tmp
-	dey
	dey
	dey
	tya
	clc
	adc scrtop
	cmp #dirp & $FFFF
	bcs +
	ldy tmp
	bra ++
+	jsr getdent
	bne +
+	phy
	jsr isshown
	ply
	bcc -
++	plp
	rts
	
putlfn:
	php
	rep #$30
	stz tmp
	ldy #$0
-	lda buf,y
	beq ++
	bit #$FF80
	beq +
	lda #'?'
+	jsr putc
	iny
	iny
	inc tmp
	lda tmp
	cmp #DISPLEN
	bne -
++	sep #$20
	ldy #$B
	lda [dent],y
	and #$10
	beq +
	lda #'/'
	jsr putc
+	rep #$20
-	lda tmp
	cmp #DISPLEN
	bcs +
	lda #' '
	jsr putc
	inc tmp
	bra -
+	plp
	rts

redraw:
	php
	sep #$20
	inc update
	rep #$30
	ldx #NAMES
	jsr move
	lda #DISPNUM
	sta tmp2
	ldy #$0
-	jsr getdent
	beq _f
	sty scrbot
	phy
	jsr isshown
	bcc +
	jsr filename
	jsr clrline
	ldx #NAMES-1
	jsr xmove
	ldx #' '
	lda 1,s
	cmp sel
	bne ++
	ldx #'>'
++	txa
	jsr putc
	jsr putlfn
	lda #$A
	jsr putc
	dec tmp2
	bne +
	ply
	bra ++
+	ply
	iny
	iny
	iny
	bra -

__	jsr clrline
	lda #$A
	jsr putc
	dec tmp2
	bne _b
++	sep #$20
	dec update
	plp
	rts

parent:
	rep #$30
	lda scrtop
	sta tmp2
	lda #dirp & $FFFF
	sta scrtop
	ldy #$0
-	jsr getdent
	bne +
	lda tmp2
	sta scrtop
	rts
+	lda [dent]
	cmp #$2E2E
	bne +
	ldy #$1A
	lda [dent],y
	sta dir
	ldy #$14
	lda [dent],y
	sta dir+2
	ora dir
	bne ++
	lda BREC+$02C
	sta dir
	lda BREC+$02E
	sta dir+2
++	jsr readdir
	jsr redraw
	rts
+	iny
	iny
	iny
	bra -

chdir:
	lda clust
	sta dir
	lda clust+2
	sta dir+2
	jsr readdir
	bcc +
	jmp _sde
+	jsr endbox
	jsr redraw
	sec
	rts
	
_fs	
	pea _fsmsg&$FFFF
_err	jsr box
	plx
	jsr puts
	jmp confirm
_size	pea _szmsg&$FFFF
	bra _err
readheader:
	sep #$20
	stz smch
	rep #$30
	ldy sel
	jsr getdent
	beq _fs
	
	ldy #$1A
	lda [dent],y
	sta clust
	ldy #$14
	lda [dent],y
	sta clust+2
	lda clust
	ora clust+2
	beq _fs
	ldy #$B
	lda [dent],y
	and #$10
	bne chdir
	
	ldy #$1C
	lda [dent],y
	sta size
	and #$3FF
	beq +
	cmp #$200
	bne _size
	sep #$20
	dec smch
	rep #$20
+	iny
	iny
	lda [dent],y
	sta size+2
	cmp #$61
	bcs _size

	lda #$3F
	sta tmp2
	lda #HIROM
	bit gamectl
	beq +
	lda #$7F
	sta tmp2
+	bit smch-1
	bpl +
	inc tmp2
+	lda tmp2
	sep #$10
	ldx clsh
-	lsr
	dex
	bne -
	sta tmp2
	pha
	rep #$10

-	dec tmp2
	bmi +
	jsr nextclust
	bcs _sde
	bit eof-1
	bmi ++
	bra -
++	jmp _fs

+	jsr clustsec
	sep #$10
	ldx clsiz
	rep #$30
	dex
	stx tmp2
	pla
	and tmp2
	clc
	adc sdblk
	sta sdblk
	bcc +
	inc sdblk+2
+	LDADDR HEAD
	sta sdaddr
	jsr sdread
	bcs _sde
	clc
	rts
_sde	
	jsr box
	jsr sderror
	jmp confirm
	
readrom:
	rep #$30
	ldy sel
	jsr getdent
	bne +
	jmp _fs
+	sep #$10
	lda #$0
	ldx smch
	bpl +
	lda #-2
+	sta sdaddr
	ldy #$1A
	lda [dent],y
	sta clust
	ldy #$14
	lda [dent],y
	sta clust+2
	jsr endbox
	jsr bar
-	jsr readclust
	bcs +
	jsr nextclust
	bcs +
	jsr showprog
	bit eof-1
	bpl -
	jsr endbar
	clc	
	rts
+	rep #$30
	jsr endbar
	bit cardsw-1
	bpl +
	jsr box
	jsr sderror
	jsr waitkey
	jsr readdir
	jsr redraw
+	sec
	rts

	
_fsmsg: .ASC "FS ERROR", 0
_szmsg: .ASC "INVALID SIZE", 0
.ENDS
