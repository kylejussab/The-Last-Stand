extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, otherCard):
	if otherCard.role.contains("Stealthy") and otherCard.cardKey != "Nora":
		otherCard.modify_value(-2)
	
	var perkAmount: int = 0
	var ellieRoles = thisCard.role.split("/")
	
	for ally in thisHand:
		if ally.type == "Character":
			var isMatch: bool = false
			for role in ellieRoles:
				if ally.role.contains(role):
					isMatch = true
					break
			
			if not isMatch:
				perkAmount += 1
			
	if perkAmount > 0:
		thisCard.modify_value(perkAmount)

# Function used for forsaken honor check
func would_perk_trigger(thisCard, thisHand, otherCard) -> bool:
	if otherCard.role.contains("Stealthy") and otherCard.cardKey != "Nora":
		return true
	
	var ellieRoles = thisCard.role.split("/")
	for ally in thisHand:
		if ally.type == "Character":
			var isMatch: bool = false
			for role in ellieRoles:
				if ally.role.contains(role):
					isMatch = true
					break
			if not isMatch:
				return true
			
	return false
