extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, _thisHand, otherCard) -> int:
	if otherCard.faction == "Firefly":
		thisCard.modify_value(2)
		return 2
	
	return 0

# Function used for forsaken honor check
func would_perk_trigger(_thisCard, _thisHand, otherCard) -> bool:
	if otherCard.faction == "Firefly":
		return true
	else:
		return false
