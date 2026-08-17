extends AllegianceHandler

func on_character_played(card: Node2D, hand: Array, _otherCard: Node2D) -> void:
	if card.faction != "Firefly":
		return
	
	var highestValue = -1
	for c in hand:
		if is_instance_valid(c) and c.type == "Character" and c.faction != "Firefly":
			if c.value > highestValue:
				highestValue = c.value
	
	if highestValue <= card.value:
		return
	
	var bonus = highestValue - card.value
	
	battle.battleEngine.log_action("System. Divided Loyalties activated. " + card.nameText + " used a higher value from hand, gaining +" + str(bonus) + ".")
	
	await (Engine.get_main_loop() as SceneTree).create_timer(0.5).timeout
	
	card.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Divided Loyalties.png")
	card.get_node("AnimationPlayer").queue("modifierIndicator")
	await battle._await_card_animation(card, "modifierIndicator")
	card.modify_value(bonus)
