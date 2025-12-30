.namespace Player
{

.const INC_POS		= PX(2)
.const MIN_XPOS		= $10
.const MAX_XPOS		= $f0
.const MIN_YPOS		= $40
.const MAX_YPOS		= $D0

// ------------------------------------------------------------
//
.enum {StateSpawn, StatePlay, StateExplode, StateHide}
.var IniStateList = List().add(iniSpawn, iniPlay, iniExpl, iniHide)
.var UpdStateList = List().add(updSpawn, updPlay, updExpl, updHide)
.var DrwStateList = List().add(drwPlay, drwPlay, drwExpl, drwHide)

// ------------------------------------------------------------
.segment Zeropage "Player"
CollX:			.word $0000
CollY:			.word $0000
TestX:			.word $0000
TestY:			.word $0000
TestR:			.byte $00

DelX:			.word $0000

// ------------------------------------------------------------
//
.segment BSS "Player"
XPosFr:				.byte 	$00
XPos:				.byte 	$00,$00
YPosFr:				.byte 	$00
YPos:				.byte	$00,$00
AnimFrame:			.byte	$00
PalIndx:			.byte	(PAL_PLAYER << 4) | 15
Dir:				.byte	$01
Timer:				.byte	$00

ShootDelay:			.byte	$00

State:				.byte	$00

Active:				.byte 	$00

// ------------------------------------------------------------
//
.segment Data "Player State Tables"
IniStateTable:
	.fillword IniStateList.size(), IniStateList.get(i)
UpdStateTable:
	.fillword UpdStateList.size(), UpdStateList.get(i)
DrwStateTable:
	.fillword DrwStateList.size(), DrwStateList.get(i)

// ------------------------------------------------------------
//
.segment Code "Player"
Init: 
{
	// Player starts inactive
	lda #$00
	sta Active

	// State the player in spawn state
	lda #StateSpawn
	jsr SwitchToState

	rts
}

SwitchToState: 
{
	sta State
	asl
	tax
	jsr (IniStateTable,x)
	rts
}

Update: 
{
	lda State
	asl
	tax
	jsr (UpdStateTable,x)
	rts
}

Draw: 
{
	jsr setScreenPos

	lda State
	asl
	tax
	jsr (DrwStateTable,x)
	rts
}

// ------------------------------------------------------------
// Update functions
//
// Spawn state - show the player warping in
//
// params:		Y = object Indx
// preserve: 	Y and Z
//
iniSpawn: 
{
	// jsr ResetScMult

	// jsr ResetShield

	lda #0
	sta Timer

	// sta Dead
	// sta AnimFrame
	// sta Dir
	// sta Thrusting
	// sta ShieldDisrupt

	// lda #(PAL_PLAYER << 4) | $0f
	// sta PalIndx

	_set24im(PX($80),XPosFr)
	_set24im(PX($c0),YPosFr)

	rts
}

updSpawn: 
{
	clc
	lda Timer
	adc #$01
	sta Timer
	cmp #$02
	bne !+

	// State the player in spawn state
	lda #StatePlay
	jsr SwitchToState

!:
	rts
}

// ------------------------------------------------------------
// Play state - flying and shooting
//
// params:		Y = object Indx
// preserve: 	Y and Z
//
iniPlay: 
{
	// Now active
	lda #$01
	sta Active

	lda #$00
	sta ShootDelay
	
	rts
}

updPlay: 
{
	inc Timer

	// ------------------------------------------------ Test for UP
	lda System.DPad
	and #$01
	beq _not_up

	_sub24im(YPosFr, INC_POS, YPosFr)

	sec
	lda YPos+0
	sbc #<MIN_YPOS
	lda YPos+1
	sbc #>MIN_YPOS
	lbpl _not_up

	_set16im(MIN_YPOS, YPos)

_not_up:

	// ------------------------------------------------ Test for DOWN
	lda System.DPad
	and #$02
	beq _not_down

	_add24im(YPosFr, INC_POS, YPosFr)

	sec
	lda YPos+0
	sbc #<MAX_YPOS
	lda YPos+1
	sbc #>MAX_YPOS
	lbmi _not_down

	_set16im(MAX_YPOS, YPos)

_not_down:

	// ------------------------------------------------ Test for RIGHT
	lda System.DPad
	and #$08
	beq _not_right

	_add24im(XPosFr, INC_POS, XPosFr)

	sec
	lda XPos+0
	sbc #<MAX_XPOS
	lda XPos+1
	sbc #>MAX_XPOS
	lbmi _not_right

	_set16im(MAX_XPOS, XPos)

_not_right:

	// ------------------------------------------------ Test for LEFT
	lda System.DPad
	and #$04
	beq _not_left

	_sub24im(XPosFr, INC_POS, XPosFr)

	sec
	lda XPos+0
	sbc #<MIN_XPOS
	lda XPos+1
	sbc #>MIN_XPOS
	lbpl _not_left

	_set16im(MIN_XPOS, XPos)

_not_left:

	lda ShootDelay
	beq _test_shoot

	dec ShootDelay
	bra _no_shoot

_test_shoot:
	lda System.DPad
	and #$10
	beq _no_shoot

// 	jsr PlaySample2
	
	ldx #$00
	jsr Bullets.CreateBullet
	ldx #$01
	jsr Bullets.CreateBullet

	lda #$03
	sta ShootDelay

_no_shoot:

// 	lda #(PAL_PLAYER << 4) | $0f
// 	sta PalIndx

// 	jsr DecreaseScMult

// 	jsr TestEnemyCollision

// 	lda TestR
// 	sta encoll

// 	jsr TestBulletCollision

// 	// Did we get hit by anything?
// 	lda TestR
// 	ora encoll:#$00
// 	beq _nohit

// 	and #$02
// 	beq normalHit

// 	// Electric Hit

// 	// Was hit, flash palette
// 	lda #(PAL_FLASH << 4) | 15
// 	sta PalIndx

// 	// Disrupt Shield
// 	lda #$1f
// 	sta ShieldDisrupt

// 	// bra _nohit

// normalHit:
// 	// Was hit, flash palette
// 	lda #(PAL_FLASH << 4) | 15
// 	sta PalIndx

// 	// jsr ResetScMult

// 	lda #$01
// 	sta ShFramesSinceHit

// 	sec
// 	lda ShAmount
// 	sbc #MAX_HITSUB
// 	sta ShAmount
// 	bpl dontfixmin

// 	lda #$00
// 	sta ShAmount

// dontfixmin:
// 	lda ShAmount
// 	bne _done

#if PLAYER_CANDIE
	// jsr PlaySample3

	// Switch to explode state
	// lda #StateExplode
	// jsr SwitchToState
	// bra _done
#endif 

_done:
_nohit:

	rts
}

// ------------------------------------------------------------
// Explode state - kabooming
//
// params:		Y = object Indx
// preserve: 	Y and Z
//
iniExpl: 
{
	// // Dead so inactive
	// lda #$00
	// sta Active

	// lda #0
	// sta AnimFrame
	// lda #(PAL_BULLETS << 4) | $0f
	// sta PalIndx
	rts
}

updExpl: 
{
// 	lda VBlankCount
// 	and #3
// 	bne !+

//  	clc
//  	lda AnimFrame
//  	adc #10
//  	sta AnimFrame
//  	cmp #50	
//  	bne !+

//  	lda #StateHide
// 	jsr SwitchToState

// !:	
	rts
}

// ------------------------------------------------------------
// Hide state - not updating or drawing
//
// params:		Y = object Indx
// preserve: 	Y and Z
//
iniHide: 
{
	// lda #$60
	// sta Timer

	rts
}

updHide: 
{
// 	// don't decrease if 0
// 	lda Timer
// 	beq !+

// 	dec Timer
// 	lda Timer
// 	bne !+

// 	// State the player in spawn state
// 	// lda #StateSpawn
// 	// jsr SwitchToState

// 	lda #$01
// 	sta Dead

// !:
	rts
}

// ------------------------------------------------------------
// Draw functions - the number of draw states are generally less
// that update states because you can often share drawing logic
// across the update logic
// 
// Draw Spawn - player showing up
//
// params:		Y = object Indx
// preserve: 	Y and Z
//
drwSpawn: 
{
	rts
}

// ------------------------------------------------------------
// Draw Play - ship flying around
//
// params:		Y = object Indx
// preserve: 	Y and Z
//
drwPlay: 
{
	_set16im(playerChars.baseChar, DrawBaseChr)			// Start charIndx with first pixie char

	_set8im((PAL_PLAYER << 4) | $0f, DrawPal)

	_sub16im(XPos, 16, DrawPosX)
	_sub16im(YPos, 16, DrawPosY)

	lda #$00
	sta DrawSChr

	ldx #PIXIE_32x32
	jsr DrawPixie

	rts
}

// ------------------------------------------------------------
// Draw Explode - kaboom
//
// params:		Y = object Indx
// preserve: 	Y and Z
//
drwExpl: 
{
	// _sub16im(RRBSpr.XPos, 16, RRBSpr.XPos)
	// _sub8im(RRBSpr.YPos, 16, RRBSpr.YPos)

	// lda #<sprExplo.baseChar
	// sta RRBSpr.BaseChr+0
	// lda #>sprExplo.baseChar
	// sta RRBSpr.BaseChr+1

	// lda #RRBSpr32x32
	// jsr RRBSpr.Draw

	rts
}

// ------------------------------------------------------------
// Draw Hide - don't draw
//
// params:		Y = object Indx
// preserve: 	Y and Z
//
drwHide: 
{
	rts
}

// ------------------------------------------------------------
// SetScreenPos - takes world position and makes it screen relative
//
setScreenPos: 
{
// 	_sub16(XPos+0, Camera.XPos, RRBSpr.XPos)
		
// 	lda #$08						// 2		20
// 	sta $d770						// 4
// 	lda #$00						// 2
// 	sta $d771						// 4		
// 	sta $d772						// 4
// 	sta $d776						// 4
// 	_set16(RRBSpr.XPos, $d774)		// 6 + 8	14
// 	_set16($d779,RRBSpr.XPos)		// 8 + 6	14

// 	_add16im(YPos+1, 0, RRBSpr.YPos)

// 	lda AnimFrame
// 	sta RRBSpr.SChr
	
// 	lda Timer
// 	and #$04
// 	bne notThrusting

// 	lda AnimFrame
// 	cmp #$00
// 	bne notLeft

// 	lda Thrusting
// 	beq notThrusting

// 	lda #30
// 	sta RRBSpr.SChr
// 	bra notThrusting

// notLeft:

// 	lda AnimFrame
// 	cmp #24
// 	bne notThrusting

// 	lda Thrusting
// 	beq notThrusting

// 	lda #36
// 	sta RRBSpr.SChr

// notThrusting:
// 	lda PalIndx
// 	sta RRBSpr.Pal
	rts
}

// ------------------------------------------------------------
//
TestBulletCollision: 
{
// 	lda #$00
// 	sta TestR

// 	phz
// 	phy

// 	ldz EnmProjectiles.SplitPos
// 	bra bcolldone

// bcollloop:
// 	lda (EnmProjectiles.IndexPtr),z
// 	tay

// 	sec
// 	lda EnmProjectiles.ObjXLo,y
// 	sbc CollX+0
// 	sta TestX+0
// 	lda EnmProjectiles.ObjXHi,y
// 	sbc CollX+1
// 	sta TestX+1

// 	sec
// 	lda EnmProjectiles.ObjYLo,y
// 	sbc CollY+0
// 	sta TestY+0
// 	lda EnmProjectiles.ObjYHi,y
// 	sbc CollY+1
// 	sta TestY+1

// 	sec
// 	lda TestX+0
// 	sbc #<PLAYER_ENM_PROJ_COLL_LEFT
// 	sta bcheck0
// 	lda TestX+1
// 	sbc #>PLAYER_ENM_PROJ_COLL_LEFT
// 	sta bcheck1
// 	bmi !+

// 	lda bcheck0:#$00
// 	cmp #<PLAYER_ENM_PROJ_COLL_RIGHT
// 	lda bcheck1:#$00
// 	sbc #>PLAYER_ENM_PROJ_COLL_RIGHT
// 	bcs !+

// 	sec
// 	lda TestY+0
// 	sbc #$f8
// 	sta bcheck2
// 	lda TestY+1
// 	sbc #$ff
// 	sta bcheck3
// 	bmi !+

// 	lda bcheck2:#$00
// 	cmp #$10
// 	lda bcheck3:#$00
// 	sbc #$00
// 	bcs !+

// 	lda TestR
// 	ora #$01
// 	sta TestR

// 	lda EnmProjectiles.ObjSprBase,y 
// 	cmp #$0c
// 	bne notEnergyBullet

// 	lda TestR
// 	ora #$02
// 	sta TestR

// notEnergyBullet:

// 	lda #$00
// 	sta EnmProjectiles.ObjL,y

// !:

// 	inz

// bcolldone:
// 	cpz EnmProjectiles.Size
// 	bne bcollloop

// 	ply
// 	plz

	rts
}

// ------------------------------------------------------------
//
TestEnemyCollision: 
{
// 	lda #$00
// 	sta TestR

// 	phz
// 	phy

// 	ldz Enemy.SplitPos
// 	bra bcolldone

// bcollloop:
// 	lda (Enemy.IndexPtr),z
// 	tay

// 	_testEnmFlag(ENMST_ACTIVE)
// 	beq !+

// 	sec
// 	lda Enemy.XPosLo,y
// 	sbc CollX+0
// 	sta TestX+0
// 	lda Enemy.XPosHi,y
// 	sbc CollX+1
// 	sta TestX+1

// 	sec
// 	lda Enemy.YPosLo,y
// 	sbc CollY+0
// 	sta TestY+0
// 	lda Enemy.YPosHi,y
// 	sbc CollY+1
// 	sta TestY+1


// 	sec
// 	lda TestX+0
// 	sbc #<PLAYER_ENM_COLL_LEFT
// 	sta bcheck0
// 	lda TestX+1
// 	sbc #>PLAYER_ENM_COLL_LEFT
// 	sta bcheck1
// 	bmi !+

// 	lda bcheck0:#$00
// 	cmp #<PLAYER_ENM_COLL_RIGHT
// 	lda bcheck1:#$00
// 	sbc #>PLAYER_ENM_COLL_RIGHT
// 	bcs !+

// 	sec
// 	lda TestY+0
// 	sbc #$f4
// 	sta bcheck2
// 	lda TestY+1
// 	sbc #$ff
// 	sta bcheck3
// 	bmi !+

// 	lda bcheck2:#$00
// 	cmp #$18
// 	lda bcheck3:#$00
// 	sbc #$00
// 	bcs !+

// 	lda #$01
// 	sta TestR

// 	jsr Enemy.HandleHit

// !:

// 	inz

// bcolldone:
// 	cpz.zp Enemy.Size
// 	bne bcollloop

// 	ply
// 	plz

	rts
}

HitEnemy: 
{
	// jsr IncreaseScMult
	rts
}

// ------------------------------------------------------------

}