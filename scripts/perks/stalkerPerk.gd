extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, _otherCard) -> int:
	var infectedTotal = 0
	
	for infected in thisHand:
		if infected.type == "Character" && infected.faction == "Infected":
			infectedTotal += 2
	
	if infectedTotal != 0:
		thisCard.modify_value(infectedTotal)
	
	return infectedTotal
