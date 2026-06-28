extends EndRoundPerk

func calculate_end_perk_value(_thisCharacterCard, thisSupportCard, _otherCharacterCard, _otherSupportCard, _thisHand) -> int:
	if thisSupportCard and (thisSupportCard.cardKey == "Brick" or thisSupportCard.cardKey == "Bottle"):
		return 4
			
	return 0
