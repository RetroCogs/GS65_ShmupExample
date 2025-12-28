// ------------------------------------------------------------
//
.segment Zeropage "GameState Credits"

.segment Code "GameState Credits"

// ------------------------------------------------------------
//
// Titles State - show titles screen
//
gsIniCredits: 
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

	jsr InitObjData

	jsr InitLayoutCommon

	jsr InitPixies

	rts
}

// ------------------------------------------------------------
//
gsUpdCredits: 
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

	lda Irq.VBlankCount
	and #$00
	lbne donemove

	_add16(Camera.XScroll, Camera.CamVelX, Camera.XScroll)
	_add16(Camera.YScroll, Camera.CamVelY, Camera.YScroll)

donemove:

	jsr UpdateObjData

	jsr UpdateLayoutCommon

	lda System.DPadClick
	and #$10
	beq _not_fire

	lda #GStateTitles
	sta RequestGameState

_not_fire:

	rts
}

// ------------------------------------------------------------
//
gsDrwCredits: 
{
	_set8im($0f, DrawPal)

	jsr DrawObjData

	rts
}



