extends AllegianceHandler

func on_round_resolved(winningCard: Node2D, _winningHand: Array, _losingCard: Node2D, _losingHand: Array, isPlayerWinner: bool, damage: int) -> void:
	if not isPlayerWinner:
		return
	if winningCard.faction != "Infected":
		return
	if damage <= 0:
		return
	
	var bonusDamage = int(ceil(damage * 0.5))
	if bonusDamage <= 0:
		return
	
	winningCard.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/CBI.png")
	winningCard.get_node("AnimationPlayer").play("modifierIndicator")
	await winningCard.get_node("AnimationPlayer").animation_finished
	
	battle.battleEngine.log_action("System. Cordyceps Brain Infection activated. Opponent took " + str(bonusDamage) + " additional damage.")
	await battle._deal_damage(Actor.Type.OPPONENT, bonusDamage)
