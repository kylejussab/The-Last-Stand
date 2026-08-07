extends AllegianceHandler

const REQUIRED_COUNT = 2
const BONUS = 1

func on_round_end(_playerCharacterCard: Node2D, playerHand: Array, _opponentCharacterCard: Node2D, _opponentHand: Array) -> Dictionary:
	var seraphites = playerHand.filter(func(c): return is_instance_valid(c) and c.type == "Character" and c.faction == "Seraphite")
	
	if seraphites.size() < REQUIRED_COUNT:
		return {}
	
	var target = seraphites[randi() % seraphites.size()]
	
	target.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Faith Network.png")
	target.get_node("AnimationPlayer").play("modifierIndicator")
	await target.get_node("AnimationPlayer").animation_finished
	
	target.modify_value(BONUS)
	
	battle.battleEngine.log_action("System. Faith Network activated. " + target.nameText + " gained +1.")
	
	return {}
