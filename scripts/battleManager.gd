extends Node

const CARD_MOVE_SPEED = 0.2
const MAX_CHARACTER_CARDS = 4
const MAX_SUPPORT_CARDS = 4

var battleTimer
var opponentCharacterCardSlot
var opponentSupportCardSlot

var playerCharacterCard
var playerSupportCard
var opponentCharacterCard
var opponentSupportCard

var playerHasPlayedCharacter = false
var opponentHasPlayedCharacter = false
var playerHasPlayedSupport = false
var opponentHasPlayedSupport = false
var turnNumber = 1

var playerStartsTurn = true

var discardedCards = []

func _ready() -> void:
	battleTimer = $"../battleTimer"
	battleTimer.one_shot = true
	battleTimer.wait_time = 1.0
	
	opponentCharacterCardSlot = $"../cardSlots/opponentCardSlotCharacter"
	opponentSupportCardSlot = $"../cardSlots/opponentCardSlotSupport"
	
	$"../cardManager".connect("characterPlayed", Callable(self, "on_player_character_played"))
	$"../cardManager".connect("supportPlayed", Callable(self, "on_player_support_played"))
	
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false

func resetTurn():
	playerHasPlayedCharacter = false
	opponentHasPlayedCharacter = false
	playerHasPlayedSupport = false
	opponentHasPlayedSupport = false
	
	playerCharacterCard = null
	playerSupportCard = null
	opponentCharacterCard = null
	opponentSupportCard = null
	
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false
	
	if turnNumber % 2 == 0:
		playerStartsTurn = false
	else:
		playerStartsTurn = true
	
	if !playerStartsTurn:
		battleTimer.start()
		await battleTimer.timeout
		opponent_character_turn()

func on_player_character_played(card):
	playerHasPlayedCharacter = true
	playerCharacterCard = card
	
	if playerStartsTurn:
		await opponent_character_turn()
	else:
		attempt_winning_support()

func on_player_support_played(card):
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false
	
	playerHasPlayedSupport = true
	
	playerSupportCard = card
	
#	Opponent must calculate if a win is possible with support play
#	For now the opponent will just play the first support available to win (if one exists)
	if playerStartsTurn:
		await play_equalling_support()
		$"../EndTurnButton".disabled = false
		$"../EndTurnButton".visible = true
	else:
		# Wait
		battleTimer.start()
		await battleTimer.timeout
		_on_end_turn_button_pressed()

func opponent_character_turn():
	# Wait
	battleTimer.start()
	await battleTimer.timeout
	
	await play_card_with_highest_value()
	
	opponentHasPlayedCharacter = true
	
	if playerStartsTurn:
		$"../EndTurnButton".disabled = false
		$"../EndTurnButton".visible = true

func update_opponent_hand():
	var characterDeckReference = $"../characterDeck"
	var supportDeckReference = $"../supportDeck"
	var opponentHand = $"../opponentHand".opponentHand

	var characterCount = 0
	var supportCount = 0

	for card in opponentHand:
		if card.type == "Character":
			characterCount += 1
		elif card.type == "Support":
			supportCount += 1
	
	while characterCount < MAX_CHARACTER_CARDS:
		characterDeckReference.draw_opponent_card()
		characterCount += 1
		battleTimer.start()
		await battleTimer.timeout
	
	while supportCount < MAX_SUPPORT_CARDS:
		supportDeckReference.draw_opponent_card()
		supportCount += 1
		battleTimer.start()
		await battleTimer.timeout

func update_player_hand():
	var characterDeckReference = $"../characterDeck"
	var supportDeckReference = $"../supportDeck"
	var playerHand = $"../playerHand".playerHand

	var characterCount = 0
	var supportCount = 0

	for card in playerHand:
		if card.type == "Character":
			characterCount += 1
		elif card.type == "Support":
			supportCount += 1
	
	while characterCount < MAX_CHARACTER_CARDS:
		characterDeckReference.draw_card()
		characterCount += 1
		battleTimer.start()
		await battleTimer.timeout
	
	while supportCount < MAX_SUPPORT_CARDS:
		supportDeckReference.draw_card()
		supportCount += 1
		battleTimer.start()
		await battleTimer.timeout

