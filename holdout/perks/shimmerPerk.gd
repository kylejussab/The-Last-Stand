extends MidRoundPerk

const COMPANION_KEYS = ["Ellie", "Dina"]
const COMPANION_BONUS = 3

func calculate_perk_value(_thisCard, thisHand, _otherCard) -> int:
	var toAdd = 0
	
	if not _get_matching_companions(thisHand).is_empty():
		toAdd += COMPANION_BONUS
		
	return toAdd

func get_companion_bonus(_thisCard, thisHand, _otherCard) -> Dictionary:
	return {"companions": _get_matching_companions(thisHand), "amount": COMPANION_BONUS}

func _get_matching_companions(thisHand: Array) -> Array:
	return thisHand.filter(func(c): 
		return is_instance_valid(c) and (c.cardKey in COMPANION_KEYS or c.cardKey == "JacksonScout")
)
