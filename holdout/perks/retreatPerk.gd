extends Node
var timing: String = "onResolution"

func apply_on_resolution_perk(_thisCharacterCard, _thisSupportCard, _otherCharacterCard, _otherSupportCard, _won: bool, _damage: int) -> Dictionary:
	return {"negateDamage": true, "log": 0}
