// Calculate the angle, in a 256-degree circle, between two points.
// The trick is to use logarithmic division to get the y/x ratio and
// integrate the power function into the atan table. Some branching is
// avoided by using a table to adjust for the octants.
// In otherwords nothing new or particularily clever but nevertheless
// quite useful.
//
// by Johan Forslöf (doynax)
//
.segment Zeropage "Math"
x1:			.byte $00
y1:			.byte $00
x2:			.byte $00
y2:			.byte $00
dx:			.byte $00
dy:			.byte $00
octant:		.byte $00
angle:		.byte $00

resultX:    .byte $00,$00
resultY:    .byte $00,$00,$00

.segment Code "Math"

GetRandom: 
{
	phx
	inc RngIndx
	ldx RngIndx
	lda rngtable,x
	plx
	rts
}

// -------------------------------------------------------
// X    = Angle
// A,Z  = 8.8 Length
//
calcVector:
{
    // Store Length and support -ve numbers
    //
    sta $d774+0

    lda #$00
    sta $d774+2
    sta $d774+3

    tza
	cmp #$80
	bcc !+
	dec $d774+2
	dec $d774+3
!:
    sta $d774+1

	// Store X cos in 8.sss
    //
	lda #$00
	sta $d770+1
	sta $d770+2
	sta $d770+3
	lda costable31,x
	cmp #$80
	bcc !+
	dec $d770+1
	dec $d770+2
	dec $d770+3
!:
	sta $d770+0

    // Result in $d778+1,2
    //
    _set16($d778+1, resultX)

	// Store Y cos in 8.sss
    //
	lda #$00
	sta $d770+1
	sta $d770+2
	sta $d770+3
	lda sintable127,x
	cmp #$80
	bcc !+
	dec $d770+1
	dec $d770+2
	dec $d770+3
!:
	sta $d770+0

    // Result in $d778+1,2
    //
    _set24($d778+1, resultY)

    rts
}

atan2:
{
    phx
    phy

    lda dx
    cmp #$80
    bcc !+
    eor #$ff
!:	tax
    rol octant

    lda dy
    cmp #$80
    bcc !+
    eor #$ff
!:	tay
    rol octant

    lda log2_tab,x
    sbc log2_tab,y
    bcc !+
    eor #$ff
!:	tax

    lda octant
    rol
    and #%111
    tay

    lda atan_tab,x
    eor octant_adjust,y
    sta.zp angle

    ply
    plx
    rts
}

.segment Data "Math"
octant_adjust:	
		.byte %00111111		// x+,y+,|x|>|y|
		.byte %00000000		// x+,y+,|x|<|y|
		.byte %11000000		// x+,y-,|x|>|y|
		.byte %11111111		// x+,y-,|x|<|y|
		.byte %01000000		// x-,y+,|x|>|y|
		.byte %01111111		// x-,y+,|x|<|y|
		.byte %10111111		// x-,y-,|x|>|y|
		.byte %10000000		// x-,y-,|x|<|y|

//		;;;;;;;; atan(2^(x/32))*128/pi ;;;;;;;;
atan_tab:	
		.byte $00,$00,$00,$00,$00,$00,$00,$00
		.byte $00,$00,$00,$00,$00,$00,$00,$00
		.byte $00,$00,$00,$00,$00,$00,$00,$00
		.byte $00,$00,$00,$00,$00,$00,$00,$00
		.byte $00,$00,$00,$00,$00,$00,$00,$00
		.byte $00,$00,$00,$00,$00,$00,$00,$00
		.byte $00,$00,$00,$00,$00,$00,$00,$00
		.byte $00,$00,$00,$00,$00,$00,$00,$00
		.byte $00,$00,$00,$00,$00,$00,$00,$00
		.byte $00,$00,$00,$00,$00,$00,$00,$00
		.byte $00,$00,$00,$00,$00,$01,$01,$01
		.byte $01,$01,$01,$01,$01,$01,$01,$01
		.byte $01,$01,$01,$01,$01,$01,$01,$01
		.byte $01,$01,$01,$01,$01,$01,$01,$01
		.byte $01,$01,$01,$01,$01,$02,$02,$02
		.byte $02,$02,$02,$02,$02,$02,$02,$02
		.byte $02,$02,$02,$02,$02,$02,$02,$02
		.byte $03,$03,$03,$03,$03,$03,$03,$03
		.byte $03,$03,$03,$03,$03,$04,$04,$04
		.byte $04,$04,$04,$04,$04,$04,$04,$04
		.byte $05,$05,$05,$05,$05,$05,$05,$05
		.byte $06,$06,$06,$06,$06,$06,$06,$06
		.byte $07,$07,$07,$07,$07,$07,$08,$08
		.byte $08,$08,$08,$08,$09,$09,$09,$09
		.byte $09,$0a,$0a,$0a,$0a,$0b,$0b,$0b
		.byte $0b,$0c,$0c,$0c,$0c,$0d,$0d,$0d
		.byte $0d,$0e,$0e,$0e,$0e,$0f,$0f,$0f
		.byte $10,$10,$10,$11,$11,$11,$12,$12
		.byte $12,$13,$13,$13,$14,$14,$15,$15
		.byte $15,$16,$16,$17,$17,$17,$18,$18
		.byte $19,$19,$19,$1a,$1a,$1b,$1b,$1c
		.byte $1c,$1c,$1d,$1d,$1e,$1e,$1f,$1f


