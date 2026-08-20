extends OpponentAI
class_name OpponentAIAggressive

const RISKY_CARDS = ["Molotov", "TrapMine", "ShotgunShells", "SmokeBomb", "Brick", "Bottle"]
const DEFENSIVE_CARDS = ["Retreat", "Resilience"]

func _init():
	playstyleName = "Aggressive"

func play_character_card(opponentHand, _playerHand, _playerPlayedCard = null, _playerHealth = 99, _opponentHealth = 99):
	var characters: Array = []
	
	for card in opponentHand:
		if card.type == "Character":
			characters.append(card)
	
	var highest = characters[0]
	for card in characters:
		if card.value > highest.value:
			highest = card
	
	if randf() < 0.7:
		return highest
	
	var others = characters.filter(func(c): return c != highest)
	
	if others.size() == 0:
		return highest
	
	return others[randi() % others.size()]

func choose_support_card(opponent_hand, opponent_character, player_character, opponent_health = 99, _player_health = 99):
	var currentDiff = opponent_character.value - player_character.value
	
	var eligible = []
	for support in opponent_hand:
		if support.type == "Support" and support.canBePlayed:
			eligible.append(support)
	
	if eligible.is_empty():
		return null
	
	if currentDiff >= 4:
		return null

	if currentDiff <= -4 and opponent_health <= 25:
		for support in eligible:
			if support.cardKey in DEFENSIVE_CARDS:
				return support

	var scored = []
	for support in eligible:
		if support.cardKey in DEFENSIVE_CARDS:
			continue
		
		var score = float(support.value)
		if support.cardKey in RISKY_CARDS:
			score *= 0.6
		
		scored.append({"support": support, "score": score})
	
	if scored.is_empty():
		return null
	
	scored.sort_custom(func(a, b): return a.score > b.score)
	var best = scored[0]
	
	if best.score < 1.5:
		return null
	
	if randf() < 0.7:
		return best.support
	
	return null
