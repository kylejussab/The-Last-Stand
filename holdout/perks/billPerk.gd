extends EndRoundPerk

func calculate_end_perk_value(_thisCharacterCard, thisSupportCard, _otherCharacterCard, _otherSupportCard, _thisHand) -> int:
	if thisSupportCard != null:
		if thisSupportCard.parity == "Negative":
			return 4
			
	return 0
