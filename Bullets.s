.namespace Bullets
{

.const NUM_BULLETS = 32

.const INI_BULL_LIFE = 36

.const INI_BULL_VELX = FP(0)
.const INI_BULL_VELY = FP(-6)

.const INI_BULL1_OFFX = FP(-7)
.const INI_BULL2_OFFX = FP(7)

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
ObjT:
	.fill NUM_BULLETS, 0
ObjL:
	.fill NUM_BULLETS, 1

.segment Data "Bullets"
IniVelXLo:
	.byte <INI_BULL_VELX, <INI_BULL_VELX
IniVelXHi:
	.byte >INI_BULL_VELX, >INI_BULL_VELX

IniOffXLo:
    .byte <INI_BULL1_OFFX, <INI_BULL2_OFFX
IniOffXHi:
    .byte >INI_BULL1_OFFX, >INI_BULL2_OFFX

IniVelYLo:
	.byte <INI_BULL_VELY, <INI_BULL_VELY
IniVelYHi:
	.byte >INI_BULL_VELY, >INI_BULL_VELY

IniOffYLo:
    .byte 0,0
IniOffYHi:
    .byte 0,0

IniA:
	.byte $00, $00

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

    clc
	lda Player.XPos+0
    adc IniOffXLo,x
	sta ObjXLo,y
	lda Player.XPos+1
    adc IniOffXHi,x
	sta ObjXHi,y

    clc
	lda Player.YPos+0
    adc IniOffYLo,x
	sta ObjYLo,y
	lda Player.YPos+1
    adc IniOffYHi,x
	sta ObjYHi,y

	lda IniVelXLo,x
	sta ObjVXLo,y
	lda IniVelXHi,x
	sta ObjVXHi,y

	lda IniVelYLo,x
	sta ObjVYLo,y
	lda IniVelYHi,x
	sta ObjVYHi,y

	lda IniA,x
	sta ObjA,y

	lda #$00
	sta ObjT,y

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
	lda ObjT,y
	adc #$01
	sta ObjT,y

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

	lda ObjT,y
	and #$03
	bne no_anim
	
	clc
	lda ObjA,y
	cmp #6
	bcs no_anim

	adc #3
	sta ObjA,y

no_anim:

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

    // Prime the multiply unit for FP to Screen conversions
    //
	lda #$08
	sta $d770
	lda #$00
	sta $d771
	sta $d772
	sta $d776

	//
	ldz SplitPos
	bra checkdone

drawloop:
	lda (IndexPtr),z
	tay

	jsr setScreenPos

	_sub16im(DrawPosX, 8, DrawPosX)
	_sub16im(DrawPosY, 12, DrawPosY)

	lda ObjA,y
	sta DrawSChr

	ldx #PIXIE_16x24
	jsr DrawPixie

	inz

checkdone:
	cpz Size
	bne drawloop

	rts
}

// ------------------------------------------------------------
//
setScreenPos: 
{
	lda ObjXLo,y
	sta $d774
	lda ObjXHi,y
	sta $d775

	_set16($d779, DrawPosX)

	lda ObjYLo,y
	sta $d774
	lda ObjYHi,y
	sta $d775

	_set16($d779, DrawPosY)

	rts
}

// ------------------------------------------------------------

}