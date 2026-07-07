extends Node
class_name OpponentAI

var playstyleName: String = "Base"

func play_character_card(_opponentHand, _playerHand, _playerPlayedCard = null):
	# Override in subclass
	return null

func choose_support_card(_opponentHand, _opponentCharacter, _playerCharacter):
	# Override in subclass
	return null
