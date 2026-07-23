extends Node
var timing: String = "onPlay"

func apply_on_play_perk(thisCharacterCard, thisSupportCard, _otherCharacterCard, _otherSupportCard, _thisHand, _forceNoBackfire: bool = false) -> Dictionary:
	if thisCharacterCard.role.contains("Crafty") or thisCharacterCard.role.contains("Defensive"):
		thisSupportCard.modify_value(2)
		return {"handled": false, "log": [[2, "self"]]}
	
	return {"handled": false, "log": 0}
