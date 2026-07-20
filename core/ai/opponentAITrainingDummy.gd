extends OpponentAI
class_name OpponentAITutorialDummy

var forcedCharacterKey: String = ""
var forcedSupportKey: String = ""

func play_character_card(opponentHand: Array, _playerHand: Array, _playerPlayedCard = null):
	if forcedCharacterKey != "":
		for card in opponentHand:
			if card.type == "Character" and card.cardKey == forcedCharacterKey:
				return card
				
	# Failsafe
	for card in opponentHand:
		if card.type == "Character":
			return card
			
	return null

func choose_support_card(opponent_hand, _opponent_character, _player_character, _opponent_health = 99, _player_health = 99):
	if forcedSupportKey != "":
		for card in opponent_hand:
			if card.type == "Support" and card.cardKey == forcedSupportKey:
				return card
				
	# Intentionally skip if nothing is given
	return null
