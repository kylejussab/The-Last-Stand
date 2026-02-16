extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, otherCard):
	var toAdd = 0
	
	for infected in thisHand:
		if infected.type == "Character" && infected.faction == "Infected":
			toAdd += 1
	
	if otherCard.faction == "Infected":
		toAdd += 2
	
	if toAdd != 0:
		thisCard.modify_value(toAdd)
