extends EndRoundPerk

func calculate_end_perk_value(_thisCharacterCard, thisSupportCard, _otherCharacterCard, _otherSupportCard, thisHand) -> int:
	var toAdd: int = 0
	
	for card in thisHand:
		if card.role.contains("Crafty") and card.type == "Character":
			toAdd += 1
			
	if thisSupportCard:
		toAdd += 3
		
	return toAdd

func would_perk_trigger(_thisCharacterCard, thisSupportCard, _otherCharacterCard, _otherSupportCard, thisHand) -> bool:
	var hasCrafty = thisHand.any(func(card): return card.role.contains("Crafty") and card.type == "Character")
	var hasSupport = true if thisSupportCard else false
	return hasCrafty or hasSupport
