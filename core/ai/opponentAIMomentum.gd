extends OpponentAI
class_name OpponentAIMomentum

const MEMORY_LENGTH = 3
const RISKY_CARDS = ["Molotov", "TrapMine", "ShotgunShells", "SmokeBomb", "Brick", "Bottle"]
const DEFENSIVE_CARDS = ["Retreat", "Resilience"]

var recentResults: Array = []

func _init():
	playstyleName = "Momentum"

func record_round_result(won: bool) -> void:
	recentResults.append(won)
	if recentResults.size() > MEMORY_LENGTH:
		recentResults.pop_front()

func play_character_card(opponentHand, _playerHand, _playerPlayedCard = null, _playerHealth = 99, _opponentHealth = 99):
	var characters: Array = []
	var supports: Array = []
	
	for card in opponentHand:
		if card.type == "Character":
			characters.append(card)
		elif card.type == "Support":
			supports.append(card)
	
	if characters.is_empty():
		return null
	
	var winStreak = recentResults.size() == MEMORY_LENGTH and recentResults.all(func(r): return r == true)
	var loseStreak = recentResults.size() == MEMORY_LENGTH and recentResults.all(func(r): return r == false)
	
	var bestCharacter: Node2D
	
	if winStreak:
		bestCharacter = _play_aggressive(characters)
	elif loseStreak:
		bestCharacter = _play_calculated(characters, supports, opponentHand)
	else:
		bestCharacter = _play_balanced(characters, supports)
	
	if randf() < 0.85:
		return bestCharacter
	
	var others = characters.filter(func(c): return c != bestCharacter)
	if others.is_empty():
		return bestCharacter
	return others[randi() % others.size()]

func _play_aggressive(characters: Array) -> Node2D:
	var best = characters[0]
	for character in characters:
		if character.value > best.value:
			best = character
	return best

func _play_balanced(characters: Array, supports: Array) -> Node2D:
	var bestCharacter = characters[0]
	var maxComboValue = -1
	
	for character in characters:
		var bestSupportScore = 0.0
		for support in supports:
			var score = float(support.value)
			if support.cardKey in RISKY_CARDS:
				score *= 0.6
			if score > bestSupportScore:
				bestSupportScore = score
		
		var comboValue = character.value + bestSupportScore
		if comboValue > maxComboValue:
			maxComboValue = comboValue
			bestCharacter = character
	
	return bestCharacter

func _play_calculated(characters: Array, supports: Array, opponentHand: Array) -> Node2D:
	var bestCharacter = characters[0]
	var maxPotentialValue = -1

	for character in characters:
		var potentialValue = character.value
		
		var bestSupportValue = 0
		for support in supports:
			if support.value > bestSupportValue:
				bestSupportValue = support.value
		potentialValue += bestSupportValue
		
		if character.perk != null:
			match character.perk.timing:
				"midRound":
					potentialValue += character.perk.calculate_perk_value(character, opponentHand, null)
				"endRound", "lateEndRound":
					var bestEndBonus = character.perk.calculate_end_perk_value(character, null, null, null, opponentHand)
					for support in supports:
						var bonus = character.perk.calculate_end_perk_value(character, support, null, null, opponentHand)
						if bonus > bestEndBonus:
							bestEndBonus = bonus
					potentialValue += bestEndBonus
				"calculationRound":
					potentialValue += character.perk.calculate_after_calculation_perk_value(character, opponentHand, 0, 1)
		
		if potentialValue > maxPotentialValue:
			maxPotentialValue = potentialValue
			bestCharacter = character
	
	return bestCharacter

func choose_support_card(opponent_hand, opponent_character, player_character, opponent_health = 99, _player_health = 99):
	var currentDiff = opponent_character.value - player_character.value
	
	var eligible = []
	for support in opponent_hand:
		if support.type == "Support" and support.canBePlayed:
			eligible.append(support)
	
	if eligible.is_empty():
		return null
	
	var winStreak = recentResults.size() == MEMORY_LENGTH and recentResults.all(func(r): return r == true)
	var loseStreak = recentResults.size() == MEMORY_LENGTH and recentResults.all(func(r): return r == false)
	
	if winStreak:
		return _choose_support_aggressive(eligible, currentDiff, opponent_health)
	elif loseStreak:
		return _choose_support_defensive(eligible, currentDiff, opponent_health)
	else:
		return _choose_support_balanced(eligible, currentDiff, opponent_health)

func _choose_support_aggressive(eligible: Array, currentDiff: int, opponent_health: int) -> Node2D:
	# On a hot streak: chase the biggest number, barely holds back
	if currentDiff >= 4:
		return null
	
	if currentDiff <= -4 and opponent_health <= 25:
		for support in eligible:
			if support.cardKey in DEFENSIVE_CARDS:
				return support
	
	var best = null
	var bestScore = -INF
	for support in eligible:
		if support.cardKey in DEFENSIVE_CARDS:
			continue
		var score = float(support.value)
		if support.cardKey in RISKY_CARDS:
			score *= 0.6
		if score > bestScore:
			bestScore = score
			best = support
	
	if best != null and bestScore >= 1.5 and randf() < 0.85:
		return best
	
	return null

func _choose_support_balanced(eligible: Array, currentDiff: int, opponent_health: int) -> Node2D:
	# Neutral state: steady, dependable pick, same restraint as Balanced
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
	
	return best.support

func _choose_support_defensive(eligible: Array, currentDiff: int, _opponent_health: int) -> Node2D:
	# On a cold streak: prioritise stabilising, reaches for defensive cards more
	if currentDiff > 0:
		return null
	
	var candidates = []
	for support in eligible:
		if support.cardKey in DEFENSIVE_CARDS:
			continue
		var score = float(support.value)
		if support.cardKey in RISKY_CARDS:
			score *= 0.6
		var resultingMargin = currentDiff + score
		if resultingMargin > 0:
			candidates.append({"support": support, "margin": resultingMargin})
	
	if not candidates.is_empty():
		candidates.sort_custom(func(a, b): return a.margin < b.margin)
		return candidates[0].support
	
	for support in eligible:
		if support.cardKey == "Retreat":
			return support
	
	for support in eligible:
		if support.cardKey == "Resilience":
			return support
	
	return null
