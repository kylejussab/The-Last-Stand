extends AllegianceHandler

func on_both_characters_played(_playerCard: Node2D, _playerHand: Array, opponentCard: Node2D) -> void:
	if opponentCard.faction != "Infected" and opponentCard.faction != "Seraphite":
		return
	
	if opponentCard.isNullified:
		return
	
	await battle.get_tree().create_timer(0.5).timeout
	
	opponentCard.isNullified = true
	
	opponentCard.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/No Safe Haven.png")
	opponentCard.get_node("AnimationPlayer").queue("modifierIndicator")
	await battle._await_card_animation(opponentCard, "modifierIndicator")
	
	battle.battleEngine.log_action("System. No Safe Haven activated. The opponent's perk will not activate.")
