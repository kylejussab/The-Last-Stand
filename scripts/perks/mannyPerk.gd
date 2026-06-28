extends MidRoundPerk

func calculate_perk_value(thisCard, _thisHand, otherCard) -> int:
	if otherCard != null:
		if otherCard.role.contains("Aggressive") or otherCard.role.contains("Defensive"):
			var difference = otherCard.value - thisCard.value
			return difference + 2
			
	return 0

func would_perk_trigger(_thisCard, _thisHand, otherCard) -> bool:
	if otherCard.role.contains("Aggressive") or otherCard.role.contains("Defensive"):
		return true
	else:
		return false
