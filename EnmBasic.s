.namespace Enemy
{

.var BSD0Timer = EData0
.var BSD1Type = EData1
.var BSD2Parent = EData2
.var BSD3Flags = EData3

.const BS_INI_VEL_RIGHT = PX(2)
.const BS_INI_VEL_LEFT = PX(-2)

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
iniSpawnBasic: {
	lda #$03
	sta Life,y

	jsr InitSpawnedPosData

	// By default red type
	lda #$00
	sta BSD1Type,y

	// Check blue type selector flag
	lda BSD3Flags,Y
	and #ENBAS_SPAWNBLUE
	beq doneTypeSelection

	// this enemy is blue
	lda #$01
	sta BSD1Type,y

doneTypeSelection:
	lda BSD3Flags,y
	and #ENBAS_HDIR_LEFT
	bne _left

	// start moving right
	lda #<BS_INI_VEL_RIGHT
	sta XVelLo,y
	lda #>BS_INI_VEL_RIGHT
	sta XVelHi,y

	bra _doneX

_left:
	// start moving left
	lda #<BS_INI_VEL_LEFT
	sta XVelLo,y
	lda #>BS_INI_VEL_LEFT
	sta XVelHi,y

_doneX:

	lda #$00
	sta AnimFrame,y

	jsr GetRandom
	sta Timer,y

	jsr GetRandom
	sta BSD0Timer,y

	ldx BSD0Timer,y
	jsr SetCosYPos
	ldx Timer,y
	jsr AddCos2YPos

	rts
}

// ------------------------------------------------------------
// params:		Y = object ID
// registers:	A,X,Z free to use
// preserve: 	Y
//
updSpawnBasic: {
	lda #StatePlayBasic
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
iniPlayBasic: {
	// Now activate
	_setEnmFlag(ENMST_ACTIVE)
	rts
}

// Bullet types for basic enemy
//
BasicBulletType:
	.byte $04, $0c					// type 0 = red (hurt player), type 1 = blue (disrupt radar)
BasicFireMask:
	.byte %00000001, %00000011		// type 0 = single bullet per cycle, type 2 = double buller per cycle

// ------------------------------------------------------------
// params:		Y = object ID
// registers:	A,X,Z free to use
// preserve: 	Y
//
updPlayBasic: {
	phx

	jsr CalcRelativeDistanceToPlayer

	lda Timer,y
	inc
	sta Timer,y

	lda BSD3Flags,y
	and #ENBAS_BIGCOS
	beq !+
	lda BSD0Timer,y
	inc
	sta BSD0Timer,y
!:

	// Set Ypos based on BSD0Timer
	ldx BSD0Timer,y
	jsr SetCosYPos

	lda BSD3Flags,y
	and #ENBAS_SMLCOS
	beq !+
	ldx Timer,y
	jsr AddCos2YPos
!:

	jsr ApplyVelocityX

	ldx BSD1Type,y
	lda BasicBulletType,x
	sta SpawnData+0

	ldx BSD1Type,y
	lda BasicFireMask,x
	sta SpawnData+1

	lda #$03
	sta SpawnData+2
	jsr AimAndFire

	lda XPosLo,y
	sta CollX+0
	lda XPosHi,y
	sta CollX+1
	lda YPosLo,y
	sta CollY+0
	lda YPosHi,y
	sta CollY+1

	lda #(PAL_ENM << 4) | 15
	sta PalIndx,y

	// Animate the enemy
	lda AnimDelay,y
	inc
	sta AnimDelay,y
	and #3
	bne !noanim+

 	clc
 	lda AnimFrame,y
 	adc #10
 	cmp #50	
 	bne !+

 	lda #$00

!:	
 	sta AnimFrame,y

!noanim:

	// Test collisions
	//
	jsr TestBulletCollision

	lda TestR
	beq !done+

	jsr HandleHit

!done:

	plx
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
drwSpawnBasic: {
	rts
}

// ------------------------------------------------------------
// Draw Play - flying around
//
// params:		Y = object ID
// registers:	A,X,Z free to use
// preserve: 	Y
//
drwPlayBasic: 
{
// 	_sub16im(RRBSpr.XPos, 16, RRBSpr.XPos)
// 	_sub8im(RRBSpr.YPos, 16, RRBSpr.YPos)

// 	lda #<sprEnemy.baseChar
// 	sta RRBSpr.BaseChr+0
// 	lda #>sprEnemy.baseChar
// 	sta RRBSpr.BaseChr+1

// 	lda XVelHi,y
// 	bpl !+

// 	clc
// 	lda RRBSpr.SChr
// 	adc #50
// 	sta RRBSpr.SChr

// !:

// 	lda BSD1Type,y
// 	beq !+

// 	clc
// 	lda RRBSpr.SChr
// 	adc #100
// 	sta RRBSpr.SChr

// !:
// 	lda #RRBSpr32x32
// 	jsr RRBSpr.Draw

	rts
}

SetCosYPos: {
	lda costable,x
	sta YPosLo,y
	lda #$00
	sta YPosFr,y
	sta YPosHi,y

	rts
}

AddCos2YPos: {
	clc
	lda YPosLo,y
	adc costable31,x
	sta YPosLo,y
	lda #$00
	sta YPosFr,y
	sta YPosHi,y

	rts
}

}