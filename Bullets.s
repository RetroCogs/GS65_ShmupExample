.namespace Bullets
{

.const NUM_BULLETS = 32

.const INI_BULL_LIFE = 36

.const INI_BULL_VELX = FP(0)
.const INI_BULL_VELY = FP(-6)

.const INI_BULL1_OFFX = -7
.const INI_BULL2_OFFX = 7

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

ObjXFr:
	.fill NUM_BULLETS, 0
ObjXLo:
	.fill NUM_BULLETS, 0
ObjXHi:
	.fill NUM_BULLETS, 0

ObjVXFr:
	.fill NUM_BULLETS, 0
ObjVXLo:
	.fill NUM_BULLETS, 0
ObjVXHi:
	.fill NUM_BULLETS, 0

ObjYFr:
	.fill NUM_BULLETS, 0
ObjYLo:
	.fill NUM_BULLETS, 0
ObjYHi:
	.fill NUM_BULLETS, 0

ObjVYFr:
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
IniVelXFr:
	.byte <INI_BULL_VELX, <INI_BULL_VELX
IniVelXLo:
	.byte >INI_BULL_VELX, >INI_BULL_VELX
IniVelXHi:
	.byte [INI_BULL_VELX>>16], [INI_BULL_VELX>>16]

IniOffXLo:
    .byte <INI_BULL1_OFFX, <INI_BULL2_OFFX
IniOffXHi:
    .byte >INI_BULL1_OFFX, >INI_BULL2_OFFX

IniVelYFr:
	.byte <INI_BULL_VELY, <INI_BULL_VELY
IniVelYLo:
	.byte >INI_BULL_VELY, >INI_BULL_VELY
IniVelYHi:
	.byte [INI_BULL_VELY>>16], [INI_BULL_VELY>>16]

IniOffYLo:
    .byte 0,0
IniOffYHi:
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

	lda Player.XPosFr
	sta ObjXFr,y
    clc
	lda Player.XPos+0
    adc IniOffXLo,x
	sta ObjXLo,y
	lda Player.XPos+1
    adc IniOffXHi,x
	sta ObjXHi,y

	lda Player.YPosFr
	sta ObjYFr,y
    clc
	lda Player.YPos+0
    adc IniOffYLo,x
	sta ObjYLo,y
	lda Player.YPos+1
    adc IniOffYHi,x
	sta ObjYHi,y

	lda IniVelXFr,x
	sta ObjVXFr,y
	lda IniVelXLo,x
	sta ObjVXLo,y
	lda IniVelXHi,x
	sta ObjVXHi,y

	lda IniVelYFr,x
	sta ObjVYFr,y
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
	lda ObjXFr,y
	adc ObjVXFr,y
	sta ObjXFr,y
	lda ObjXLo,y
	adc ObjVXLo,y
	sta ObjXLo,y
	lda ObjXHi,y
	adc ObjVXHi,y
	sta ObjXHi,y

	clc
	lda ObjYFr,y
	adc ObjVYFr,y
	sta ObjYFr,y
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