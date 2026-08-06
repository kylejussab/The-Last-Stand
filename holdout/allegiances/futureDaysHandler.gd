extends AllegianceHandler

func on_round_end(playerCharacterCard: Node2D, _playerHand: Array, _opponentCharacterCard: Node2D, _opponentHand: Array) -> Dictionary:
	if battle.battleEngine.lastRoundWinner != battle.battleEngine.Winner.PLAYER:
		return {}
	if not is_instance_valid(playerCharacterCard):
		return {}
	if playerCharacterCard.faction != "Jackson":
		return {}
	
	battle.battleEngine.log_action("System. Future Days activated. " + playerCharacterCard.nameText + " was returned to your hand instead of discarded.")
	
	return {"returnWinningCardToHand": true}
