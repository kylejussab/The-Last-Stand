extends AllegianceHandler

func on_character_played(card: Node2D, _hand: Array, _opponentCard: Node2D) -> void:
	if card.faction != "Jackson":
		return
	
	var eligible = battle.opponentHand.filter(func(c): return is_instance_valid(c) and not c.get_meta("isRevealed", false))
	if eligible.is_empty():
		return
	
	card.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Patrol Route.png")
	card.get_node("AnimationPlayer").play("modifierIndicator")
	await card.get_node("AnimationPlayer").animation_finished
	
	var target = eligible[randi() % eligible.size()]
	target.set_meta("isRevealed", true)
	
	battle.battleEngine.log_action("System. Patrol Route activated. A card in the opponent's hand was revealed.")
	
	AudioManager.play_random_card_draw()
	target.get_node("AnimationPlayer").play("cardFlip")
	
	battle.get_node("%opponentHand").update_hand_positions(battle.cardMoveSpeed)
	
	await target.get_node("AnimationPlayer").animation_finished
