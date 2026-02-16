extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(_thisCard, _thisHand, otherCard):
	if otherCard.role.contains("Survivor"):
		otherCard.modify_value(-3)
