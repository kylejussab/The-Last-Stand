extends AllegianceHandler

func on_round_resolved(winningCard: Node2D, _winningHand: Array, _losingCard: Node2D, _losingHand: Array, isPlayerWinner: bool, _damage: int) -> void:
	if not isPlayerWinner:
		return
	if winningCard.faction != "Infected":
		return
	
	winningCard.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Necrotic Feedback.png")
	winningCard.get_node("AnimationPlayer").play("modifierIndicator")
	await winningCard.get_node("AnimationPlayer").animation_finished
	
	battle.battleEngine.log_action("System. Necrotic Feedback activated. Opponent took 2 additional damage.")
	await battle._deal_damage(Actor.Type.OPPONENT, 2)
