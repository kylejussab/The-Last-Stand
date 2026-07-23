extends MidRoundPerk

func calculate_perk_value(_thisCard, thisHand, _otherCard) -> int:
	var toAdd = 0
	
	for runner in thisHand:
		if runner.cardKey == "Runner":
			toAdd += runner.value
			
	return toAdd
