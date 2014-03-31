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
	bit #$20
	beq +
	ldx #_nocard
	jsr puts
	plp
	rts
+	bit #$10
	beq +
	ldx #_crcerr
	jsr puts
	bra _pblk
+	rep #$10
	sep #$20
	ldx #_error
	jsr puts
	lda SDFAILED
	and #$3F
	jsr putbyte
	ldx #_response
	jsr puts
	lda SDRESP+3
	jsr putbyte
	lda SDRESP+2
	jsr putbyte
	lda SDRESP+1
	jsr putbyte
	lda SDRESP
	jsr putbyte
_pblk:	ldx #_blk
	jsr puts
	rep #$20
	clc
	lda sdblk
	adc partoff
	pha
	lda sdblk+2
	adc partoff+2
	jsr putword
	pla
	jsr putword
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

_nocard: .ASC "NO CARD", 0
_error: .ASC "CARD ERROR", 10, "CMD $", 0
_response: .ASC 10, "RESPONSE ", 0
_blk: .ASC 10, "BLOCK ", 0
_crcerr: .ASC "CRC ERROR", 0

.ENDS
