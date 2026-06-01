extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, otherCard) -> int:
	var perkAmount: int = 0
	
	for ally in thisHand:
		if ally.cardKey == "Ellie" or ally.cardKey == "Tommy" or ally.cardKey == "TommyFirefly":
			perkAmount += 4
			break
			
	if otherCard.role.contains("/"):
		perkAmount += 2
			
	if perkAmount > 0:
		thisCard.modify_value(perkAmount)
	
	return perkAmount

func would_perk_trigger(_thisCard, thisHand, otherCard) -> bool:
	for ally in thisHand:
		if ally.cardKey == "Ellie" or ally.cardKey == "Tommy":
			return true
			
	if otherCard.role.contains("/"):
		return true
			
	return false
