extends OpponentAI
class_name OpponentAIBalanced

const RISKY_CARDS = ["Molotov", "TrapMine", "ShotgunShells", "SmokeBomb", "Brick", "Bottle"]
const DEFENSIVE_CARDS = ["Retreat", "Resilience"]

func _init():
	playstyleName = "Balanced"

func play_character_card(opponentHand, _playerHand, _playerPlayedCard = null, _playerHealth = 99, _opponentHealth = 99):
	var characters: Array = []
	var supports: Array = []
	
	for card in opponentHand:
		if card.type == "Character":
			characters.append(card)
		elif card.type == "Support":
			supports.append(card)
	
	var bestCharacter = characters[0] if characters.size() > 0 else null
	var maxComboValue = -1
	
	for character in characters:
		var bestSupportScore = 0.0
		
		for support in supports:
			var score = float(support.value)
			if support.cardKey in RISKY_CARDS:
				score *= 0.6 # rough guesswork discount, not real backfire odds
			
			if score > bestSupportScore:
				bestSupportScore = score
		
		var comboValue = character.value + bestSupportScore
		
		if comboValue > maxComboValue:
			maxComboValue = comboValue
			bestCharacter = character
	
	if randf() < 0.85:
		return bestCharacter
	
	var others = characters.filter(func(c): return c != bestCharacter)
	
	if others.size() == 0:
		return bestCharacter
	
	return others[randi() % others.size()]

func choose_support_card(opponent_hand, opponent_character, player_character, opponent_health = 99, _player_health = 99):
	var currentDiff = opponent_character.value - player_character.value
	
	var eligible = []
	for support in opponent_hand:
		if support.type == "Support" and support.canBePlayed:
			eligible.append(support)
	
	if eligible.is_empty():
		return null
	
	# Already comfortably ahead on the matchup? The combo already worked, don't spend more.
	if currentDiff >= 4:
		return null
	
	# Badly behind and running low? Consider a defensive card.
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
	
	return best.support
