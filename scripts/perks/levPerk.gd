extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, _otherCard):
	var hasAlly: bool = false
	var hasSeraphite: bool = false
	
	for ally in thisHand:
		if ally.cardKey == "Yara" or ally.cardKey == "Abby":
			hasAlly = true
		if ally.faction == "Seraphite":
			hasSeraphite = true
			
	var perkAmount: int = 0
	
	if hasAlly:
		perkAmount += 5
	
	if not hasSeraphite:
		perkAmount += 3
			
	if perkAmount > 0:
		thisCard.modify_value(perkAmount)

func would_perk_trigger(_thisCard, thisHand, _otherCard) -> bool:
	var hasAlly: bool = false
	var hasSeraphite: bool = false
	
	for ally in thisHand:
		if ally.cardKey == "Yara" or ally.cardKey == "Abby":
			hasAlly = true
		if ally.faction == "Seraphite":
			hasSeraphite = true
			
	return hasAlly or not hasSeraphite