func play_card_with_highest_value():
	# Opponent AI, for now it plays the highest value card.
	var opponentHand = $"../opponentHand".opponentHand
	
	var highestValueCard: Node = null

	for card in opponentHand:
		if card.type != "Character":
			continue

		if highestValueCard == null or card.value > highestValueCard.value:
			highestValueCard = card
	
	# Animate the card
	var tween = get_tree().create_tween()
	tween.tween_property(highestValueCard, "position", opponentCharacterCardSlot.position, CARD_MOVE_SPEED)
	
	opponentCharacterCard = highestValueCard
	
	# Comment this out when we hide opponent cards
	highestValueCard.get_node("AnimationPlayer").play("cardFlip")
	
	$"../opponentHand".remove_card_from_hand(highestValueCard)

func play_equalling_support():
	var opponentHand = $"../opponentHand".opponentHand
	
#	For now we are just adding the raw values. Not worrying about perks
	var playerTotalPower
	if playerSupportCard:
		playerTotalPower = playerCharacterCard.value + playerSupportCard.value
	else:
		playerTotalPower = playerCharacterCard.value
	
	var opponentTotalPower = opponentCharacterCard.value
	
	if opponentTotalPower > playerTotalPower:
		return
	
	for support in opponentHand:
		if support.type == "Support":
			if opponentTotalPower + support.value > playerTotalPower:
				opponentSupportCard = support
				break
			elif opponentTotalPower + support.value == playerTotalPower && !opponentSupportCard:
				opponentSupportCard = support
	
	if opponentSupportCard:
		opponentHasPlayedSupport = true
		battleTimer.start()
		await battleTimer.timeout
		
		# Animate the card
		var tween = get_tree().create_tween()
		tween.tween_property(opponentSupportCard, "position", opponentSupportCardSlot.position, CARD_MOVE_SPEED)
		
		# Comment this out when we hide opponent cards
		opponentSupportCard.get_node("AnimationPlayer").play("cardFlip")
		
		$"../opponentHand".remove_card_from_hand(opponentSupportCard)
	else:
		battleTimer.start()
		await battleTimer.timeout

func attempt_winning_support():
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false
	
	var opponentHand = $"../opponentHand".opponentHand
	
#	For now we are just adding the raw values. Not worrying about perks
	var playerTotalPower
	if playerSupportCard:
		playerTotalPower = playerCharacterCard.value + playerSupportCard.value
	else:
		playerTotalPower = playerCharacterCard.value
	
	var opponentTotalPower = opponentCharacterCard.value
	
	if opponentTotalPower > playerTotalPower:
		if !playerStartsTurn:
			battleTimer.start()
			await battleTimer.timeout
			await end_turn_sequence()
		return
	
	for support in opponentHand:
		if support.type == "Support":
			if opponentTotalPower + support.value > playerTotalPower:
				opponentSupportCard = support
				opponentHasPlayedSupport = true
				break
	
	if opponentSupportCard:
		battleTimer.start()
		await battleTimer.timeout
		
		# Animate the card
		var tween = get_tree().create_tween()
		tween.tween_property(opponentSupportCard, "position", opponentSupportCardSlot.position, CARD_MOVE_SPEED)
		
		# Comment this out when we hide opponent cards
		opponentSupportCard.get_node("AnimationPlayer").play("cardFlip")
		
		$"../opponentHand".remove_card_from_hand(opponentSupportCard)
		
	if playerStartsTurn:
		battleTimer.wait_time = 1.5
		battleTimer.start()
		await battleTimer.timeout
		battleTimer.wait_time = 1
	else:
		$"../EndTurnButton".disabled = false
		$"../EndTurnButton".visible = true

func _on_end_turn_button_pressed() -> void:
	end_turn_sequence()

func move_cards_to_discard(cards):
	for card in cards:
		discardedCards.append(card)
		card.scale = Vector2(1, 1)
		
		var tween = get_tree().create_tween()
		tween.tween_property(card, "position", Vector2(150, 280), CARD_MOVE_SPEED)
	
	$"../cardSlots/cardSlotSupport".occupied = false
	$"../cardSlots/cardSlotCharacter".occupied = false

func end_turn_sequence():
	var cardsToDiscard = []
	
	if playerSupportCard:
		cardsToDiscard.append(playerSupportCard)
	else:
		if playerStartsTurn:
			await attempt_winning_support()

	cardsToDiscard.append(playerCharacterCard)
	cardsToDiscard.append(opponentCharacterCard)
	
	if opponentSupportCard:
		cardsToDiscard.append(opponentSupportCard)
	
	move_cards_to_discard(cardsToDiscard)
	
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false
	
	# Wait
	battleTimer.wait_time = 0.5
	battleTimer.start()
	await battleTimer.timeout
	
	update_player_hand()
	update_opponent_hand()
	battleTimer.wait_time = 1
	
	turnNumber += 1
	cardsToDiscard = []
	
	resetTurn()