//		;;;;;;;; log2(x)*32 ;;;;;;;;
log2_tab:
		.byte $00,$00,$20,$32,$40,$4a,$52,$59
		.byte $60,$65,$6a,$6e,$72,$76,$79,$7d
		.byte $80,$82,$85,$87,$8a,$8c,$8e,$90
		.byte $92,$94,$96,$98,$99,$9b,$9d,$9e
		.byte $a0,$a1,$a2,$a4,$a5,$a6,$a7,$a9
		.byte $aa,$ab,$ac,$ad,$ae,$af,$b0,$b1
		.byte $b2,$b3,$b4,$b5,$b6,$b7,$b8,$b9
		.byte $b9,$ba,$bb,$bc,$bd,$bd,$be,$bf
		.byte $c0,$c0,$c1,$c2,$c2,$c3,$c4,$c4
		.byte $c5,$c6,$c6,$c7,$c7,$c8,$c9,$c9
		.byte $ca,$ca,$cb,$cc,$cc,$cd,$cd,$ce
		.byte $ce,$cf,$cf,$d0,$d0,$d1,$d1,$d2
		.byte $d2,$d3,$d3,$d4,$d4,$d5,$d5,$d5
		.byte $d6,$d6,$d7,$d7,$d8,$d8,$d9,$d9
		.byte $d9,$da,$da,$db,$db,$db,$dc,$dc
		.byte $dd,$dd,$dd,$de,$de,$de,$df,$df
		.byte $df,$e0,$e0,$e1,$e1,$e1,$e2,$e2
		.byte $e2,$e3,$e3,$e3,$e4,$e4,$e4,$e5
		.byte $e5,$e5,$e6,$e6,$e6,$e7,$e7,$e7
		.byte $e7,$e8,$e8,$e8,$e9,$e9,$e9,$ea
		.byte $ea,$ea,$ea,$eb,$eb,$eb,$ec,$ec
		.byte $ec,$ec,$ed,$ed,$ed,$ed,$ee,$ee
		.byte $ee,$ee,$ef,$ef,$ef,$ef,$f0,$f0
		.byte $f0,$f1,$f1,$f1,$f1,$f1,$f2,$f2
		.byte $f2,$f2,$f3,$f3,$f3,$f3,$f4,$f4
		.byte $f4,$f4,$f5,$f5,$f5,$f5,$f5,$f6
		.byte $f6,$f6,$f6,$f7,$f7,$f7,$f7,$f7
		.byte $f8,$f8,$f8,$f8,$f9,$f9,$f9,$f9
		.byte $f9,$fa,$fa,$fa,$fa,$fa,$fb,$fb
		.byte $fb,$fb,$fb,$fc,$fc,$fc,$fc,$fc
		.byte $fd,$fd,$fd,$fd,$fd,$fd,$fe,$fe
		.byte $fe,$fe,$fe,$ff,$ff,$ff,$ff,$ff

sintable:
	.fill 256, (80 + (sin((i/256) * PI * 2) * 68)) + 16
costable:
	.fill 256, (80 + (cos((i/256) * PI * 2) * 48)) + 16

RngIndx:
	.byte $00

rngtable:
	.fill 256, ((random() * 2.0) - 1.0) * 127

sintable127:
	.fill 256, (sin((i/256) * PI * 2) * 127)

costable31:
	.fill 256, (cos((i/256) * PI * 2) * 15)
