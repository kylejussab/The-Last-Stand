extends AllegianceHandler

func on_round_resolved(winningCard: Node2D, _winningHand: Array, losingCard: Node2D, _losingHand: Array, isPlayerWinner: bool, _damage: int) -> void:
	if not isPlayerWinner:
		return
	
	var isNewHunt = _try_hunt(winningCard, losingCard, true)
	if not isNewHunt:
		return
	
	await battle.get_tree().create_timer(0.5).timeout
	
	winningCard.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/War.png")
	winningCard.get_node("AnimationPlayer").queue("modifierIndicator")
	
	await battle.get_tree().create_timer(0.5).timeout
	_play_hunt_effects(losingCard.cardKey, losingCard)
	
	await battle._await_card_animation(winningCard, "modifierIndicator")
	
	battle.battleEngine.log_action("System. War activated. " + losingCard.nameText + " has been marked as hunted.")
