extends AllegianceHandler

func on_both_characters_played(playerCard: Node2D, _playerHand: Array, opponentCard: Node2D) -> void:
	if playerCard.faction != "WLF":
		return
	
	if not is_instance_valid(opponentCard):
		return
	
	if opponentCard.faction != "Seraphite" and opponentCard.faction != "Infected":
		return
	
	await (Engine.get_main_loop() as SceneTree).create_timer(0.75).timeout
	
	playerCard.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Kill Order.png")
	playerCard.get_node("AnimationPlayer").queue("modifierIndicator")
	await playerCard.get_node("AnimationPlayer").animation_finished
	
	playerCard.modify_value(2)
	
	battle.battleEngine.log_action("System. Kill Order activated. " + playerCard.nameText + " gained +2 against " + opponentCard.faction + ".")
