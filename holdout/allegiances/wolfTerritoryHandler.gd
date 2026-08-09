extends AllegianceHandler

func on_round_end(_playerCharacterCard: Node2D, playerHand: Array, _opponentCharacterCard: Node2D, _opponentHand: Array) -> Dictionary:
	var toDiscard = playerHand.filter(func(c): return is_instance_valid(c) and c.type == "Character" and (c.faction == "Infected" or c.faction == "Seraphite"))
	
	if toDiscard.is_empty():
		return {}
	
	var handNode = battle.get_node("%playerHand")
	
	for card in toDiscard:
		await battle._place_card_in_discard(card, handNode)
	
	battle.battleEngine.log_action("System. Wolf Territory activated. Infected and Seraphite cards were discarded from your hand.")
	
	return {}
