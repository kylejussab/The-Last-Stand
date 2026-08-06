extends MidRoundPerk

const COMPANION_KEYS = ["Ellie", "Jessie"]
const COMPANION_BONUS = 2

func calculate_perk_value(_thisCard, thisHand, otherCard) -> int:
	var toAdd = 0
	
	if otherCard != null:
		if otherCard.role.contains("Defensive"):
			toAdd += 4
			
	if not _get_matching_companions(thisHand).is_empty():
		toAdd += COMPANION_BONUS
		
	return toAdd

func get_companion_bonus(_thisCard, thisHand, _otherCard) -> Dictionary:
	return {"companions": _get_matching_companions(thisHand), "amount": COMPANION_BONUS}

func _get_matching_companions(thisHand: Array) -> Array:
	return thisHand.filter(func(c): 
		return is_instance_valid(c) and (c.cardKey in COMPANION_KEYS or c.cardKey == "JacksonScout")
)
