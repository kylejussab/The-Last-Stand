extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, _thisHand, otherCard) -> int:
	var toAdd = 0
	
	if otherCard.role.contains("Aggressive"):
		toAdd += 2
	
	if otherCard.type == "Character" && otherCard.faction == "Infected":
		toAdd += 1
	
	if toAdd != 0:
		thisCard.modify_value(toAdd)
	
	return toAdd

# Function used for forsaken honor check
func would_perk_trigger(_thisCard, _thisHand, otherCard) -> bool:
	var toAdd = 0
	
	if otherCard.role.contains("Aggressive"):
		toAdd += 2
	
	if otherCard.type == "Character" && otherCard.faction == "Infected":
		toAdd += 1
	
	if toAdd != 0:
		return true
	else:
		return false
