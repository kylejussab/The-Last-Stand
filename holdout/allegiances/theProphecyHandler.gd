extends AllegianceHandler

const PERCENTAGE = 0.25

func on_round_end(playerCharacterCard: Node2D, playerHand: Array, _opponentCharacterCard: Node2D, _opponentHand: Array) -> Dictionary:
	if not is_instance_valid(playerCharacterCard) or playerCharacterCard.faction != "Seraphite":
		return {}
	
	var hasProphet = playerHand.any(func(c): return is_instance_valid(c) and c.cardKey == "TheProphet")
	if not hasProphet:
		return {}
	
	var eligibleTargets = playerHand.filter(func(c): return is_instance_valid(c) and c.cardKey != "TheProphet")
	if eligibleTargets.is_empty():
		return {}
	
	var bonus = int(playerCharacterCard.value * PERCENTAGE)
	if bonus <= 0:
		return {}
	
	var target = eligibleTargets[randi() % eligibleTargets.size()]
	
	target.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/The Prophecy Foretold.png")
	target.get_node("AnimationPlayer").play("modifierIndicator")
	await target.get_node("AnimationPlayer").animation_finished
	
	target.modify_value(bonus)
	
	battle.battleEngine.log_action("System. The Prophecy Foretold activated. " + target.nameText + " gained +" + str(bonus) + " from " + playerCharacterCard.nameText + "'s resolve.")
	
	return {}
