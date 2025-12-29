// ------------------------------------------------------------
//
.const NUM_OBJS1 = 256

.segment Zeropage "GameState Play"

.segment Code "GameState Play"

// ------------------------------------------------------------
//
// Titles State - show titles screen
//
gsIniPlay: 
{
	lda #$00
	sta Irq.VBlankCount

	lda #$00
	sta GameSubState
	sta GameStateTimer

	lda #$00
	sta GameStateData+0
	sta GameStateData+1
	sta GameStateData+2

	_set16im($0000, Camera.YScroll)
	_set16im($ffff, Camera.CamVelY)

	_set16im($0000, Camera.XScroll)
	_set16im($0000, Camera.CamVelX)

	jsr Player.Init
	jsr Bullets.InitList

	jsr InitLayoutCommon

	jsr InitPixies

	rts
}

// ------------------------------------------------------------
//
gsUpdPlay: 
{
	// Inc the game state timer
	_add16im(GameStateData, 1, GameStateData)
	lda GameStateData+0
	cmp #$c0
	lda GameStateData+1
	sbc #$02
	bcc !+
	_set16im(0, GameStateData)

	clc
	lda GameStateData+2
	adc #$01
	and #$03
	sta GameStateData+2
!:

//	_add16im(Camera.XScroll, 1, Camera.XScroll)

	lda Irq.VBlankCount
	and #$00
	lbne donemove

	_add16(Camera.XScroll, Camera.CamVelX, Camera.XScroll)
	_add16(Camera.YScroll, Camera.CamVelY, Camera.YScroll)


donemove:

	jsr Player.Update
	jsr Bullets.Update

	jsr UpdateLayoutCommon

// 	lda System.DPadClick
// 	and #$10
// 	beq _not_fire

// 	lda #GStateCredits
// 	sta RequestGameState

// _not_fire:

	rts
}

// ------------------------------------------------------------
//
gsDrwPlay: 
{
	jsr Bullets.Draw
	jsr Player.Draw

	rts
}

// ---
.segment Data "GameState Play"

// ------------------------------------------------------------
//
.segment BSS "Obj Data"

Objs1PosXLo:
	.fill NUM_OBJS1, 0
Objs1PosXHi:
	.fill NUM_OBJS1, 0
Objs1PosYLo:
	.fill NUM_OBJS1, 0
Objs1VelXLo:
	.fill NUM_OBJS1, 0
Objs1VelXHi:
	.fill NUM_OBJS1, 0
Objs1VelY:
	.fill NUM_OBJS1, 0
Objs1Spr:
	.fill NUM_OBJS1, 0




