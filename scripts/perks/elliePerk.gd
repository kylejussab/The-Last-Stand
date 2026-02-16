extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(_thisCard, _thisHand, otherCard):
	if otherCard.role.contains("Stealthy") and otherCard.cardKey != "Nora":
		otherCard.modify_value(-1)

# Function used for forsaken honor check
func would_perk_trigger(_thisCard, _thisHand, otherCard) -> bool:
	if otherCard.role.contains("Stealthy") and otherCard.cardKey != "Nora":
		return true
	else:
		return false
