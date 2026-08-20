extends AllegianceHandler

func on_character_played(card: Node2D, hand: Array, _opponentCard: Node2D) -> void:
	if card.faction != "Infected":
		return
	
	var infectedInHand = hand.filter(func(c): return is_instance_valid(c) and c.faction == "Infected").size()
	if infectedInHand <= 0:
		return
	
	var bonus = infectedInHand * 2
	
	await battle.get_tree().create_timer(0.75).timeout
	
	card.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Horde Mentality.png")
	card.get_node("AnimationPlayer").play("modifierIndicator")
	await card.get_node("AnimationPlayer").animation_finished
	
	battle.battleEngine.log_action("System. Horde Mentality activated. " + card.nameText + " gained " + str(bonus) + " from the horde.")
	card.modify_value(bonus)
