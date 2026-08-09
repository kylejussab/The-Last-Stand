extends AllegianceHandler

func on_round_resolved(winningCard: Node2D, winningHand: Array, losingCard: Node2D, _losingHand: Array, isPlayerWinner: bool, _damage: int) -> void:
	if not isPlayerWinner:
		return
	
	var isNewHunt = _try_hunt(winningCard, losingCard, false)
	if not isNewHunt:
		return
	
	var eligible = winningHand.filter(func(c): return is_instance_valid(c))
	if eligible.is_empty():
		return
	
	var target = eligible[randi() % eligible.size()]
	
	await battle.get_tree().create_timer(0.5).timeout
	
	target.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Manhunt.png")
	target.get_node("AnimationPlayer").queue("modifierIndicator")
	
	await battle.get_tree().create_timer(0.5).timeout
	_play_hunt_effects(losingCard.cardKey, losingCard)
	
	await battle._await_card_animation(target, "modifierIndicator")
	
	target.modify_value(2)
	
	battle.battleEngine.log_action("System. Manhunt activated. " + losingCard.nameText + " has been marked as hunted, and " + target.nameText + " gained +2.")
