.INCLUDE "dat.inc"

.SECTION "CODE"
busy:
	php
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
	php
	rep #$10
	sep #$20
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
	lda SDSTAT
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
	plp
	rts

sdfatal:
	jsr box
	jsr sderror
	jmp loop

sdread:
	php
	rep #$20
	lda sdaddr
	sta DMAADDR
	clc
	lda sdblk
	adc partoff
	sta SDBLK
	lda sdblk+2
	adc partoff+2
	sta SDBLK+2
	sep #$20
	lda dmactrl
	ora #MEMMODE
	sta DMACTRL
	lda #READCMD
	sta SDCMD
	jsr busy
	lda dmactrl
	sta DMACTRL
	rol tmp
	plp
	ror tmp
	rts

.ENDS
