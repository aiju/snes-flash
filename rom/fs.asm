.INCLUDE "dat.inc"

.SECTION "CODE"
mbr:
	pea _mbrmsg
	jsr putst
	rep #$20
	stz sdblk
	stz sdblk+2
	stz partoff
	stz partoff+2
	lda #(BREC>>9)&$FF80
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
	pea _fatmsg
	jsr putst
	rep #$20
	jsr sdread
	bcc +
	jmp sdfatal
+	
	lda BREC+$00B
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
	rep #$30
	lda BREC+$02C
	sta clust
	lda BREC+$02E
	sta clust+2
	lda #$0100
	sta sdaddr
	lda #$0003
	sta sdblk
	stz sdblk+2
	jsr sdread
	bcc +
	jmp sdfatal
+	lda $28000
	jsr putword
	jmp loop
	rts
_fatmsg: .ASC "FAT ", 0

readclust:
	php
	rep #$20
	sep #$10
	lda clust
	sta sdblk
	lda clust+2
	sta sdblk+2
	ldx clsh
-	beq +
	asl sdblk
	rol sdblk+2
	dex
	bra -
+	

	lda #$A
	jsr putc
	lda sdblk+2
	jsr putword
	lda sdblk
	jsr putword
	lda #$A
	jsr putc
	lda sdaddr
	jsr putword
	lda #$A
	jsr putc
	jsr sdread
	plp
	clc
	rts

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

.ENDS
