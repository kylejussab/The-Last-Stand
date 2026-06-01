extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, _otherCard) -> int:
	var foundAggressiveCharacter: bool = false
	
	for ally in thisHand:
		if ally.type == "Character":
			if ally.role.contains("Aggressive"):
				foundAggressiveCharacter = true
				break
			
	if not foundAggressiveCharacter:
		thisCard.modify_value(3)
		return 3
	
	return 0

func would_perk_trigger(_thisCard, thisHand, _otherCard) -> bool:
	for ally in thisHand:
		if ally.type == "Character" and ally.role.contains("Aggressive"):
			return false 
			
	return true
