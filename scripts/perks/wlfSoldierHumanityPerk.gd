extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(_thisCard, _thisHand, otherCard):
	if otherCard.faction == "Firefly" or otherCard.faction == "Seraphite":
		otherCard.modify_value(-2)
