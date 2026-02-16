extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, _thisHand, otherCard):
	if otherCard.role.contains("Aggressive") or otherCard.role.contains("Stealthy"):
		thisCard.modify_value(2)
