extends AllegianceHandler

func on_round_resolved(_winningCard: Node2D, _winningHand: Array, losingCard: Node2D, losingHand: Array, isPlayerWinner: bool, _damage: int) -> void:
	if isPlayerWinner:
		return
	if losingCard.faction != "Infected":
		return
	
	var eligible = losingHand.filter(func(c): return is_instance_valid(c) and c.faction == "Infected")
	if eligible.is_empty():
		return
	
	battle.battleEngine.log_action("System. Fungal Growth activated. Your Infected cards in hand gained +1.")
	
	for card in eligible:
		card.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Fungal Growth.png")
		card.get_node("AnimationPlayer").play("modifierIndicator")
		card.modify_value(1)
