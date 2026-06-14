extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, otherCard) -> int:
	var perkAmount: int = 0
	
	if otherCard.type == "Character":
		if otherCard.role.contains("Aggressive") or otherCard.role.contains("Stealthy"):
			perkAmount += 2
	
	for ally in thisHand:
		if ally.role.contains("Stealthy") and ally.type == "Character":
			perkAmount += 1
			
	if perkAmount > 0:
		thisCard.modify_value(perkAmount)
	
	return perkAmount

# Function used for forsaken honor check
func would_perk_trigger(_thisCard, thisHand, otherCard) -> bool:
	if otherCard.type == "Character":
		if otherCard.role.contains("Aggressive") or otherCard.role.contains("Stealthy"):
			return true
	
	for ally in thisHand:
		if ally.role.contains("Stealthy") and ally.type == "Character":
			return true
			
	return false
