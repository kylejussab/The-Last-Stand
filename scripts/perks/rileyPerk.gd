extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, _otherCard):
	var hasEllie: bool = false
	var hasStealthy: bool = false
	
	for ally in thisHand:
		if ally.cardKey == "Ellie":
			hasEllie = true
		if ally.role.contains("Stealthy") and ally.type == "Character":
			hasStealthy = true
			
	if hasEllie:
		thisCard.modify_value(3)
	elif not hasStealthy:
		thisCard.modify_value(2)

func would_perk_trigger(_thisCard, thisHand, _otherCard) -> bool:
	var hasEllie: bool = false
	var hasStealthy: bool = false
	
	for ally in thisHand:
		if ally.cardKey == "Ellie":
			hasEllie = true
		if ally.role.contains("Stealthy") and ally.type == "Character":
			hasStealthy = true
	
	return hasEllie or not hasStealthy
