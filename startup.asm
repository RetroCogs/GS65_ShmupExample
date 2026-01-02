// Only Segments Code and Data are included in the .prg, BSS and ZP are virtual
// and must be proerly initialized.
//
.file [name="startup.prg", type="bin", segments="Code,Data"]
.cpu _45gs02				

#define USE_DBG				// enable to see raster costs

#define PLAYER_CANDIE

// ------------------------------------------------------------
// Memory layout
//
.const COLOR_OFFSET 		= $0800				// Offset ColorRam to make bank $10000 contiguous
.const COLOR_RAM 			= $ff80000 + COLOR_OFFSET

.const GRAPHICS_RAM 		= $10000			// all bg chars / pixie data goes here
.const PIXIEANDSCREEN_RAM 	= $50000			// screen ram / pixie work ram goes here
												// must be on a $100 alignment due to RRB pixie MAP behavior

// --------------
.segmentdef Zeropage [start=$02, min=$02, max=$fb, virtual]
.segmentdef Code [start=$2000, max=$cfff]
.segmentdef Data [startAfter="Code", max=$cfff]

.segmentdef MappedPixieWorkRam [start=$8000, max=$bfff, virtual]

.segmentdef BSS [start=$e000, max=$f400, virtual]

// --------------
.segmentdef GraphicsRam [start=GRAPHICS_RAM, max=PIXIEANDSCREEN_RAM-1, virtual]

// --------------
// Ensure PixieWorkRam is on a $100 alignemt due to RRB pixie MAP behavior
//
.segmentdef PixieWorkRam [start=PIXIEANDSCREEN_RAM, max=PIXIEANDSCREEN_RAM+$ffff, virtual]
.segmentdef ScreenRam [startAfter="PixieWorkRam", max=PIXIEANDSCREEN_RAM+$ffff, virtual]
.segmentdef MapRam [startAfter="ScreenRam", max=PIXIEANDSCREEN_RAM+$ffff, virtual]

// ------------------------------------------------------------
// Defines to describe the screen size
//
.const SCREEN_WIDTH = 256
.const SCREEN_HEIGHT = 216

.function FP(x) { .return (x * (1<<8)) }

// ------------------------------------------------------------
//
#import "m65macros.s"

#import "layers_Functions.s"
#import "layout_Functions.s"
#import "assets_Functions.s"

// ------------------------------------------------------------
// Layer constants
//

// Maximum number of Pixie words use per row, 1 pixie is 2+ words (GOTOX + CHAR + [optional CHAR])
//
.const NUM_PIXIEWORDS = 96					// Must be < 128 (to keep indexing within range)

// ------------------------------------------------------------
// Layer layout for credits screen example
//
// Dual vertically and horizontally parallaxing layers with pixies,
// note that vertical parallax needs 2 layers per graphics layer!!!
//
// 1) BG0 layer for background
// 1) BG0 layer for background
// 1) BG1 layer for midground
// 1) BG1 layer for midground
//
// 2) Pixie layer for you know, pixies
//
// 3) Always end with EOL layer
//
.const Layout1 = NewLayout("credits", SCREEN_WIDTH, SCREEN_HEIGHT, (SCREEN_HEIGHT / 8))
.const Layout1_BG0a = Layer_BG("bg_level0a", (SCREEN_WIDTH/16) + 1, true, 1)
.const Layout1_BG0b = Layer_BG("bg_level0b", (SCREEN_WIDTH/16) + 1, true, 1)
.const Layout1_BG1a = Layer_BG("bg_level1a", (SCREEN_WIDTH/16) + 1, true, 1)
.const Layout1_BG1b = Layer_BG("bg_level1b", (SCREEN_WIDTH/16) + 1, true, 1)
.const Layout1_Pixie = Layer_PIXIE("pixie", NUM_PIXIEWORDS, 1)
.const Layout1_EOL = Layer_EOL("eol")
.const Layout1end = EndLayout(Layout1)

// ------------------------------------------------------------
// Static BG Map sizes, in this example we are expanding the tile / map
// set into a static buffer, for a real game you'd want to be more fancy
//
.const BG0ROWSIZE = (256 / 16) * 2
.const BG0NUMROWS = (1024 / 8)

.const BG1ROWSIZE = (256 / 16) * 2
.const BG1NUMROWS = (1024 / 8)

.const MAXXBOUNDS = 512 - SCREEN_WIDTH
.const MAXYBOUNDS = 512 - SCREEN_HEIGHT

// ------------------------------------------------------------
// Number of NCM palettes that we are using
//
.enum {
	PAL_FONTHUD,
	PAL_BG0,
	PAL_BG1,

	PAL_BULLETS,

	PAL_PLAYER,

	PAL_ENM00,

	PAL_FLASH,

	NUM_PALETTES
}

