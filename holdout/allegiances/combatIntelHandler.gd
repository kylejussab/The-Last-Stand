extends AllegianceHandler

func on_round_resolved(_winningCard: Node2D, winningHand: Array, _losingCard: Node2D, _losingHand: Array, isPlayerWinner: bool, _damage: int) -> void:
	if not isPlayerWinner:
		return
	
	var eligible = winningHand.filter(func(c): return is_instance_valid(c) and c.type == "Character" and c.faction == "WLF")
	if eligible.is_empty():
		return
	
	var target = eligible[randi() % eligible.size()]
	
	await battle.get_tree().create_timer(0.5).timeout
	
	target.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Combat Intel.png")
	target.get_node("AnimationPlayer").queue("modifierIndicator")
	await battle._await_card_animation(target, "modifierIndicator")
	
	target.modify_value(1)
	
	battle.battleEngine.log_action("System. Combat Intel activated. " + target.nameText + " gained +1.")
