extends AllegianceHandler

func on_round_end(playerCharacterCard: Node2D, _playerHand: Array, opponentCharacterCard: Node2D, _opponentHand: Array) -> Dictionary:
	if not is_instance_valid(opponentCharacterCard) or not is_instance_valid(playerCharacterCard):
		return {}
	
	var playerWonWithSeraphite = battle.battleEngine.lastRoundWinner == battle.battleEngine.Winner.PLAYER and playerCharacterCard.faction == "Seraphite"
	if not playerWonWithSeraphite:
		return {}
	
	var absValue = abs(opponentCharacterCard.value)
	var halvedAbsValue = int(absValue / 2.0)
	var penalty = absValue - halvedAbsValue 
	
	var opponentName: String = Actor.Avatar.keys()[HoldoutStats.currentOpponent].capitalize()
	
	opponentCharacterCard.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Wounded Prey.png")
	opponentCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
	await opponentCharacterCard.get_node("AnimationPlayer").animation_finished
	
	if penalty != 0:
		opponentCharacterCard.modify_value(-penalty)
	
	battle.battleEngine.log_action("System. Wounded Prey activated. " + opponentName + "'s " + opponentCharacterCard.nameText + " remains in play, weakened.")
	
	opponentCharacterCard.set_meta("isRevealed", true)
	return {"preserveOpponentCard": true}
