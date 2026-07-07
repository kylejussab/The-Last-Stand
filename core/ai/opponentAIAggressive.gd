extends OpponentAI
class_name OpponentAIAggressive

func _init():
	playstyleName = "Aggressive"

func play_character_card(opponentHand, _playerHand, _playerPlayedCard = null, _playerHealth = 99, _opponentHealth = 99):
	var characters: Array = []
	
	# Collect character cards only
	for card in opponentHand:
		if card.type == "Character":
			characters.append(card)
	
	# Find highest-value card
	var highest = characters[0]
	for card in characters:
		if card.value > highest.value:
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
