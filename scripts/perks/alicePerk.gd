extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, otherCard):
	var perkAmount: int = 0
	
	if otherCard.faction == "Infected":
		perkAmount += 3
		
	for ally in thisHand:
		if ally.faction == "WLF":
			perkAmount += 1
			
	if perkAmount > 0:
		thisCard.modify_value(perkAmount)

# Function used for forsaken honor check
func would_perk_trigger(_thisCard, thisHand, otherCard) -> bool:
	if otherCard.faction == "Infected":
		return true
	
	for ally in thisHand:
		if ally.faction == "WLF":
			return true
			
	return false
