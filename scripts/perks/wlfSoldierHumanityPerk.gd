extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(_thisCard, _thisHand, otherCard):
	if otherCard.faction == "Firefly" or otherCard.faction == "Seraphite":
		otherCard.modify_value(-2)
		return [-2, "opponent"]
	
	return 0

# Function used for forsaken honor check
func would_perk_trigger(_thisCard, _thisHand, otherCard) -> bool:
	if otherCard.faction == "Firefly" or otherCard.faction == "Seraphite":
		return true
	else:
		return false
