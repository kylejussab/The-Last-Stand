extends EndRoundPerk

func calculate_end_perk_value(_thisCharacterCard, thisSupportCard, _otherCharacterCard, _otherSupportCard, _thisHand) -> int:
	if thisSupportCard != null:
		if thisSupportCard && thisSupportCard.cardKey == "SupplyCache":
			return 2
			
	return 0

func apply_end_perk(_thisCharacterCard, thisSupportCard, _otherCharacterCard, _otherSupportCard, thisHand) -> int:
	if thisSupportCard != null and thisSupportCard.cardKey == "SupplyCache":
		var randomCard = thisHand.pick_random()
		randomCard.modify_value(2)
		return 2
		
	return 0
