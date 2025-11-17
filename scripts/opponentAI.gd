extends Node
class_name OpponentAI

func play_character_card(_opponent_hand, _player_hand):
	# Override in subclass
	return null

func choose_support_card(_opponent_hand, _opponent_character, _player_character):
	# Override in subclass
	return null