// ------------------------------------------------------------
//
.segment Zeropage "Main zeropage"

Tmp:			.word $0000,$0000		// General reusable data (Don't use in IRQ)
Tmp1:			.word $0000,$0000
Tmp2:			.word $0000,$0000
Tmp3:			.word $0000,$0000
Tmp4:			.word $0000,$0000
Tmp5:			.word $0000,$0000
Tmp6:			.word $0000,$0000
Tmp7:			.word $0000,$0000

SpawnPattern:	.byte $00
SpawnPosX:		.word $0000
SpawnPosY:		.word $0000
SpawnData:		.byte $00, $00, $00, $00

// ------------------------------------------------------------
//
.segment BSS "Main"

RequestGameState:	.byte $00
GameState:			.byte $00				// Titles / Play / HiScore etc
GameSubState:		.byte $00
GameStateTimer:		.byte $00
GameStateData:		.byte $00,$00,$00

SaveState:			.dword 0
SaveStateEnd:

//--------------------------------------------------------
// Main
//--------------------------------------------------------
.segment Code

* = $2000
	jmp Entry

.print "--------"

.const bgCharsBegin = StartSection("GraphicsRan", GRAPHICS_RAM, PIXIEANDSCREEN_RAM-GRAPHICS_RAM)
.const bg0Chars = AddAsset("F", "sdcard/bg20_chr.bin")
.const bg1Chars = AddAsset("F", "sdcard/bg21_chr.bin")
.const sprFont = AddAsset("F", "sdcard/font_chr.bin")
.const bulletsChars = AddAsset("F", "sdcard/plbull_chr.bin")
.const playerChars = AddAsset("F", "sdcard/player_chr.bin")
.const enemy00Chars = AddAsset("F", "sdcard/enemy00_chr.bin")
.const bgCharsEnd = EndSection()

.print "--------"

.const blobsBegin = StartSection("iffl", $00000, $40000)
.const iffl0 = AddAsset("FS-IFFL0", "sdcard/data.bin.addr.mc")
.const blobsEnd = EndSection()

.print "--------"

#import "layers_code.s"
#import "layout_code.s"
#import "assets_code.s"
#import "system_code.s"
#import "fastLoader.s"
#import "decruncher.s"
#import "keyb_code.s"
#import "pixie_code.s"

// ------------------------------------------------------------
//
.enum {GStateTitles, GStatePlay, GStateCredits}
.var GSIniStateList = List().add(gsIniTitles, gsIniPlay, gsIniCredits)
.var GSUpdStateList = List().add(gsUpdTitles, gsUpdPlay, gsUpdCredits)
.var GSDrwStateList = List().add(gsDrwTitles, gsDrwPlay, gsDrwCredits)

// ------------------------------------------------------------
//
.segment Code "Entry"
Entry: 
{
	jsr System.Initialization1

	// Init the raster IRQ
	//
 	sei

	disableCIAInterrupts()

    lda $dc0d
    lda $dd0d

    lda #<Irq.irqBotHandler
    sta $fffe
    lda #>Irq.irqBotHandler
    sta $ffff

    lda #$01
    sta $d01a

	jsr Irq.SetIRQBotPos

    cli

	// Wait for IRQ before disabling the screen
	WaitVblank()

	jsr System.DisableScreen

	lda #$00
	sta $d020

	// initialise fast load (start drive motor)
	jsr fl_init

	LoadFile(bg0Chars.addr + iffl0.crunchAddress, iffl0.filenamePtr)
	DecrunchFile(bg0Chars.addr + iffl0.crunchAddress, bg0Chars.addr)

	// done loading. stop drive motor
	jsr fl_exit
	
	// Update screen positioning if PAL/NTSC has changed
	jsr System.CenterFrameHorizontally
	jsr System.CenterFrameVertically

 	sei

	jsr System.Initialization2

	VIC4_SetScreenLocation(ScreenRam)

	// Initialize palette and bgmap data
	jsr InitPalette
	jsr InitBGMap

	// Setup the initial game state
	lda #GStateTitles
	sta RequestGameState
	jsr SwitchGameStates

    // set the interrupt to line bottom position
    jsr Irq.SetIRQBotPos

	cli

	// initialize dpad data	
	jsr System.InitDPad
		
mainloop:
	WaitVblank()

	DbgBord(4)

	// !!!! - Update Buffers that will be seen next frame - !!!!
	//
	// Update the layer buffers for the coming frame, this DMAs the BG layer and
	// ALL pixie data and sets the X and Y scroll values
	//
	jsr Layout.ConfigureHW

	jsr Layout.UpdateBuffers

	// If the frame is disabled, enable it, this ensure first frame of garbage isn't seen
	lda #FlEnableScreen
	bit System.Flags
	bne skipEnable

	jsr System.EnableScreen

skipEnable:

	// Determine if we want to switch states, this is done here so that any
	// new layout requests are properly setup.
	//
	lda RequestGameState
	cmp GameState
	beq !+

	jsr SwitchGameStates

!:

	DbgBord(0)

	// !!!! - Prepare all data for next frame - !!!!
	//
	// From this point on we update and draw the coming frame, this gives us a whole
	// frame to get all of the logic and drawing done.
	//

	// Clear the work Pixie ram using DMA
	jsr ClearWorkPixies

	// Scan the keyboard and joystick 2
	jsr System.UpdateDPad

	// Run the update
	lda GameState
	asl
	tax
	jsr (GSUpdStateTable,x)

	DbgBord(7)

	// Run the draw, this will add all of the pixies for the next frame
	lda GameState
	asl
	tax
	jsr (GSDrwStateTable,x)

	DbgBord(0)

	jmp mainloop
}

