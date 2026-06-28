extends EndRoundPerk

func calculate_end_perk_value(_thisCharacterCard, thisSupportCard, _otherCharacterCard, _otherSupportCard, thisHand) -> int:
	var toAdd: int = 0
	
	for card in thisHand:
		if card.role.contains("Crafty") and card.type == "Character":
			toAdd += 1
			
	if thisSupportCard and thisSupportCard.role.contains("Survivor"):
		toAdd += 3
		
	return toAdd

func would_perk_trigger(_thisCharacterCard, thisSupportCard, _otherCharacterCard, _otherSupportCard, thisHand) -> bool:
	var hasCrafty = thisHand.any(func(card): return card.role.contains("Crafty") and card.type == "Character")
	var hasSurvivorSupport = thisSupportCard and thisSupportCard.role.contains("Survivor")
	return hasCrafty or hasSurvivorSupport
