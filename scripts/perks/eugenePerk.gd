extends PerkBase

func _init() -> void:
	timing = "endRound"

func apply_end_perk(thisCharacterCard, thisSupportCard, _otherCharacterCard, _otherSupportCard, thisHand):
	var perkAmount: int = 0
	
	for type in thisHand:
		if type.role.contains("Crafty") and type.type == "Character":
			perkAmount += 1
			
	if thisSupportCard and thisSupportCard.role.contains("Survivor"):
		perkAmount += 3
			
	if perkAmount > 0:
		thisCharacterCard.modify_value(perkAmount)

func would_perk_trigger(_thisCharacterCard, thisSupportCard, _otherCharacterCard, _otherSupportCard, thisHand) -> bool:
	var hasCrafty = thisHand.any(func(type): return type.role.contains("Crafty") and type.type == "Character")
	var hasSurvivorSupport = thisSupportCard and thisSupportCard.role.contains("Survivor")
	
	return hasCrafty or hasSurvivorSupport
