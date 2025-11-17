extends Node

const OPPONENT_THINKING_TIME = 1
const END_ROUND_TIME = 1.2
const CARD_MOVE_SPEED = 0.2

const MAX_CHARACTER_CARDS = 4
const MAX_SUPPORT_CARDS = 4

var opponentCharacterCardSlot
var opponentSupportCardSlot

var playerCharacterCard
var playerSupportCard
var opponentCharacterCard
var opponentSupportCard

var turnNumber = 1

enum RoundStage {
	PLAYER_CHARACTER,
	OPPONENT_CHARACTER,
	PLAYER_SUPPORT,
	OPPONENT_SUPPORT,
	END_CALCULATION}

var whoStartedRound
var roundStage: RoundStage

var opponentAI: OpponentAI

var discardedCards = []

func _ready() -> void:
	$"../battleTimer".one_shot = true
	$"../battleTimer".battleTimer.wait_time = OPPONENT_THINKING_TIME
	
	$"../cardManager".connect("characterPlayed", Callable(self, "on_player_character_played"))
	$"../cardManager".connect("supportPlayed", Callable(self, "on_player_support_played"))
	
	hide_end_turn_button()
	
	opponentAI = OpponentAIHighestValue.new()
	
	# Player always starts
	whoStartedRound = "player"
	roundStage = RoundStage.PLAYER_CHARACTER

func resetTurn():
	playerCharacterCard = null
	playerSupportCard = null
	opponentCharacterCard = null
	opponentSupportCard = null
	
	hide_end_turn_button()
	
	if turnNumber % 2 == 0:
		whoStartedRound = "opponent"
	else:
		whoStartedRound = "player"
	
	if whoStartedRound == "opponent":
		opponent_character_turn()

func on_player_character_played(card):
	playerCharacterCard = card
	
	# If the opponent started the round
	if opponentCharacterCard != null:
		init_support_round()
	else:
		roundStage = RoundStage.OPPONENT_CHARACTER
		opponent_character_turn()

func opponent_character_turn():
	await wait_for(OPPONENT_THINKING_TIME)
	
	# Get the card from the AI and play it
	var opponentHand = $"../opponentHand".opponentHand
	var playerHand = $"../playerHand".playerHand
	var card = opponentAI.play_character_card(opponentHand, playerHand)
	
	animate_opponent_playing_card(card, $"../cardSlots/opponentCardSlotCharacter")
	opponentCharacterCard = card
	
	# If the player started the round
	if playerCharacterCard != null:
		show_end_turn_button()
		init_support_round()
	else:
		roundStage = RoundStage.PLAYER_CHARACTER

func init_support_round():
	if whoStartedRound == "player":
		roundStage = RoundStage.PLAYER_SUPPORT
	else:
		roundStage = RoundStage.OPPONENT_SUPPORT
		opponent_support_turn()

func on_player_support_played(card):
	hide_end_turn_button()
	
	playerSupportCard = card
	
	if whoStartedRound == "player":
		opponent_support_turn()
	else:
		# Calculate the reward values (this is where health would be subtracted)
		
		await wait_for(END_ROUND_TIME)
		end_turn()

func opponent_support_turn():
	await wait_for(OPPONENT_THINKING_TIME)
	
	# Get the card from the AI and play it
	var opponentHand = $"../opponentHand".opponentHand
	var card = opponentAI.choose_support_card(opponentHand, opponentCharacterCard, playerCharacterCard)
	
	if card != null:
		animate_opponent_playing_card(card, $"../cardSlots/opponentCardSlotSupport")
		opponentSupportCard = card
	
	if whoStartedRound == "player":
		# Calculate the reward values (this is where health would be subtracted)
		
		await wait_for(END_ROUND_TIME)
		end_turn()
	else:
		# Always give the player the option of playing a support
		roundStage = RoundStage.PLAYER_SUPPORT
		show_end_turn_button()

func end_turn():
	var cardsToDiscard = []
	var playerHand = $"../playerHand".playerHand
	var opponentHand = $"../opponentHand".opponentHand
	
	if playerSupportCard:
		cardsToDiscard.append(playerSupportCard)

	cardsToDiscard.append(playerCharacterCard)
	cardsToDiscard.append(opponentCharacterCard)
	
	if opponentSupportCard:
		cardsToDiscard.append(opponentSupportCard)
	
	await move_cards_to_discard(cardsToDiscard)
	hide_end_turn_button()
	await wait_for(CARD_MOVE_SPEED)
	
	await repopolate_hand(playerHand, "player")
	await repopolate_hand(opponentHand, "opponent")
	
	turnNumber += 1
	cardsToDiscard = []
	
	resetTurn()

func _on_end_turn_button_pressed() -> void:
	hide_end_turn_button()
	
	# If player played support, let the AI choose to play support, otherwise end
	if playerSupportCard == null:
		if opponentSupportCard == null:
			opponent_support_turn()
			return

	await wait_for(END_ROUND_TIME)
	end_turn()

# Helper functions
func wait_for(duration):
	$"../battleTimer".wait_time = duration
	$"../battleTimer".start()
	await $"../battleTimer".timeout

func animate_opponent_playing_card(opponentCard, opponentCardSlot):
	var tween = get_tree().create_tween()
	tween.tween_property(opponentCard, "position", opponentCardSlot.position, CARD_MOVE_SPEED)
	
	# Comment this out when we hide opponent cards
	opponentCard.get_node("AnimationPlayer").play("cardFlip")
	opponentCard.get_node("image").visible = true
	
	$"../opponentHand".remove_card_from_hand(opponentCard)

func show_end_turn_button():
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true

func hide_end_turn_button():
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false

func move_cards_to_discard(cards):
	for card in cards:
		discardedCards.append(card)
		card.scale = Vector2(1, 1)
		
		var tween = get_tree().create_tween()
		tween.tween_property(card, "position", Vector2(150, 280), CARD_MOVE_SPEED)
	
	$"../cardSlots/cardSlotSupport".occupied = false
	$"../cardSlots/cardSlotCharacter".occupied = false

func repopolate_hand(hand, handToUpdate):
	var characterDeckReference = $"../characterDeck"
	var supportDeckReference = $"../supportDeck"
	
	var characterCount = 0
	var supportCount = 0

	for card in hand:
		if card.type == "Character":
			characterCount += 1
		elif card.type == "Support":
			supportCount += 1
	
	while characterCount < MAX_CHARACTER_CARDS:
		if handToUpdate == "player":
			characterDeckReference.draw_card()
		else:
			characterDeckReference.draw_opponent_card()
		
		characterCount += 1
		await wait_for(CARD_MOVE_SPEED)
	
	while supportCount < MAX_SUPPORT_CARDS:
		if handToUpdate == "player":
			supportDeckReference.draw_card()
		else:
			supportDeckReference.draw_opponent_card()
		supportCount += 1
		await wait_for(CARD_MOVE_SPEED)
