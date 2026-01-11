.namespace Enemy
{

.var BSD0Timer = EData0
.var BSD1Type = EData1
.var BSD2Parent = EData2
.var BSD3Flags = EData3

.const BS_INI_VEL_RIGHT = FP(2)
.const BS_INI_VEL_LEFT = FP(-2)

.const YVEL = FP(1)
.const YMAX = FP($100)

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
iniSpawnBasic: 
{
	lda #$07
	sta Life,y

	jsr InitSpawnedPosData

	lda #$00
	sta AnimFrame,y

	jsr GetRandom
	sta Timer,y

	rts
}

// ------------------------------------------------------------
// params:		Y = object ID
// registers:	A,X,Z free to use
// preserve: 	Y
//
updSpawnBasic: 
{
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
iniPlayBasic: 
{
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
updPlayBasic: 
{
	phx

	clc
	lda Timer,y
	adc #$01
	sta Timer,y

	and #$03
	bne no_anim

	clc
	lda AnimFrame,y
	adc #$08
	and #$1f
	sta AnimFrame,y

no_anim:

	clc
	lda YPosLo,y
	adc #<YVEL
	sta YPosLo,y
	lda YPosHi,y
	adc #>YVEL
	sta YPosHi,y

	cmp #>YMAX
	bne no_kill				// off the screen

	lda #StateHide			// kill it
 	jsr SwitchToState

	bra done

no_kill:

	lda XPosLo,y
	sta CollX+0
	lda XPosHi,y
	sta CollX+1
	lda YPosLo,y
	sta CollY+0
	lda YPosHi,y
	sta CollY+1

	lda #(PAL_ENM00 << 4) | 15
	sta PalIndx,y

	// Test collisions
	//
	jsr TestBulletCollision

	lda TestR
	beq done

	jsr HandleHit

done:

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
drwSpawnBasic: 
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
drwPlayBasic: 
{
	_set16im(enemy00Chars.baseChar, DrawBaseChr)			// Start charIndx with first pixie char

	lda PalIndx,y
	sta DrawPal

    _sub16im(DrawPosX, 16, DrawPosX)
    _sub16im(DrawPosY, 16, DrawPosY)

	lda AnimFrame,y
	sta DrawSChr

	ldx #PIXIE_32x32
	jsr DrawPixie

	rts
}

}