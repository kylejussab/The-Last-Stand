extends EndRoundPerk
func calculate_end_perk_value(_thisCharacterCard, thisSupportCard, _otherCharacterCard, _otherSupportCard, thisHand) -> int:
	if forceTrigger:
		return 6
	var toAdd: int = 0
	for card in thisHand:
		if card.role.contains("Crafty") and card.type == "Character":
			toAdd += 1
	if thisSupportCard:
		toAdd += 3
	return toAdd
