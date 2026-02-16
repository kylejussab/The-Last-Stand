extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, _otherCard):
	var fireflyTotal = 0
		
	for firefly in thisHand:
		if firefly.type == "Character" && firefly.faction == "Firefly":
			fireflyTotal += 1
			break
	
	if fireflyTotal > 0:
		thisCard.modify_value(3)
