extends AllegianceHandler

func on_round_resolved(_winningCard: Node2D, winningHand: Array, _losingCard: Node2D, _losingHand: Array, isPlayerWinner: bool, _damage: int) -> void:
	if not isPlayerWinner:
		return
	
	var eligible = winningHand.filter(func(c): return is_instance_valid(c) and c.faction == "Infected")
	if eligible.is_empty():
		return
	
	battle.battleEngine.log_action("System. Fungal Growth activated. Your Infected cards in hand gained +1.")
	
	for target in eligible:
		_animate_and_boost(target)

func _animate_and_boost(target: Node2D) -> void:
	target.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Fungal Growth.png")
	target.get_node("AnimationPlayer").play("modifierIndicator")
	await target.get_node("AnimationPlayer").animation_finished
	target.modify_value(1)
