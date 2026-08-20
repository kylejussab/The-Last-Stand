extends EndRoundPerk
func calculate_end_perk_value(_thisCharacterCard, thisSupportCard, _otherCharacterCard, _otherSupportCard, _thisHand) -> int:
	if forceTrigger:
		return 3
	if thisSupportCard != null:
		if thisSupportCard.parity == "Negative":
			return 3
	return 0
