.INCLUDE "dat.inc"

.SECTION "CODE"
filename:
	php
	sep #$20
	stz lfn
	jsr _sfnsum
	sta tmp
	stz tmp+1

	lda dent+2
	sta ptr+2
	rep #$20
	lda dent
	sta ptr
	
	lda #buf
	sta tmp3

-	rep #$20
	lda ptr
	sec
	sbc #$20
	sta ptr
	bcs +
	sep #$20
	dec ptr+2
	lda ptr+2
	cmp #DIR>>16
	rep #$20
	bcc sfn

+	ldy #$B
	lda [ptr],y
	cmp #$F
	bne sfn
	ldy #$1A
	lda [ptr],y
	bne sfn
	sep #$20
	ldy #$D
	lda [ptr],y
	cmp tmp
	bne sfn
	lda [ptr]
	beq sfn
	cmp #$E5
	beq sfn
	and #$1F
	inc tmp+1
	cmp tmp+1
	bne sfn
	
	rep #$20
	ldy #$01
	ldx #5
	jsr _copy
	ldy #$0E
	ldx #6
	jsr _copy
	ldy #$1C
	ldx #2
	jsr _copy
	
	sep #$20
	inc lfn
	lda [ptr]
	asl
	bpl -
	rep #$20
	lda #0
	sta (tmp3)
	stz buf+510
	plp
	rts
_copy:
	lda [ptr],y
	iny
	iny
	sta (tmp3)
	lda tmp3
	cmp #buf+510
	bcs +
	adc #2
	sta tmp3
+	dex
	bne _copy
	rts

sfn:
	sep #$30
	stz lfn
	ldx #0
	ldy #0
	sty tmp
-	lda [dent],y
	sta buf,x
	and #$DF
	beq +
	stx tmp
+	inx
	stz buf,x
	inx
	iny
	cpy #8
	bne -
	
	lda #'.'
	sta buf,x
	inx
	stz buf,x
	inx

-	lda [dent],y
	iny
	sta buf,x
	and #$DF
	beq +
	stx tmp
+	inx
	stz buf,x
	inx
	cpy #11
	bne -

	ldx tmp
	inx
	inx
	rep #$20
	stz buf,x
	plp
	rts

_sfnsum:
	sep #$30
	ldy #0
	lda #0
-	pha
	lsr
	pla
	ror
	clc
	adc [dent],y
	iny
	cpy #11
	bne -
	rts

sort:
	php
	rep #$30
	lda #dirp >> 8
	sta dirptr+1
	sta ptr2+1
	stz dirptr
	lda dpend
	sec
	sbc #3
	pha
	pea dirp & $FFFF
	jsr quicksort
	pla
	pla
	plp
	rts

strcpy:
	ldx #-2
-	inx
	inx
	lda buf,x
	jsr _upper
	sta buf2,x
	tay
	bne -
	lda buf+512
	sta buf2+512
	rts

quicksort:
	lda 3,s
	cmp 5,s
	bcc +
	rts
+	lda 5,s
	pha
	tay
	jsr _name
	jsr strcpy
	ply
	lda 5,s
	sta ptr2
	jsr swap

	lda 3,s
	tay
	sta ptr2
-	phy
	jsr _name
	jsr _cmp
	ply
	bcc +
	jsr swap
	lda ptr2
	clc
	adc #3
	sta ptr2
+	iny
	iny
	iny
	tya
	cmp 5,s
	bcc -
++	jsr swap
	
	lda ptr2
	sec
	sbc #3
	pha
	lda 5,s
	pha
	jsr quicksort
	ply
	pla
	clc
	adc #6
	sta 3,s
	bra quicksort

_name:
	lda [dirptr],y
	sta dent
	phy
	iny
	lda [dirptr],y
	sta dent+1
	ldy #$B
	lda [dent],y
	sta buf+512
	jsr filename
	ply
	rts

swap:
	lda [dirptr],y
	pha
	lda [ptr2]
	sta [dirptr],y
	pla
	sta [ptr2]
	sep #$20
	tyx
	ldy #2
	lda $7F0002,x
	pha
	lda [ptr2],y
	sta $7F0002,x
	pla
	sta [ptr2],y
	txy
	rep #$20
	rts

_cmp:
	lda buf+512
	eor buf2+512
	and #$10
	beq ++
	clc
	lda buf+512
	and #$10
	beq +
	sec
	rts
++	ldx #-2
-	inx
	inx
	lda buf,x
	jsr _upper
	eor #$FFFF
	sec
	adc buf2,x
	bne +
	lda buf,x
	bne -
+	rts

_upper:
	cmp #'z'+1
	bcs +
	cmp #'a'
	bcc +
	sec
	sbc #'a'-'A'
+	rts

.ENDS
