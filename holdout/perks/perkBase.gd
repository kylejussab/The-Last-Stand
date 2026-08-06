extends Resource
class_name PerkBase

var timing: String = "midRound"

func get_companion_bonus(_thisCard, _thisHand, _otherCard) -> Dictionary:
	return {"companions": [], "amount": 0}
