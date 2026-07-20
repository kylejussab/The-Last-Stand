extends Node
class_name OpponentAI

var playstyleName: String = "Base"

func play_character_card(_opponentHand, _playerHand, _playerPlayedCard = null):
	# Override in subclass
	return null

func choose_support_card(_opponent_hand, _opponent_character, _player_character, _opponent_health = 99, _player_health = 99):
	# Override in subclass
	return null
