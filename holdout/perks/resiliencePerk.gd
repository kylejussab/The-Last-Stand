extends Node
var timing: String = "onResolution"

func apply_on_resolution_perk(_thisCharacterCard, _thisSupportCard, _otherCharacterCard, _otherSupportCard, won: bool, damage: int) -> Dictionary:
	if won:
		return {"log": 0}
	
	@warning_ignore("integer_division")
	var reduced = damage / 2
	return {"modifiedDamage": reduced, "log": [[-(damage - reduced), "self"]]}
