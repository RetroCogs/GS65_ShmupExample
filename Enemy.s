// ------------------------------------------------------------
//
// Enemy Flags
//

// Basic:
//
.const ENBAS_HDIR_RIGHT	= $00		// - Horizontal direction	- clear = right
.const ENBAS_HDIR_LEFT	= $80		// - Horizontal direction	- set = left
.const ENBAS_BIGCOS		= $40		// - Big vertical cosine
.const ENBAS_SMLCOS		= $20		// - Small vertical cosine offset (based on timer)
.const ENBAS_SPAWNBLUE	= $10		// - Can spawn blue basics

// Spawner:
//
.const ENSP_PLAYER_REL	= $40

// ------------------------------------------------------------
//
.namespace Enemy
{

.const NUM_ENEMIES = 64

.const BULLCOLL_LEFT	= FP(-$10)
.const BULLCOLL_RIGHT	= FP($20)

.const BULLCOLL_TOP	    = FP(-$10)
.const BULLCOLL_BOTTOM	= FP($20)

// ------------------------------------------------------------
//
.enum {
	// Basic Enemy
	StateSpawnBasic, StatePlayBasic,
	// Spawner
	StateSpawnSpawner, StatePlaySpawner,
	// Common
	StateExplode, StateHide
	}
.var IniStateList = List().add(
	// Basic Enemy
	iniSpawnBasic, iniPlayBasic,
	// Spawner
	iniSpawnSpawner, iniPlaySpawner,
	// Common
	iniExpl, iniHide
	)
.var UpdStateList = List().add(
	// Basic Enemy
	updSpawnBasic, updPlayBasic,
	// Spawner
	updSpawnSpawner, updPlaySpawner,
	// Common
	updExpl, updHide
	)
.var DrwStateList = List().add(
	// Basic Enemy
	drwSpawnBasic, drwPlayBasic,
	// Spawner
	drwSpawnSpawner, drwPlaySpawner,
	// Common
	drwExpl, drwHide
	)

// ------------------------------------------------------------
//
.segment Data "Enemy State Tables"
IniStateTable:
	.fillword IniStateList.size(), IniStateList.get(i)
UpdStateTable:
	.fillword UpdStateList.size(), UpdStateList.get(i)
DrwStateTable:
	.fillword DrwStateList.size(), DrwStateList.get(i)

// ------------------------------------------------------------
//
.segment Zeropage "Enemy"
IndexPtr:		.word $0000
SplitPos:		.byte $00
Size:			.byte $00

CollX:			.word $0000
CollY:			.word $0000
TestX:			.byte $00,$00,$00
TestY:			.byte $00,$00,$00
TestDX:			.word $0000
TestDY:			.word $0000
TestR:			.byte $00

.var ploffs 	= Tmp			// 16bit

// ------------------------------------------------------------
//
.segment BSS "Enemy"
ObjIndxList:
	.fill NUM_ENEMIES, 0

XPosLo:
	.fill NUM_ENEMIES, 0
XPosHi:
	.fill NUM_ENEMIES, 0

XVelLo:
	.fill NUM_ENEMIES, 0
XVelHi:
	.fill NUM_ENEMIES, 0

YVelLo:
	.fill NUM_ENEMIES, 0
YVelHi:
	.fill NUM_ENEMIES, 0

YPosLo:
	.fill NUM_ENEMIES, 0
YPosHi:
	.fill NUM_ENEMIES, 0

Status:
	.fill NUM_ENEMIES, 0

AnimDelay:
	.fill NUM_ENEMIES, 0
AnimFrame:
	.fill NUM_ENEMIES, 0
Timer:
	.fill NUM_ENEMIES, 0
PalIndx:
	.fill NUM_ENEMIES, 0

Life:
	.fill NUM_ENEMIES, 1
EData0:
	.fill NUM_ENEMIES, 0
EData1:
	.fill NUM_ENEMIES, 0
EData2:
	.fill NUM_ENEMIES, 0
EData3:
	.fill NUM_ENEMIES, 0

FireChanceIndx:
	.fill NUM_ENEMIES, 0

FireCount:
	.byte $00

SpIndx:
	.byte $00


// ------------------------------------------------------------
//
.segment Code "Enemy"
InitList: 
{
	_initlist(ObjIndxList, SplitPos, IndexPtr, NUM_ENEMIES, Size)

	lda #$00
	sta FireCount
	sta SpIndx

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
EnmSpawnType:
	.byte StateSpawnBasic, StateSpawnSpawner

// ------------------------------------------------------------
// params:		A = enemy type
//				Z = parent ID
// registers:	A,X,Y,Z free to use
//
Create: 
{
	.var spawnType = Tmp		// 8bit

	sta spawnType

	// returns Y = newly created enemy slot
	jsr Alloc
	beq !+						// Couldn't allocate

	// Y = object ID
	// Z = parent ID

	ldx spawnType

	// All types start being inactive
	lda #$00
	sta AnimDelay,y 

	_clearEnmStatus()

	lda #$07
	sta FireChanceIndx,y

	// State the player in spawn state
	lda EnmSpawnType,x
	jsr SwitchToState

	inc SpIndx

!:
	rts
}

// params:	y = object ID
//			z = spawn Parent
//
SwitchToState: 
{
	_setEnmStateFromA()

	_getEnmStateToA()
	asl
	tax
	jsr (IniStateTable,x)

	rts
}

// ------------------------------------------------------------
//
Update: 
{
	// 
	ldz SplitPos
	lbra checkdone

moveloop:
	// X = index of current object
	lda (IndexPtr),z
	tay

	_getEnmStateToA()
	asl
	tax

	phz
	jsr (UpdStateTable,x)
	plz

	lda Life,y
	bpl stillalive

	// handle the dead case, free the object at slot Z
	tza
	tay
	jsr Free

stillalive:
	inz

checkdone:
	cpz Size
	lbne moveloop

	rts
}

// ------------------------------------------------------------
//
Draw: 
{
	//
	ldz SplitPos
	bra checkdone

drawloop:
	lda (IndexPtr),z
	tay

	jsr setScreenPos

	_getEnmStateToA()
	asl
	tax

	phz
	jsr (DrwStateTable,x)
	plz

	_testEnmFlag(ENMST_ACTIVE)
	beq !+

!:
	inz

checkdone:
	cpz Size
	bne drawloop

	rts
}

// ------------------------------------------------------------
#import "EnmBasic.s"
#import "EnmSpawner.s"

// ------------------------------------------------------------
HandleHit: 
{
	lda #(PAL_FLASH << 4) | 15
	sta PalIndx,y

	sec
	lda Life,y
	sbc #$01
	sta Life,y
	bne !+

	// ldx #$00
	// jsr Player.AddScore

	jsr Player.HitEnemy

	// jsr PlaySample3

	// Switch to explode state
	lda #StateExplode
	jsr SwitchToState

	lda #$00
!:
	rts
}

// ------------------------------------------------------------
// Explode state - kabooming
//
// params:		Y = object ID
// preserve: 	Y and Z
//
iniExpl: 
{
	// Now inactive
	_clearEnmFlag(ENMST_ACTIVE)

	lda #$05
	sta Life,y

	lda #$00
	sta AnimFrame,y
	sta Timer,y

	lda #(PAL_BULLETS << 4) | $0f
	sta PalIndx,y

	ldx Irq.VBlankCount
	lda rngtable,x
	cmp #$10
	bcs !+

//	jsr SpawnPickup

!:

	rts
}

updExpl: 
{
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

 	lda #StateHide
 	jsr SwitchToState

!:	
 	sta AnimFrame,y

!noanim:
	rts
}

// ------------------------------------------------------------
// Hide state - not updating or drawing
//
// params:		Y = object ID
// preserve: 	Y and Z
//
iniHide: 
{
	lda #$03
	sta Timer,y
	rts
}

updHide: 
{
	sec
	lda Timer,y
	sbc #$1
	sta Timer,y
	bpl !+

 	lda #$ff
 	sta Life,y

!:
	rts
}

// ------------------------------------------------------------
// Draw Explode - kaboom
//
// params:		Y = object ID
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
// params:		Y = object ID
// preserve: 	Y and Z
//
drwHide: 
{
	rts
}

// ------------------------------------------------------------
//
TestBulletCollision: 
{
	lda #$00
	sta TestR

	phz
	phy

	ldz Bullets.SplitPos
	bra bcolldone

bcollloop:
	lda (Bullets.IndexPtr),z
	tay

	sec
	lda Bullets.ObjXLo,y
	sbc CollX+0
	sta TestX+0
	lda Bullets.ObjXHi,y
	sbc CollX+1
	sta TestX+1

	sec
	lda Bullets.ObjYLo,y
	sbc CollY+0
	sta TestY+0
	lda Bullets.ObjYHi,y
	sbc CollY+1
	sta TestY+1

	sec
	lda TestX+0
	sbc #<BULLCOLL_LEFT
	sta bcheck0
	lda TestX+1
	sbc #>BULLCOLL_LEFT
	sta bcheck1
	bmi !+

	lda bcheck0:#$00
	cmp #<BULLCOLL_RIGHT
	lda bcheck1:#$00
	sbc #>BULLCOLL_RIGHT
	bcs !+

	sec
	lda TestY+0
	sbc #<BULLCOLL_TOP
	sta bcheck2
	lda TestY+1
	sbc #>BULLCOLL_TOP
	sta bcheck3
	bmi !+

	lda bcheck2:#$00
	cmp #<BULLCOLL_BOTTOM
	lda bcheck3:#$00
	sbc #>BULLCOLL_BOTTOM
	bcs !+

	lda #$01
	sta TestR

	lda #$00
	sta Bullets.ObjL,y

!:

	inz

bcolldone:
	cpz Bullets.Size
	bne bcollloop

	ply
	plz

	rts
}

// ------------------------------------------------------------
//
fireBitTable:
	.fill 8, (1<<i)

AimAndFire: {
	// Only aim and fire if the player is active
	lda Player.Active
	lbeq _dont_aim

	// TODO: customized fire rates per enemy!
	lda Timer,y
	and #$1f
	lbne _dont_aim

	// Cycle through the fire chance bits
	clc
	lda FireChanceIndx,y
	adc #$01
	and #$07
	sta FireChanceIndx,y

	// If player is more that $100 pixels away, don't aim
	// lda ploffs+0
	// cmp #$00
	// lda ploffs+1
	// sbc #$02
	// lbcs _dont_aim

	// Is the bit set for this chance?
	lda FireChanceIndx,y
	tax
	lda fireBitTable,x
	and SpawnData+1
	lbeq _dont_aim

	// Calc angle from enemy to player
	//
	jsr CalcAngleToPlayer

	ldx.zp angle
	lda #$00
	ldz #$07
	jsr AngleFire

_dont_aim:

	rts
}

// ------------------------------------------------------------
//
CalcAngleToPlayer: {
	sec
	lda Player.XPos+0
	sbc XPosLo,y
	sta Tmp+0
	lda Player.XPos+1
	sbc XPosHi,y
	sta Tmp+1

	asl Tmp+0
	rol Tmp+1

	lda Tmp+1
	sta.zp dx

	sec
	lda Player.YPos+0
	sbc YPosLo,y
	sta Tmp1+0
	lda Player.YPos+1
	sbc YPosHi,y
	sta Tmp1+1

	lda Tmp1+1
	cmp #$80
	ror
	ror Tmp1+0
	sta Tmp1+1

	lda Tmp1+1
	cmp #$80
	ror
	ror Tmp1+0
	sta Tmp1+1

	lda Tmp1+0
	sta.zp dy

	jsr atan2

	rts
}

// ------------------------------------------------------------
// X    = Angle
// A,Z  = 8.8 Length
//
AngleFire: {
	// assumes x, a and z are correctly set
	jsr calcVector

	_set16(resultX, EnmProjectiles.SpawnVelX)
	_set24(resultY, EnmProjectiles.SpawnVelY)
	
	// Starting positin is that of parent enemy
	lda XPosLo,y
	sta SpawnPosX+0
	lda XPosHi,y
	sta SpawnPosX+1

	lda YPosLo,y
	sta SpawnPosY+0
	lda YPosHi,y
	sta SpawnPosY+1

	// Create the projectile
	phy
	jsr EnmProjectiles.CreateEnmProjectile
	ply

	rts
}

// ------------------------------------------------------------
//
CalcDistanceToPlayer: {
	// Calc the absolute distance to the player in the X axis
	sec
	lda Player.XPos+0
	sbc XPosLo,y
	sta ploffs+0
	lda Player.XPos+1
	sbc XPosHi,y
	sta ploffs+1
	rts	
}

// ------------------------------------------------------------
//
CalcRelativeDistanceToPlayer: {
	jsr CalcDistanceToPlayer

	bpl !+

	// negate
	lda ploffs+0
	eor #$ff
	sta ploffs+0
	lda ploffs+1
	eor #$ff
	sta ploffs+1
!:	
	rts
}

// ------------------------------------------------------------
// SetScreenPos - takes world position and makes it screen relative
//
setScreenPos: 
{
	lda #$08
	sta $d770
	lda #$00
	sta $d771
	sta $d772
	sta $d776

	lda XPosLo,y
	sta $d774
	lda XPosHi,y
	sta $d775

	_set16($d779, DrawPosX)

	lda YPosLo,y
	sta $d774
	lda YPosHi,y
	sta $d775

	_set16($d779, DrawPosY)

	rts
}

// ------------------------------------------------------------
// Apply X Velocity to X Pos
//
ApplyVelocityX: {
	clc
	lda XPosLo,y
	adc XVelLo,y
	sta XPosLo,y
	lda XPosHi,y
	adc XVelHi,y
	sta XPosHi,y
	rts
}

// ------------------------------------------------------------
// Apply Y Velocity to Y Pos
//
ApplyVelocityY: {
	clc
	lda YPosLo,y
	adc YVelLo,y
	sta YPosLo,y
	lda YPosHi,y
	adc YVelHi,y
	sta YPosHi,y
	rts
}

// ------------------------------------------------------------
// Test X Limits and kill if outside
//
TestKillLimitsX: 
{
// 	// Check direction of X velocity
// 	lda XVelHi,y
// 	bmi _check_nve

// 	// Velocity X is heading right, check for right bounds

// 	// +ve velx
// 	sec
// 	lda XPosLo,y
// 	sbc #<TMAX_MAP_AREA_X
// 	lda XPosHi,y
// 	sbc #>TMAX_MAP_AREA_X
// 	bmi _done_check

// 	// kill off
// 	lda #$ff
// 	sta Life,y

// 	bra _done_check

// _check_nve:
// 	// Velocity X is heading left, check for left bounds
// 	// -ve velx
// 	sec
// 	lda XPosLo,y
// 	sbc #<TMIN_MAP_AREA_X
// 	lda XPosHi,y
// 	sbc #>TMIN_MAP_AREA_X
// 	bpl _done_check

// 	// kill off
// 	lda #$ff
// 	sta Life,y

// _done_check:
	rts
}

NegateXVelocity: {
	lda XVelLo,y
	eor #$ff
	sta XVelLo,y
	lda XVelHi,y
	eor #$ff
	sta XVelHi,y
	clc
	lda XVelLo,y
	adc #$01
	sta XVelLo,y
	lda XVelHi,y
	adc #$00
	sta XVelHi,y

	rts
}

NegateYVelocity: {
	lda YVelLo,y
	eor #$ff
	sta YVelLo,y
	lda YVelHi,y
	eor #$ff
	sta YVelHi,y
	clc
	lda YVelLo,y
	adc #$01
	sta YVelLo,y
	lda YVelHi,y
	adc #$00
	sta YVelHi,y
	rts
}

LimitVelocityX: {
	.var vel_limit_pve = Tmp1		// 16bit
	.var vel_limit_nve = Tmp2		// 16bit

	// Check direction of velocity
	lda XVelHi,y
	bmi _limit_nve

	// +ve limiting, velocity is pointing right
	//

	// are we hitting the velocity limit?
	sec
	lda XVelLo,y
	sbc vel_limit_pve+0
	lda XVelHi,y
	sbc vel_limit_pve+1
	bmi _done_limiting

	// set to the velocity limit
	lda vel_limit_pve+0
	sta XVelLo,y
	lda vel_limit_pve+1
	sta XVelHi,y

	bra _done_limiting

_limit_nve:
	// -ve limiting, velocity is pointing left
	//

	sec
	lda XVelLo,y
	sbc vel_limit_nve+0
	lda XVelHi,y
	sbc vel_limit_nve+1
	bpl _done_limiting

	// set to the velocity limit
	lda vel_limit_nve+0
	sta XVelLo,y
	lda vel_limit_nve+1
	sta XVelHi,y

_done_limiting:

	rts
}

LimitVelocityY: {
	.var vel_limit_pve = Tmp1		// 16bit
	.var vel_limit_nve = Tmp1+2		// 16bit

	// Check direction of velocity
	lda YVelHi,y
	bmi _limit_nve

	// +ve limiting, velocity is pointing right
	//

	// are we hitting the velocity limit?
	sec
	lda YVelLo,y
	sbc vel_limit_pve+0
	lda YVelHi,y
	sbc vel_limit_pve+1
	bmi _done_limiting

	// set to the velocity limit
	lda vel_limit_pve+0
	sta YVelLo,y
	lda vel_limit_pve+1
	sta YVelHi,y

	bra _done_limiting

_limit_nve:
	// -ve limiting, velocity is pointing left
	//

	sec
	lda YVelLo,y
	sbc vel_limit_nve+0
	lda YVelHi,y
	sbc vel_limit_nve+1
	bpl _done_limiting

	// set to the velocity limit
	lda vel_limit_nve+0
	sta YVelLo,y
	lda vel_limit_nve+1
	sta YVelHi,y

_done_limiting:

	rts
}

// -------------------------------------------------------
// A,Z  = 8.8 Length
//
calcNewDirection: 
{
	pha
	phz

	// Calc angle from enemy to player
	//
	jsr CalcAngleToPlayer
	ldx.zp angle

	plz
	pla

	jsr calcVector

	clc
	lda XVelLo,y
	adc.zp resultX+0
	sta XVelLo,y
	lda XVelHi,y
	adc.zp resultX+1
	sta XVelHi,y

	clc
	lda YVelLo,y
	adc.zp resultY+0
	sta YVelLo,y
	lda YVelHi,y
	adc.zp resultY+1
	sta YVelHi,y

	rts
}

CalcVectorFromAngle: {
	lda #$00
	sta TestX+1
	lda costable31,x
	cmp #$80
	bcc !+
	dec TestX+1
!:
	sta TestX+0

	lda #$00
	sta TestY+1
	sta TestY+2
	lda sintable127,x
	cmp #$80
	bcc !+
	dec TestY+1
	dec TestY+2
!:
	sta TestY+0

	ldx #$00
!:
	asl TestX+0
	rol TestX+1
	asl TestY+0
	rol TestY+1
	rol TestY+2

	inx
	cpx #$02
	bne !-

	rts
}

InitSpawnedPosData: 
{
	lda SpawnPosX+0
	sta XPosLo,y
	lda SpawnPosX+1
	sta XPosHi,y

	lda SpawnPosY+0
	sta YPosLo,y
	lda SpawnPosY+1
	sta YPosHi,y

	lda SpawnData+0
	sta EData0,y
	lda SpawnData+1
	sta EData1,y
	lda SpawnData+2
	sta EData2,y
	lda SpawnData+3
	sta EData3,y

	rts
}

// ------------------------------------------------------------
// UpdateSpawn, 
//
// x = state to switch to when spawning is done
//
UpdateSpawn: {
	lda AnimDelay,y
	inc
	sta AnimDelay,y
	and #$07
	bne !noanim+

 	clc
 	lda AnimFrame,y
 	adc #10
 	cmp #100	
 	bne !+

	// done spawning
	txa
	jsr SwitchToState

 	lda #$00
	sta AnimDelay,y

!:	
 	sta AnimFrame,y

!noanim:

	rts
}

// ------------------------------------------------------------
// DrawSpawn, generic draw routine for spawn in ... 
//
DrawSpawn: {
	// _sub16im(RRBSpr.XPos, 16, RRBSpr.XPos)
	// _sub8im(RRBSpr.YPos, 16, RRBSpr.YPos)

	// lda #<sprSpawn.baseChar
	// sta RRBSpr.BaseChr+0
	// lda #>sprSpawn.baseChar
	// sta RRBSpr.BaseChr+1

	// lda #RRBSpr32x32
	// jsr RRBSpr.Draw

	rts
}

}