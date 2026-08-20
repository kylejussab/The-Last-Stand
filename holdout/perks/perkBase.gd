extends Resource
class_name PerkBase

var timing: String = "midRound"
var forceTrigger: bool = false

func get_companion_bonus(_thisCard, _thisHand, _otherCard) -> Dictionary:
	return {"companions": [], "amount": 0}
