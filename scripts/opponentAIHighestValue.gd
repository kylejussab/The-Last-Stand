extends OpponentAI
class_name OpponentAIHighestValue

func play_character_card(_opponent_hand, _player_hand):
	var highest = null
	for card in _opponent_hand:
		if card.type == "Character":
			if highest == null or card.value > highest.value:
				highest = card
	return highest

func choose_support_card(opponent_hand, opponent_character, player_character):
	var best = null
	var opponent_total = opponent_character.value
	
	for support in opponent_hand:
		if support.type == "Support" && support.canBePlayed:
			var new_total = opponent_total + support.value
			
			if new_total > player_character.value:
				return support   # win immediately
			
			if new_total == player_character.value and best == null:
				best = support   # tie fallback
	
	return best
