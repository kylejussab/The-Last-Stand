extends AllegianceHandler

func on_round_resolved(winningCard: Node2D, _winningHand: Array, losingCard: Node2D, _losingHand: Array, isPlayerWinner: bool, _damage: int) -> void:
	if not isPlayerWinner:
		return
	
	_try_hunt(winningCard, losingCard)
	
	if not losingCard.isHunted:
		return
	
	var cardKey: String = losingCard.cardKey
	
	await battle.get_tree().create_timer(0.5).timeout
	
	winningCard.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Executed.png")
	winningCard.get_node("AnimationPlayer").queue("modifierIndicator")
	
	await battle.get_tree().create_timer(0.5).timeout
	_play_hunt_effects(losingCard.cardKey, losingCard)
	
	await battle._await_card_animation(winningCard, "modifierIndicator")
	
	HoldoutStats.deckAdjustments[cardKey] = HoldoutStats.deckAdjustments.get(cardKey, 0) - 1
	
	if losingCard.gotInfected and losingCard.permanentInfection:
		HoldoutStats.consume_permanent_mark("infected", cardKey, true)
	
	var characterDeckNode = battle.get_node("../characterDeck")
	if cardKey in characterDeckNode.deck:
		characterDeckNode.deck.erase(cardKey)
		characterDeckNode.get_node("RichTextLabel").text = str(characterDeckNode.deck.size())
	
	battle.battleEngine.log_action("System. Executed activated. " + losingCard.nameText + " has been permanently removed from the deck.")
