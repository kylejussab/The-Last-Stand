extends OpponentAI
class_name OpponentAICounter

const RISKY_CARDS = ["Molotov", "TrapMine", "ShotgunShells", "SmokeBomb", "Brick", "Bottle"]
const DEFENSIVE_CARDS = ["Retreat", "Resilience"]

func _init():
	playstyleName = "Counter"

func play_character_card(opponentHand, _playerHand, playerPlayedCard = null, _playerHealth = 99, _opponentHealth = 99):
	var characters: Array = []
	var supports: Array = []
	
	for card in opponentHand:
		if card.type == "Character":
			characters.append(card)
		elif card.type == "Support":
			supports.append(card)
	
	if characters.is_empty():
		return null
	
	var bestCharacter: Node2D
	if playerPlayedCard != null:
		bestCharacter = _play_counter(characters, supports, opponentHand, playerPlayedCard)
	else:
		bestCharacter = _play_diverse(characters)
	
	if randf() < 0.85:
		return bestCharacter
	
	var others = characters.filter(func(c): return c != bestCharacter)
	if others.is_empty():
		return bestCharacter
	return others[randi() % others.size()]

func _play_counter(characters, supports, opponentHand, playerCard):
	var bestCharacter = characters[0]
	var maxCounterScore = _worst_score()
	
	for character in characters:
		var counterScore = character.value
		
		if character.perk != null:
			match character.perk.timing:
				"midRound":
					counterScore += character.perk.calculate_perk_value(character, opponentHand, playerCard)
				"endRound", "lateEndRound":
					var bestEndBonus = character.perk.calculate_end_perk_value(character, null, playerCard, null, opponentHand)
					if not isFlipScriptActive:
						for support in supports:
							var bonus = character.perk.calculate_end_perk_value(character, support, playerCard, null, opponentHand)
							if bonus > bestEndBonus:
								bestEndBonus = bonus
					counterScore += bestEndBonus
				"calculationRound":
					counterScore += character.perk.calculate_after_calculation_perk_value(character, opponentHand, 0, 1)
		
		if _is_better_score(counterScore, maxCounterScore):
			maxCounterScore = counterScore
			bestCharacter = character
	
	return bestCharacter

func _play_diverse(characters):
	var bestCharacter = characters[0]
	var maxReplaceability = -1
	
	for character in characters:
		var replaceability = 0
		var characterRoles = character.role.split("/")
		
		for other in characters:
			if other == character:
				continue
			if other.faction == character.faction:
				replaceability += 1
			for role in characterRoles:
				if role in other.role.split("/"):
					replaceability += 1
		
		if replaceability > maxReplaceability:
			maxReplaceability = replaceability
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
	
	var effectiveDiff = _effective_diff(currentDiff)
	
	if effectiveDiff >= 4:
		return null
	
	if effectiveDiff <= -4 and opponent_health <= 25:
		for support in eligible:
			if support.cardKey in DEFENSIVE_CARDS:
				return support
	
	if isFlipScriptActive:
		return null  # ceiling/discount/matchup-weight all only reward raising the AI's own value
	
	var bestSupport = null
	var bestBlendedScore = -INF
	
	for support in eligible:
		if support.cardKey in DEFENSIVE_CARDS:
			continue
		
		var ceiling = _calculate_max_support_value(support, opponent_character)
		
		var discounted = float(support.value)
		if support.cardKey in RISKY_CARDS:
			discounted *= 0.6
		
		var matchupWeight = 1.0
		if currentDiff < 0:
			matchupWeight = 1.2
		
		var blended = ((ceiling + discounted) / 2.0) * matchupWeight
		
		if blended > bestBlendedScore:
			bestBlendedScore = blended
			bestSupport = support
	
	if bestSupport == null or bestBlendedScore < 1.5:
		return null
	
	return bestSupport

func _calculate_max_support_value(support, character) -> float:
	match support.cardKey:
		"Silencer":
			var bonus = 2 if character.role.contains("Crafty") or character.role.contains("Defensive") else 0
			return support.value + bonus
		"Retreat":
			return 6
		"Resilience":
			return support.value + 3
		_:
			return support.value
