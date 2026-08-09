extends AllegianceHandler

func on_round_resolved(winningCard: Node2D, _winningHand: Array, losingCard: Node2D, _losingHand: Array, isPlayerWinner: bool, _damage: int) -> void:
	if not isPlayerWinner:
		return
	
	var isNewHunt = _try_hunt(winningCard, losingCard, false)
	var isDefeatingHunted = losingCard.isHunted
	
	if not isNewHunt and not isDefeatingHunted:
		return
	
	var eligible = battle.opponentHand.filter(func(c): return is_instance_valid(c) and not c.get_meta("isRevealed", false))
	if eligible.is_empty():
		return
	
	await battle.get_tree().create_timer(0.5).timeout
	
	winningCard.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Scent Trail.png")
	winningCard.get_node("AnimationPlayer").queue("modifierIndicator")
	
	if isNewHunt:
		await battle.get_tree().create_timer(0.5).timeout
		_play_hunt_effects(losingCard.cardKey, losingCard)
	
	await battle._await_card_animation(winningCard, "modifierIndicator")
	
	var target = eligible[randi() % eligible.size()]
	target.set_meta("isRevealed", true)
	
	battle.battleEngine.log_action("System. Scent Trail activated. A card in the opponent's hand was revealed.")
	
	AudioManager.play_random_card_draw()
	target.get_node("AnimationPlayer").queue("cardFlip")
	
	battle.get_node("%opponentHand").update_hand_positions(battle.cardMoveSpeed)
	
	await battle._await_card_animation(target, "cardFlip")
