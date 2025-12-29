.namespace Bullets
{

.const NUM_BULLETS = 16

.const INI_BULL_LIFE = 36
.const INI_BULL_VELX = 0
.const INI_BULL_VELY = -6

// ------------------------------------------------------------
//
.segment Zeropage "Bullets"
IndexPtr:		.word $0000
SplitPos:		.byte $00
Size:			.byte $00

// ------------------------------------------------------------
//
.segment BSS "Bullets"
ObjIndxList:
	.fill NUM_BULLETS, 0

ObjXLo:
	.fill NUM_BULLETS, 0
ObjXHi:
	.fill NUM_BULLETS, 0

ObjVXLo:
	.fill NUM_BULLETS, 0
ObjVXHi:
	.fill NUM_BULLETS, 0

ObjYLo:
	.fill NUM_BULLETS, 0
ObjYHi:
	.fill NUM_BULLETS, 0

ObjVYLo:
	.fill NUM_BULLETS, 0
ObjVYHi:
	.fill NUM_BULLETS, 0

ObjA:
	.fill NUM_BULLETS, 0
ObjL:
	.fill NUM_BULLETS, 1

.segment Data "Bullets"
IniVelXLo:
	.byte <INI_BULL_VELX, <INI_BULL_VELX
IniVelXHi:
	.byte >INI_BULL_VELX, >INI_BULL_VELX
IniOffX:
    .byte 0,0
IniVelYLo:
	.byte <INI_BULL_VELY, <INI_BULL_VELY
IniVelYHi:
	.byte >INI_BULL_VELY, >INI_BULL_VELY
IniOffY:
    .byte 0,0

IniA:
	.byte $02, $00

// ------------------------------------------------------------
//
.segment Code "Bullets"
// Initialize the object list
//
InitList: 
{
	_initlist(ObjIndxList, SplitPos, IndexPtr, NUM_BULLETS, Size)
	rts
}

Alloc: 
{
	_alloc(SplitPos, IndexPtr)
	rts
}

Free: 
{
	_free(SplitPos, IndexPtr)
	rts
}

// ------------------------------------------------------------
//
CreateBullet: 
{
	jsr Alloc
	beq !+				// Couldn't allocate

	jsr InitObj

!:
	rts
}

// ------------------------------------------------------------
// Initialize a single object
// params:	X = object ID
//
InitObj: 
{
	phx

	lda #INI_BULL_LIFE
	sta ObjL,y

	lda Player.XPos+0
	sta ObjXLo,y
	lda Player.XPos+1
	sta ObjXHi,y

	clc
	lda Player.YPos+0
	sta ObjYLo,y
	lda Player.YPos+1
	sta ObjYHi,y

    ldx #0

	clc
	lda IniVelXLo,x
	sta ObjVXLo,y
	lda IniVelXHi,x
	sta ObjVXHi,y

	clc
	lda IniVelYLo,x
	sta ObjVYLo,y
	lda IniVelYHi,x
	sta ObjVYHi,y

	lda IniA,x
	sta ObjA,y

	plx
	rts
}

// ------------------------------------------------------------
// Move a single object
// params:	Y = object ID
//
MoveObj: 
{
	clc
	lda ObjXLo,y
	adc ObjVXLo,y
	sta ObjXLo,y
	lda ObjXHi,y
	adc ObjVXHi,y
	sta ObjXHi,y

	clc
	lda ObjYLo,y
	adc ObjVYLo,y
	sta ObjYLo,y
	lda ObjYHi,y
	adc ObjVYHi,y
	sta ObjYHi,y

	// decrease life
	sec
	lda ObjL,y
	sbc #$01
	sta ObjL,y

	rts
}

// ------------------------------------------------------------
//
Update: 
{
	// 
	ldz SplitPos
	bra checkdone

moveloop:
	// X = index of current object
	lda (IndexPtr),z
	tay

	jsr MoveObj

	lda ObjL,y
	bpl stillalive

	// handle the dead case, free the object at slot Y
	tza
	tay
	jsr Free

stillalive:
	inz

checkdone:
	cpz Size
	bne moveloop

	rts
}

Draw: 
{
	_set16im(bulletsChars.baseChar, DrawBaseChr)			// Start charIndx with first pixie char
	_set8im((PAL_BULLETS << 4) | $0f, DrawPal)

	//
	ldz SplitPos
	bra checkdone

drawloop:
	lda (IndexPtr),z
	tay

    sec
    lda ObjXLo,y
    sbc #8
    sta DrawPosX+0
    lda ObjXHi,y
    sbc #0
    sta DrawPosX+1

    sec
    lda ObjYLo,y
    sbc #8
    sta DrawPosY+0
    lda ObjYHi,y
    sbc #0
    sta DrawPosY+1

	lda #$00
	sta DrawSChr

	ldx #PIXIE_16x16
	jsr DrawPixie

	inz

checkdone:
	cpz Size
	bne drawloop

	rts
}

// ------------------------------------------------------------

}