extends AllegianceHandler

func on_character_played(card: Node2D, hand: Array, _opponentCard: Node2D) -> void:
	if card.faction != "Seraphite":
		return
	
	var distinctFactions: Array = []
	for c in hand:
		if is_instance_valid(c) and c.type == "Character" and c.faction not in distinctFactions:
			distinctFactions.append(c.faction)
	
	if distinctFactions.is_empty():
		return
	
	var bonus = distinctFactions.size()
	
	await (Engine.get_main_loop() as SceneTree).create_timer(0.75).timeout
	
	card.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/False Colors.png")
	card.get_node("AnimationPlayer").play("modifierIndicator")
	await card.get_node("AnimationPlayer").animation_finished
	
	card.modify_value(bonus)
	
	battle.battleEngine.log_action("System. False Colors activated. " + card.nameText + " gained +" + str(bonus) + " from faction diversity.")
