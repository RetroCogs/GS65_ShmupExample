// ------------------------------------------------------------
// This file should be included in a namespace of an object
// that wants to be used as an object list
//

.macro _initlist(_objIndxList, _splitPos, _indexPtr, _max_num, _size) {
	lda #<_objIndxList
	sta _indexPtr+0
	lda #>_objIndxList
	sta _indexPtr+1

	lda #_max_num
	sta _size

	ldy #$00
!:
	tya
	sta (_indexPtr),y
	iny
	cpy _size
	bne !-

	sty _splitPos
}

// ------------------------------------------------------------
// Allocate an object from the free list
//
// returns:	Y = new object ID
//			N = clear if couldn't allocate
//
.macro _alloc(_splitPos, _indexPtr) {
	phz

	// Get the current split position, if it's 0 then we can't allocate
	//
	ldz _splitPos
	stz compare
	beq done

	// move the free pointer back one and grab the next free item
	//
	dez
	lda (_indexPtr),z
	stz _splitPos

	tay

done:
	plz

	// Return N flag clear if we couldn't allocate
	lda _splitPos
	cmp compare:#$00
}

// Free an object and put it back on the free list
//
// params:	Y = object ID to free
//
.macro _free(_splitPos, _indexPtr) {
	phy
	phz

	tya
	taz

	ldy _splitPos

	// We need to swap the indexes at X & Y
	lda (_indexPtr),z
	pha

	lda (_indexPtr),y
	sta (_indexPtr),z

	pla
	sta (_indexPtr),y

	inc _splitPos

	plz
	ply
}

