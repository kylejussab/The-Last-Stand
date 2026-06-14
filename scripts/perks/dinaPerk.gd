extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, otherCard) -> int:
	var perkAmount: int = 0
	
	if otherCard.role.contains("Defensive"):
		perkAmount += 4
	
	for ally in thisHand:
		if ally.cardKey == "Ellie" or ally.cardKey == "Jessie":
			perkAmount += 2
			break
	
	if perkAmount != 0:
		thisCard.modify_value(perkAmount)
	
	return perkAmount

# Function used for forsaken honor check
func would_perk_trigger(_thisCard, thisHand, otherCard) -> bool:
	var hasAlly = thisHand.any(func(ally): return ally.cardKey in ["Ellie", "Jessie"])
	
	return otherCard.role.contains("Defensive") or hasAlly
