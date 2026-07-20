extends Node
var timing: String = "onResolution"

func apply_on_resolution_perk(_thisCharacterCard, _thisSupportCard, _otherCharacterCard, _otherSupportCard, won: bool, _damage: int) -> Dictionary:
	if won:
		return {"drawExtraSupport": true, "log": 0}
	
	return {"log": 0}
