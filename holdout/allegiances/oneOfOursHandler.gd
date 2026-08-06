extends AllegianceHandler

const VALUE_PENALTY = -2

func on_round_end(_playerCharacterCard: Node2D, _playerHand: Array, opponentCharacterCard: Node2D, _opponentHand: Array) -> Dictionary:
	if not is_instance_valid(opponentCharacterCard):
		return {}
	if opponentCharacterCard.faction != "Jackson":
		return {}
	
	battle.battleEngine.log_action("System. One of Ours activated. " + opponentCharacterCard.nameText + " was added to your hand.")
	
	return {"stealOpponentCard": true, "stealValueModifier": VALUE_PENALTY}
