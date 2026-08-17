extends AllegianceHandler

func on_character_played(card: Node2D, hand: Array, _otherCard: Node2D) -> void:
	if card.faction != "Firefly":
		return
	
	var supportCount = 0
	for c in hand:
		if is_instance_valid(c) and c.type == "Support":
			supportCount += 1
	
	if supportCount >= battle.battleEngine.maxSupportCards:
		return
	
	battle.battleEngine.log_action("System. Scavenger's Due activated. You drew an extra support card.")
	
	await (Engine.get_main_loop() as SceneTree).create_timer(0.75).timeout
	
	card.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Scavengers Due.png")
	card.get_node("AnimationPlayer").queue("modifierIndicator")
	await battle._await_card_animation(card, "modifierIndicator")
	
	battle.get_node("../supportDeck").draw_card()
