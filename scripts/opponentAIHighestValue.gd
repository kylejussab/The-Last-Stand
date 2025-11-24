extends OpponentAI
class_name OpponentAIHighestValue

func play_character_card(opponent_hand, _player_hand):
	var characters: Array = []
	
	# Collect character cards only
	for card in opponent_hand:
		if card.type == "Character":
			characters.append(card)
	
	# Find highest-value card
	var highest = characters[0]
	for card in characters:
		if int(card.get_node("value").text) > int(highest.get_node("value").text):
			highest = card
	
	# 70% chance: choose highest
	if randf() < 0.7:
		return highest
	
	# 30% chance: choose a random non-highest card
	var others = characters.filter(func(c): return c != highest)
	
	if others.size() == 0:
		# Only one character, must pick it
		return highest
	
	return others[randi() % others.size()]

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
