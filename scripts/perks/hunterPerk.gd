extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, _otherCard) -> int:
	var smugglerTotal = 0
	
	for smuggler in thisHand:
		if smuggler.type == "Character" && smuggler.faction == "Smuggler":
			smugglerTotal += 1
	
	if smugglerTotal == 0:
		thisCard.modify_value(3)
		return 3
	
	return 0
