extends AllegianceHandler

func on_both_characters_played(card: Node2D, _hand: Array, _otherCard: Node2D) -> void:
	if card.faction != "Firefly":
		return
	
	if not card.perk:
		return
	
	card.perk.forceTrigger = true
	
	battle.battleEngine.log_action("System. Necessary Compromise activated. " + card.nameText + "'s perk will trigger automatically.")
	
	card.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Necessary Compromise.png")
	card.get_node("AnimationPlayer").queue("modifierIndicator")
	await battle._await_card_animation(card, "modifierIndicator")
