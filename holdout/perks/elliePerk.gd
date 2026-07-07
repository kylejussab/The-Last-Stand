extends MidRoundPerk

func calculate_perk_value(thisCard, thisHand, otherCard) -> int:
	var toAdd = 0
	
	if otherCard != null:
		if otherCard.role.contains("Stealthy") and otherCard.cardKey != "Nora":
			toAdd += 2
			
	var ellieRoles = thisCard.role.split("/")
	
	for ally in thisHand:
		if ally.type == "Character":
			var isMatch: bool = false
			for role in ellieRoles:
				if ally.role.contains(role):
					isMatch = true
					break
			
			if not isMatch:
				toAdd += 1
				
	return toAdd

func apply_mid_perk(thisCard, thisHand, otherCard):
	var logEffects = []
	
	if otherCard.role.contains("Stealthy") and otherCard.cardKey != "Nora":
		otherCard.modify_value(-2)
		logEffects.append([-2, "opponent"])
	
	var perkAmount: int = 0
	var ellieRoles = thisCard.role.split("/")
	
	for ally in thisHand:
		if ally.type == "Character":
			var isMatch: bool = false
			for role in ellieRoles:
				if ally.role.contains(role):
					isMatch = true
					break
			
			if not isMatch:
				perkAmount += 1
			
	if perkAmount > 0:
		thisCard.modify_value(perkAmount)
		logEffects.append([perkAmount, "self"])
	
	if logEffects.is_empty():
		return 0
		
	return logEffects

func would_perk_trigger(thisCard, thisHand, otherCard) -> bool:
	return calculate_perk_value(thisCard, thisHand, otherCard) > 0
