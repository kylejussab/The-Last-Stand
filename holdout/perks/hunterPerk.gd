extends MidRoundPerk

func calculate_perk_value(_thisCard, thisHand, _otherCard) -> int:
	for smuggler in thisHand:
		if smuggler.type == "Character" && smuggler.faction == "Smuggler":
			return 0
	return 3
