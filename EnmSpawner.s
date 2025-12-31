.namespace Enemy
{

.var SPSpawnType = EData0
.var SPSpawnCount = EData1
.var SPSpawnTimer = EData2
.var SPSpawnData = EData3

// ------------------------------------------------------------
// Update functions
//
// Spawn state - showing up
//
// params:		Y = object ID
//				Z = parent ID
// registers:	A,X,Z free to use
// preserve: 	Y
//
SpawnPatternXVL:	.byte $00, <FP(24), <FP(-24)
SpawnPatternXVH:	.byte $00, >FP(24), >FP(-24)

iniSpawnSpawner: 
{
	jsr GetRandom
	cmp #$80
	bcs _left

	bra _doneX

_left:

_doneX:

	jsr InitSpawnedPosData

	lda SpawnPattern
	and #ENSP_PLAYER_REL
	beq not_rel
	
	clc
	lda XPosLo,y
	adc Player.XPos+0
	sta XPosLo,y
	lda XPosHi,y
	adc Player.XPos+1
	sta XPosHi,y

not_rel:
	lda SpawnPattern
	and #$3f
	tax
	
	lda SpawnPatternXVL,x
	sta XVelLo,y
	lda SpawnPatternXVH,x
	sta XVelHi,y
	
	lda #$00
	sta AnimFrame,y

	jsr GetRandom
	sta Timer,y

	lda SPSpawnCount,y
	dec
	sta Life,y

	rts
}

// ------------------------------------------------------------
// params:		Y = object ID
// registers:	A,X,Z free to use
// preserve: 	Y
//
updSpawnSpawner: 
{
	lda #StatePlaySpawner
	jsr SwitchToState

	rts
}

// ------------------------------------------------------------
// Play state - just moving around
//
// params:		Y = object ID
// registers:	A,X,Z free to use
// preserve: 	Y
//
iniPlaySpawner: 
{
	lda SPSpawnTimer,y
	sta Timer,y

	rts
}

// ------------------------------------------------------------
// params:		Y = object ID
// registers:	A,X,Z free to use
// preserve: 	Y
//
updPlaySpawner: 
{
	jsr ApplyVelocityX
	
	sec
	lda Timer,y
	sbc #$01
	sta Timer,y
	bne _dont_spawn

	lda SPSpawnTimer,y
	sta Timer,y

	lda XPosLo,y
	sta SpawnPosX+0
	lda XPosHi,y
	sta SpawnPosX+1

	lda YPosLo,y
	sta SpawnPosY+0
	lda YPosHi,y
	sta SpawnPosY+1

	lda EData3,y
	sta SpawnData+3
	
	phy
	tya
	taz						// Z = parent ID (this)
	lda SPSpawnType,y
	jsr Enemy.Create
	ply

	sec
	lda Life,y
	sbc #$01
	sta Life,y

_dont_spawn:

	rts
}

// ------------------------------------------------------------
// Draw functions - the number of draw states are generally less
// that update states because you can often share drawing logic
// across the update logic
// 
// Draw Spawn - showing up
//
// params:		Y = object ID
// registers:	A,X,Z free to use
// preserve: 	Y
//
drwSpawnSpawner: 
{
	rts
}

// ------------------------------------------------------------
// Draw Play - flying around
//
// params:		Y = object ID
// registers:	A,X,Z free to use
// preserve: 	Y
//
drwPlaySpawner: 
{
	rts
}

}