extends AllegianceHandler

func on_character_played(card: Node2D, hand: Array, _otherCard: Node2D) -> void:
	if card.faction != "Firefly":
		return
	
	var ownTypes = {}
	for t in card.role.split("/"):
		ownTypes[t] = true
	
	var bonus = 0
	for c in hand:
		if is_instance_valid(c) and c.type == "Character":
			var fullyCovered = true
			for t in c.role.split("/"):
				if not ownTypes.has(t):
					fullyCovered = false
					break
			if not fullyCovered:
				bonus += 1
	
	if bonus <= 0:
		return
	
	battle.battleEngine.log_action("System. Just Cargo activated. " + card.nameText + " gained +" + str(bonus) + " for card types in hand it doesn't share.")
	
	await (Engine.get_main_loop() as SceneTree).create_timer(0.5).timeout
	
	card.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Just Cargo.png")
	card.get_node("AnimationPlayer").queue("modifierIndicator")
	await battle._await_card_animation(card, "modifierIndicator")
	card.modify_value(bonus)
