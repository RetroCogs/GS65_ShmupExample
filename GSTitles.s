.segment Zeropage "GameState Titles"

.segment Code "GameState Titles"

// ------------------------------------------------------------
//
// Titles State - show titles screen
//
gsIniTitles: 
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
	_set16im($0001, Camera.CamVelY)

	_set16im($0000, Camera.XScroll)
	_set16im($0001, Camera.CamVelX)

	jsr InitLayoutCommon

	jsr InitPixies

	rts
}

// ------------------------------------------------------------
//
gsUpdTitles: 
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

	// _add16im(Camera.XScroll, 1, Camera.XScroll)

	lda Irq.VBlankCount
	and #$00
	lbne donemove

	_add16(Camera.XScroll, Camera.CamVelX, Camera.XScroll)
	_add16(Camera.YScroll, Camera.CamVelY, Camera.YScroll)

	// Min X bounds
	lda Camera.XScroll+1
	bpl !+

	_set16im($0000, Camera.XScroll)
	_set16im($0001, Camera.CamVelX)

!:

	// Max X bounds
	sec
	lda Camera.XScroll+0
	sbc #<MAXXBOUNDS
	lda Camera.XScroll+1
	sbc #>MAXXBOUNDS
	bmi !+

	_set16im(MAXXBOUNDS, Camera.XScroll)
	_set16im($ffff, Camera.CamVelX)

!:
	// Min Y bounds
	lda Camera.YScroll+1
	bpl !+

	_set16im($0000, Camera.YScroll)
	_set16im($0001, Camera.CamVelY)

!:

	// Max Y bounds
	sec
	lda Camera.YScroll+0
	sbc #<MAXYBOUNDS
	lda Camera.YScroll+1
	sbc #>MAXYBOUNDS
	bmi !+

	_set16im(MAXYBOUNDS, Camera.YScroll)
	_set16im($ffff, Camera.CamVelY)

!:

donemove:

	jsr UpdateLayoutCommon

	lda System.DPadClick
	and #$10
	beq _not_fire

	lda #GStatePlay
	sta RequestGameState

_not_fire:

	rts
}

// ------------------------------------------------------------
//
gsDrwTitles: 
{
	_set8im($0f, DrawPal)

	// lda Camera.YScroll+0
	// sta PixieYShift
	
	DbgBord(11)

	lda #$50
	sta TextPosY

	sec
	lda Layout.LayoutWidth+0
	sbc GameStateData+0
	sta TextPosX+0
	lda Layout.LayoutWidth+1
	sbc GameStateData+1
	sta TextPosX+1

	lda GameStateData+2
	asl
	tay

    lda introTxtTable,y
    sta TextPtr+0
    lda introTxtTable+1,y
    sta TextPtr+1

	TextDrawSpriteMsg(false, 192, true)

	DbgBord(9)

	TextSetPos($30,$20)
	TextSetMsgPtr(testTxt1)
	TextDrawSpriteMsg(true, 0, true)

	DbgBord(10)

	TextSetPos($30,$70)
	TextSetMsgPtr(testTxt2)
	TextDrawSpriteMsg(true, 64, true)

	rts
}

// ------------------------------------------------------------
//
InitLayoutCommon:
{
	// Ensure layer system is initialized
	ldx #Layout1.id
	jsr Layout.SelectLayout

	Layer_SetRenderFunc(Layout1_BG0a.id, RenderLayout1BG0a)
	Layer_SetRenderFunc(Layout1_BG0b.id, RenderLayout1BG0b)
	Layer_SetRenderFunc(Layout1_BG1a.id, RenderLayout1BG1a)
	Layer_SetRenderFunc(Layout1_BG1b.id, RenderLayout1BG1b)
	Layer_SetRenderFunc(Layout1_Pixie.id, Layers.UpdateData.UpdatePixie)
	Layer_SetRenderFunc(Layout1_EOL.id, RenderNop)

	_set16(Layout.LayoutWidth, Tmp)
	
	ldx #Layout1_EOL.id
	lda Tmp+0
	jsr Layers.SetXPosLo
	lda Tmp+1
	jsr Layers.SetXPosHi

	rts
}

