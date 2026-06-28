extends MidRoundPerk

func calculate_perk_value(_thisCard, _thisHand, otherCard) -> int:
	if otherCard != null:
		if otherCard.faction == "Firefly" or otherCard.faction == "Seraphite":
			return 2
			
	return 0

func apply_mid_perk(_thisCard, _thisHand, otherCard):
	if otherCard.faction == "Firefly" or otherCard.faction == "Seraphite":
		otherCard.modify_value(-2)
		return [-2, "opponent"]
	
	return 0
