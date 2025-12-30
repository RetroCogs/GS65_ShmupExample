// ------------------------------------------------------------
//
.enum { 
	ENM_BASIC, 		// good
	ENM_SPAWNER		// good 
	}

// ------------------------------------------------------------
//
// Status Flags
//
.const ENMST_ACTIVE			= $80
.const ENMST_PARENTALIVE	= $40

.const ENMST_STATEMASK		= $1f

.macro _clearEnmStatus()
{
	lda #$00
	sta Enemy.Status,y
}

.macro _setEnmFlag(value)
{
	lda Enemy.Status,y
	ora #value
	sta Enemy.Status,y
}

.macro _clearEnmFlag(value)
{
	lda Enemy.Status,y
	and #~value
	sta Enemy.Status,y
}

.macro _testEnmFlag(value)
{
	lda Enemy.Status,y
	and #value
}

.macro _setEnmStateFromA()
{
	sta stateVal

	lda Enemy.Status,y
	and #~ENMST_STATEMASK
	ora stateVal:#$00
	sta Enemy.Status,y
}

.macro _getEnmStateToA()
{
	lda Enemy.Status,y
	and #ENMST_STATEMASK
}