UpdateLayoutCommon:
{
	// Copy Camera.XScroll into Tmp
	_set16(Camera.XScroll, Tmp)
	_set16(Camera.YScroll, Tmp1)

	// Update scroll values for the next frame
	{
		ldx #Layout1_BG1a.id

		lda Tmp+0
		jsr Layers.SetXPosLo
		lda Tmp+1
		jsr Layers.SetXPosHi

		lda Tmp+0
		jsr Layers.SetFineScrollX

		lda Tmp1+0
		jsr Layers.SetYPosLo
		lda Tmp1+1
		jsr Layers.SetYPosHi

		lda Tmp1+0
		jsr Layers.SetFineScrollY		// this sets both layers

		ldx #Layout1_BG1b.id

		lda Tmp+0
		jsr Layers.SetXPosLo
		lda Tmp+1
		jsr Layers.SetXPosHi

		lda Tmp+0
		jsr Layers.SetFineScrollX

		lda Tmp1+0
		jsr Layers.SetYPosLo
		lda Tmp1+1
		jsr Layers.SetYPosHi

	}

	// divide Tmp and Tmp1 by 2
	_half16(Tmp)
	_half16(Tmp1)

	{
		// Update scroll values for the next frame
		ldx #Layout1_BG0a.id

		lda Tmp+0
		jsr Layers.SetXPosLo
		lda Tmp+1
		jsr Layers.SetXPosHi

		lda Tmp+0
		jsr Layers.SetFineScrollX

		lda Tmp1+0
		jsr Layers.SetYPosLo
		lda Tmp1+1
		jsr Layers.SetYPosHi

		lda Tmp1+0
		jsr Layers.SetFineScrollY		// this sets both layers

		ldx #Layout1_BG0b.id

		lda Tmp+0
		jsr Layers.SetXPosLo
		lda Tmp+1
		jsr Layers.SetXPosHi

		lda Tmp+0
		jsr Layers.SetFineScrollX

		lda Tmp1+0
		jsr Layers.SetYPosLo
		lda Tmp1+1
		jsr Layers.SetYPosHi
	}

	rts
}

// ------------------------------------------------------------
//
RenderLayout1BG0a: 
{
	// 
	ldx #Layout1_BG0a.id
	ldy #<BgMap1
	ldz #>BgMap1
	lda #$00
	jsr Layers.UpdateData.UpdateLayer

	rts	
}

// ------------------------------------------------------------
//
RenderLayout1BG0b: 
{
	// 
	ldx #Layout1_BG0b.id
	ldy #<BgMap1
	ldz #>BgMap1
	lda #$08							// layer b is offset by 8 pixels to read next row
	jsr Layers.UpdateData.UpdateLayer

	rts	
}

// ------------------------------------------------------------
//
RenderLayout1BG1a: 
{
	// 
	ldx #Layout1_BG1a.id
	ldy #<BgMap2
	ldz #>BgMap2
	lda #$00
	jsr Layers.UpdateData.UpdateLayer

	rts	
}

// ------------------------------------------------------------
//
RenderLayout1BG1b: 
{
	// 
	ldx #Layout1_BG1b.id
	ldy #<BgMap2
	ldz #>BgMap2
	lda #$08							// layer b is offset by 8 pixels to read next row
	jsr Layers.UpdateData.UpdateLayer

	rts	
}


// ---
.segment Data "GameState Titles"

introTxtTable:
	.word introTxt1, introTxt2, introTxt3, introTxt4

.encoding "screencode_mixed"
testTxt1:
	.text "game shell 65"
	.byte $ff
testTxt2:
	.text "[press fire to start]"
	.byte $ff
testTxt3:
	.text "00"
	.byte $ff

hexTable:
	.text "0123456789abcdef"

introTxt1:
	.text "welcome to gameshell65"
	.byte $ff
introTxt2:
	.text "code by retrocogs "
	.byte $1e
	.byte $ff
introTxt3:
	.text "iffl code by mirage "
	.byte $1f
	.byte $ff
introTxt4:
	.text "now go build your game "
	.byte $1f
	.byte $ff




