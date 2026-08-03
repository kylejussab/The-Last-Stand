extends AllegianceHandler

func on_round_resolved(_winningCard: Node2D, _winningHand: Array, losingCard: Node2D, _losingHand: Array, isPlayerWinner: bool, _damage: int) -> void:
	if isPlayerWinner:
		return
	if losingCard.faction != "Infected":
		return
	
	losingCard.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Necrotic Feedback.png")
	losingCard.get_node("AnimationPlayer").play("modifierIndicator")
	await losingCard.get_node("AnimationPlayer").animation_finished
	
	battle.battleEngine.log_action("System. Necrotic Feedback activated. You dealt 2 damage anyway.")
	battle._deal_damage(Actor.Type.OPPONENT, 2)
