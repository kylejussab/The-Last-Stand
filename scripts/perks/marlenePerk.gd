extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, _thisHand, otherCard) -> int:
	if otherCard.role.contains("Survivor") or otherCard.role.contains("Stealthy"):
		thisCard.modify_value(1)
		return 1
	
	return 0

# Function used for forsaken honor check
func would_perk_trigger(_thisCard, _thisHand, otherCard) -> bool:
	if otherCard.role.contains("Survivor") or otherCard.role.contains("Stealthy"):
		return true
	else:
		return false
