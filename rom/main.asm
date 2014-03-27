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
	jsr mbr
	jsr initfat
	jsr endbox
	rts

fatal:	jmp sdfatal

title: .ASC 10, " SNES FLASH CART", 0
busystr: .ASC "BUSY", 10, 0
nocard: .ASC "NO CARD", 0
error: .ASC "CARD ERROR", 10, "CMD ", 0
response: .ASC 10, "RESPONSE ", 0
.ENDS
