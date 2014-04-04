.INCLUDE "dat.inc"

.SECTION "CODE"
modname:
	php
	rep #$30
	ldx #buf
	ldy #buf2
	lda #512
	mvn 0, 0
	
	ldx #-2
	ldy #-1
-	inx
	inx
	lda buf2,x
	cmp #'.'
	bne +
	txy
+	cmp #0
	bne -

	cpy #-1
	bne +
	txy
+	cpy #502
	bcc +
	ldy #502
+	ldx #0
-	lda _end.w,x
	sta buf2,y
	iny
	inx
	cpx #10
	bne -
	plp
	rts
_end:	.DB '.', 0, 's', 0, 'a', 0, 'v', 0, 0, 0

namecmp:
	rep #$30
	ldx #0
-	lda buf,x
	bne +
	lda buf2,x
	rts
+	eor buf2,x
	beq +
	and #$FFDF
	bne ++
	lda buf,x
	and #$FFDF
	cmp #$41
	bcc ++
	cmp #$5B
	bcc +
	ina
++	rts
+	inx
	inx
	bra -

openfile:
	php
	rep #$30
	lda #DIR >> 8
	sta dent+1
	lda #DIR & $FFFF
	sta dent
-	rep #$20
	lda dent+1
	cmp dirend+1
	beq createfile
	sep #$30
	lda [dent]
	beq +
	cmp #$E5
	beq +
	ldy #$B
	lda [dent],y
	and #$D8
	bne +
	jsr filename
	jsr namecmp
	rep #$30
	beq checkclust
+	rep #$20
	lda dent
	clc
	adc #$20
	sta dent
	bcc -
	inc dent+2
	bra -

createfile:
	rep #$10
	ldx #_nofile
	jsr puts
	jsr waitkey
	plp
	sec
	rts
_nofile: .ASC "NO SAVE", 0

_sde:
	sep #$20
	bit cardsw
	bra +
	jsr box
	jsr sderror
	jsr waitkey
+	plp
	sec
	rts

checkclust:
	rep #$20
	
	lda clsiz
	and #$FF
	sta tmp
	lda rammask
	lsr
	clc
	adc tmp
	
	sep #$10
	ldx clsh
-	lsr
	dex
	bne -
	sta tmp2
	
	ldy #$1A
	lda [dent],y
	sta clust
	ldy #$14
	lda [dent],y
	sta clust+2
	ora clust
	beq +
-	jsr nextclust
	bcs _sde
	dec tmp2
	beq ++
	bit eof-1
	bpl -
+	rep #$10
	ldx #_nofile
	jsr puts
	plp
	sec
	rts
++	plp
	clc
	rts
	
	
readin:
	php
	rep #$20
	lda rammask
	ina
	lsr
	sta tmp2
	sep #$30
	stz BLKADDR
	rep #$20
	lda #MAGIC
	sta LOCK
	stz sdaddr
	ldy #$1A
	lda [dent],y
	sta clust
	ldy #$14
	lda [dent],y
	sta clust+2
	
--	jsr clustsec
	ldx clsiz
-	lda #MEMMODE
	trb sdmode
	jsr sdread
	lda #MEMMODE
	tsb sdmode
	bcs +++
	clc
	lda sdblk
	adc partoff
	sta RAMBLK
	lda sdblk+2
	adc partoff+2
	sta RAMBLK+2	
	
	sep #$20
	inc BLKADDR
	rep #$20
	inc sdaddr
	inc sdaddr
	inc sdblk
	bne +
	inc sdblk+2
+	dec tmp2
	beq ++
	dex
	bne -
	jsr nextclust
	bra --
++	stz LOCK
	plp
	clc
	rts

+++	stz LOCK
	jmp _sde

findslot:
	php
	rep #$30
	stz tmp
	lda #DIR >> 8
	sta ptr+1
	lda #DIR & $FFFF
	sta ptr

-	rep #$20
	lda ptr+1
	cmp dirend+1
	beq ++
	sep #$20
	lda [ptr]
	beq +
	cmp #$E5
	beq +
	rep #$20
	stz tmp

--	lda ptr
	clc
	adc #$20
	sta ptr
	bcc -
	inc ptr+2
	bra -

+	rep #$20
	lda ptr+1
	sta dent+1
	lda ptr
	sta dent
	sep #$20
	lda tmp
	cmp lfn
	beq +
	inc tmp
	bra --
+	
++


	plp
	rts
.ENDS
