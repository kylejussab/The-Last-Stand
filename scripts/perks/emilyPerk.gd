extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, _otherCard):
	var seraphiteTotal = 0

	for seraphite in thisHand:
		if seraphite.type == "Character" && seraphite.faction == "Seraphite":
			seraphiteTotal += 1
	
	if seraphiteTotal != 0:
		thisCard.modify_value(seraphiteTotal)