// ------------------------------------------------------------
//
SwitchGameStates: 
{
	sta GameState
	asl
	tax
	jsr (GSIniStateTable,x)
	rts
}

// ------------------------------------------------------------
//
RenderNop: 
{
	rts
}

// ------------------------------------------------------------
//
InitPalette: 
{
	.var palPtr = Tmp1			// 16 bit

	//Bit pairs = CurrPalette, TextPalette, SpritePalette, AltPalette
	lda #%00000000 //Edit=%00, Text = %00, Sprite = %01, Alt = %00
	sta $d070 

	_set16im(Palette, palPtr)

	ldx #$00								// HW pal index

	ldz #$00								// pal index

incPalLoop:
	phz

	ldz #$00
colLoop:
	lda (palPtr),z							// get palette value
	sta $d100,x								// store into HW palette
	inz

	lda (palPtr),z							// get palette value
	sta $d200,x								// store into HW palette
	inz

	lda (palPtr),z							// get palette value
	sta $d300,x								// store into HW palette
	inz

	inx

	cpz #$30
	bne colLoop

	_add16im(palPtr, $30, palPtr)

	plz
	inz
	cpz #16
	bne incPalLoop

	lda #$00
	sta $d100
	sta $d200
	sta $d300

	rts
}

// ------------------------------------------------------------
//
#import "EnemyMacros.s"

#import "irq.s"
#import "camera.s"
#import "pixieText.s"
#import "gsTitles.s"
#import "gsPlay.s"
#import "gsCredits.s"
#import "bgmap.s"

#import "objList_Inline.s"

#import "Math.s"

#import "Player.s"
#import "Bullets.s"
#import "Enemy.s"
#import "EnmProjectiles.s"

.segment Data "GameState Tables"
GSIniStateTable:
	.fillword GSIniStateList.size(), GSIniStateList.get(i)
GSUpdStateTable:
	.fillword GSUpdStateList.size(), GSUpdStateList.get(i)
GSDrwStateTable:
	.fillword GSDrwStateList.size(), GSDrwStateList.get(i)

// ------------------------------------------------------------
//
.segment Data "Palettes"
Palette:
	.import binary "./sdcard/font_pal.bin"
	.import binary "./sdcard/bg20_pal.bin"
	.import binary "./sdcard/bg21_pal.bin"
	.import binary "./sdcard/plbull_pal.bin"
	.import binary "./sdcard/player_pal.bin"
	.import binary "./sdcard/enemy00_pal.bin"
	.fill 48,$ff

// ------------------------------------------------------------
.segment GraphicsRam "Graphics RAM"
GraphicsData:
	.fill (bgCharsBegin.currAddr - bgCharsBegin.baseAddr),0

// ------------------------------------------------------------
// Ensure these tables DONOT straddle a bank address
//
.segment MappedPixieWorkRam "Mapped Pixie Work RAM"
MappedPixieWorkTiles:
	.fill (Layout1_Pixie.DataSize * MAX_NUM_ROWS), $00
MappedPixieWorkAttrib:
	.fill (Layout1_Pixie.DataSize * MAX_NUM_ROWS), $00

.segment PixieWorkRam "Pixie Work RAM"
PixieWorkTiles:
	.fill (Layout1_Pixie.DataSize * MAX_NUM_ROWS), $00
PixieWorkAttrib:
	.fill (Layout1_Pixie.DataSize * MAX_NUM_ROWS), $00

.segment ScreenRam "Screen RAM"
ScreenRam:
	.fill (MAX_SCREEN_SIZE), $00

