.INCLUDE "dat.inc"

.SECTION "CODE"
busy:
	php
	rep #$10
	sep #$20
-	bit SDSTAT
	bmi -
	bvs +
	plp
	clc
	rts
+	plp
	sec
	rts

sderror:
	lda SDSTAT
	cmp #$40
	bne +
	ldx #nocard
	jsr puts
	plp
	rts

+	rep #$10
	sep #$20
	ldx #error
	jsr puts
;	lda SDSTAT
	and #$3F
	jsr putbyte
	ldx #response
	jsr puts
	lda SDRESP+3
	jsr putbyte
	lda SDRESP+2
	jsr putbyte
	lda SDRESP+1
	jsr putbyte
	lda SDRESP
	jsr putbyte
	rts

sdfatal:
	jsr box
	jsr sderror
-	bra -

sdread:
	php
	rep #$20
	lda sdaddr
	sta DMAADDR
	lda sdblk
	sta SDBLK
	lda sdblk+2
	sta SDBLK+2
	lda #MEMMODE
	sta DMACTRL
	lda #READ
	sta SDCMD
	jsr busy
	lda #0
	sta DMACTRL
	rol tmp
	plp
	ror tmp
	rts

.ENDS
