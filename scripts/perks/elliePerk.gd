extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(_thisCard, _thisHand, otherCard):
	if otherCard.role.contains("Stealthy") and otherCard.cardKey != "Nora":
		otherCard.modify_value(-1)
