extends MidRoundPerk

func calculate_perk_value(_thisCard, thisHand, _otherCard) -> int:
	for ally in thisHand:
		if ally.cardKey == "Tommy" or ally.cardKey == "TommyFirefly" or ally.cardKey == "TommyFireflyHumanity":
			return 2
	
	return 0
