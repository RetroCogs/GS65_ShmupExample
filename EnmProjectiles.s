.namespace EnmProjectiles
{

.const NUM_PROJECTILES = 64
.const INI_BULL_VEL = FP($70)

.const MIN_YPOS = $08
.const MAX_YPOS = $c0

// ------------------------------------------------------------
//
.segment Zeropage "EnmProjectiles"
IndexPtr:		.word $0000
SplitPos:		.byte $00
Size:			.byte $00

// ------------------------------------------------------------
//
.segment BSS "EnmProjectiles"
ObjIndxList:		.fill NUM_PROJECTILES, 0

ObjXLo:				.fill NUM_PROJECTILES, 0
ObjXHi:				.fill NUM_PROJECTILES, 0

ObjVXLo:			.fill NUM_PROJECTILES, 0
ObjVXHi:			.fill NUM_PROJECTILES, 0

ObjYFr:				.fill NUM_PROJECTILES, 0
ObjYLo:				.fill NUM_PROJECTILES, 0
ObjYHi:				.fill NUM_PROJECTILES, 0

ObjVYFr:			.fill NUM_PROJECTILES, 0
ObjVYLo:			.fill NUM_PROJECTILES, 0
ObjVYHi:			.fill NUM_PROJECTILES, 0

ObjSprBase:			.fill NUM_PROJECTILES, 0

ObjA:				.fill NUM_PROJECTILES, 0
ObjL:				.fill NUM_PROJECTILES, 1

Timer:				.fill NUM_PROJECTILES, 0

SpawnVelX:
	.byte $00,$00
SpawnVelY:
	.byte $00,$00,$00

// ------------------------------------------------------------
//
.segment Code "EnmProjectiles"
// Initialize the object list
//
InitList: {
	_initlist(ObjIndxList, SplitPos, IndexPtr, NUM_PROJECTILES, Size)
	rts
}

Alloc: {
	_alloc(SplitPos, IndexPtr)
	rts
}

Free: {
	_free(SplitPos, IndexPtr)
	rts
}

// ------------------------------------------------------------
//
CreateEnmProjectile: {
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
InitObj: {
	phx

	lda #$7f
	sta ObjL,y

	lda SpawnPosX+0
	sta ObjXLo,y
	lda SpawnPosX+1
	sta ObjXHi,y

	lda SpawnVelX+0
	sta ObjVXLo,y
	lda SpawnVelX+1
	sta ObjVXHi,y

	lda #$00
	sta ObjA,y

	lda SpawnData+0
	sta ObjSprBase,y

	lda #$00
	sta ObjYFr,y
	lda SpawnPosY+0
	sta ObjYLo,y
	lda SpawnPosY+1
	sta ObjYHi,y

	lda SpawnVelY+0
	sta ObjVYFr,y
	lda SpawnVelY+1
	sta ObjVYLo,y
	lda SpawnVelY+2
	sta ObjVYHi,y

	lda #$00
	sta Timer,y

	plx
	rts
}

// ------------------------------------------------------------
// Move a single object
// params:	Y = object ID
//
MoveObj: {
	clc
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

	sec
	lda ObjYLo,y
	sbc #<MIN_YPOS
	lda ObjYHi,y
	sbc #>MIN_YPOS
	lbmi _kill_off

	sec
	lda ObjYLo,y
	sbc #<MAX_YPOS
	lda ObjYHi,y
	sbc #>MAX_YPOS
	lbpl _kill_off

	// decrease life
	sec
	lda ObjL,y
	sbc #$01
	sta ObjL,y

	clc
	lda Timer,y
	adc #$01
	sta Timer,y

	lda #$00
	sta ObjA,y

	lda Timer,y
	and #$04
	bne !+

	lda #$02
	sta ObjA,y

!:

	rts

_kill_off:
	lda #$ff
	sta ObjL,y

	rts
}

// ------------------------------------------------------------
//
Update: {
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

Draw: {
	//
	ldz SplitPos
	bra checkdone

drawloop:
	lda (IndexPtr),z
	tay

	jsr setScreenPos

	// _sub16im(RRBSpr.XPos, 8, RRBSpr.XPos)
	// _sub8im(RRBSpr.YPos, 4, RRBSpr.YPos)

	// lda #(PAL_BULLETS << 4) | $0f
	// sta RRBSpr.Pal

	// clc
	// lda ObjA,y
	// adc ObjSprBase,y
	// sta RRBSpr.SChr

	// lda #<sprBull.baseChar
	// sta RRBSpr.BaseChr+0
	// lda #>sprBull.baseChar
	// sta RRBSpr.BaseChr+1

	// lda #RRBSpr16x8
	// jsr RRBSpr.Draw

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
	// sec
	// lda ObjXLo,y
	// sbc Camera.XPos+0
	// sta RRBSpr.XPos+0
	// lda ObjXHi,y
	// sbc Camera.XPos+1
	// sta RRBSpr.XPos+1

	// lda #$08
	// sta $d770
	// lda #$00
	// sta $d771
	// sta $d772
	// sta $d776
	// _set16(RRBSpr.XPos, $d774)
	// _set16($d779,RRBSpr.XPos)

	// lda ObjYLo,y
	// sta RRBSpr.YPos+0
	// lda ObjYHi,y
	// sta RRBSpr.YPos+1

	rts
}

// ------------------------------------------------------------

}