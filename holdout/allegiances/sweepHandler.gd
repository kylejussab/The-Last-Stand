extends AllegianceHandler

func on_both_characters_played(playerCard: Node2D, _playerHand: Array, _opponentCard: Node2D) -> void:
	if playerCard.faction != "WLF":
		return
	
	if battle.battleEngine.previousRoundFaction != "WLF":
		return
	
	await battle.get_tree().create_timer(0.5).timeout
	
	playerCard.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Sweep.png")
	playerCard.get_node("AnimationPlayer").queue("modifierIndicator")
	await battle._await_card_animation(playerCard, "modifierIndicator")
	
	await battle._deal_damage(Actor.Type.OPPONENT, 2)
	
	battle.battleEngine.log_action("System. Sweep activated. " + playerCard.nameText + " dealt 2 direct damage from consecutive WLF pressure.")
