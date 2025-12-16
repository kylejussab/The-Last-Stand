extends Node

const OPPONENT_THINKING_TIME = 1
const END_ROUND_TIME = 1.2
const CARD_MOVE_SPEED = 0.2
const CARD_MOVE_FAST_SPEED = 0.15

const DISCARD_PILE_POSITION = Vector2(135, 300)

const MAX_CHARACTER_CARDS = 4
const MAX_SUPPORT_CARDS = 4

const MIN_CARDS_FOR_RESHUFFLE = 3

var opponentCharacterCardSlot
var opponentSupportCardSlot

var playerCharacterCard
var playerSupportCard
var opponentCharacterCard
var opponentSupportCard

var opponentPlayedSupport = false

var lockPlayerInput = true

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

var showOpponentsCards = false

func _ready() -> void:
	lockPlayerInput = true
	
	$"../battleTimer".one_shot = true
	$"../battleTimer".wait_time = OPPONENT_THINKING_TIME
	
	$"../cardManager".connect("characterPlayed", Callable(self, "on_player_character_played"))
	$"../cardManager".connect("supportPlayed", Callable(self, "on_player_support_played"))
	
	hide_end_turn_button()
	
	# Changing the opponent will change the arena
	setupArena("June", "Ethan")
	
	await draw_cards_at_start()
	
	# Player always starts
	whoStartedRound = "player"
	roundStage = RoundStage.PLAYER_CHARACTER
	$"../arena/player/indicator".visible = true
	$"../arena/opponent/indicator".visible = false
	changeHeadExpression($"../arena/player/head", "thinking")
	changeHeadExpression($"../arena/opponent/head", "neutral")
	
	lockPlayerInput = false

func setupArena(player, opponent):
	match player:
		"June":
			$"../arena/player/name".text = "June Ravel"
			$"../arena/player/description".text = "Former Firefly"
			$"../arena/player/value".text = "35"
			
			$"../arena/player/head".get_node("neutral").texture = load("res://assets/arenaHeads/JuneNeutral.png")
			$"../arena/player/head".get_node("hurt").texture = load("res://assets/arenaHeads/JuneHurt.png")
			$"../arena/player/head".get_node("thinking").texture = load("res://assets/arenaHeads/JuneThinking.png")
			$"../arena/player/head".get_node("happy").texture = load("res://assets/arenaHeads/JuneHappy.png")
	
	match opponent:
		"Ethan":
			$"../arena/image".texture = load("res://assets/arenas/EthanArena.png")
			
			$"../arena/opponent/name".text = "Ethan Hark"
			$"../arena/opponent/description".text = "Patrol Leader"
			$"../arena/opponent/value".text = "35"
			# For now the opponent gets assigned June heads
			$"../arena/opponent/head".get_node("neutral").texture = load("res://assets/arenaHeads/JuneNeutral.png")
			$"../arena/opponent/head".get_node("hurt").texture = load("res://assets/arenaHeads/JuneHurt.png")
			$"../arena/opponent/head".get_node("thinking").texture = load("res://assets/arenaHeads/JuneThinking.png")
			$"../arena/opponent/head".get_node("happy").texture = load("res://assets/arenaHeads/JuneHappy.png")
			opponentAI = OpponentAIHighestValue.new()

func resetTurn():
	playerCharacterCard = null
	playerSupportCard = null
	opponentCharacterCard = null
	opponentSupportCard = null
	
	opponentPlayedSupport = false
	
	hide_end_turn_button()
	
	# Shuffle cards from discard back into decks if needed
	await repopulate_decks()
	
	if turnNumber % 2 == 0:
		whoStartedRound = "opponent"
	else:
		whoStartedRound = "player"
		$"../arena/player/indicator".visible = true
		$"../arena/opponent/indicator".visible = false
		lockPlayerInput = false
		changeHeadExpression($"../arena/player/head", "thinking")
		changeHeadExpression($"../arena/opponent/head", "neutral")
	
	if whoStartedRound == "opponent":
		changeHeadExpression($"../arena/player/head", "neutral")
		changeHeadExpression($"../arena/opponent/head", "thinking")
		opponent_character_turn()

func on_player_character_played(card):
	playerCharacterCard = card
	
	# If the opponent started the round
	if opponentCharacterCard != null:
		init_support_round()
	else:
		roundStage = RoundStage.OPPONENT_CHARACTER
		opponent_character_turn()
	
	changeHeadExpression($"../arena/player/head", "neutral")

func opponent_character_turn():
	$"../arena/player/indicator".visible = false
	$"../arena/opponent/indicator".visible = true
	changeHeadExpression($"../arena/opponent/head", "thinking")
	lockPlayerInput = true
	await wait_for(OPPONENT_THINKING_TIME)
	
	# Get the card from the AI and play it
	var opponentHand = $"../opponentHand".opponentHand
	var playerHand = $"../playerHand".playerHand
	var card = opponentAI.play_character_card(opponentHand, playerHand)
	
	await animate_opponent_playing_card(card, $"../cardSlots/opponentCardSlotCharacter")
	opponentCharacterCard = card
	
	$"../arena/player/indicator".visible = true
	$"../arena/opponent/indicator".visible = false
	# If the player started the round
	if playerCharacterCard != null:
		show_end_turn_button()
		init_support_round()
	else:
		lockPlayerInput = false
		roundStage = RoundStage.PLAYER_CHARACTER
		changeHeadExpression($"../arena/player/head", "thinking")
	
	changeHeadExpression($"../arena/opponent/head", "neutral")

func init_support_round():
	lockPlayerInput = false
	changeHeadExpression($"../arena/player/head", "neutral")
	changeHeadExpression($"../arena/opponent/head", "neutral")
	
	apply_mid_round_perks()
	allow_support_cards()
	
	if whoStartedRound == "player":
		roundStage = RoundStage.PLAYER_SUPPORT
		changeHeadExpression($"../arena/player/head", "thinking")
	else:
		roundStage = RoundStage.OPPONENT_SUPPORT
		changeHeadExpression($"../arena/opponent/head", "thinking")
		opponent_support_turn()

func on_player_support_played(card):
	changeHeadExpression($"../arena/player/head", "neutral")
	
	hide_end_turn_button()
	
	playerSupportCard = card
	
	if whoStartedRound == "player":
		opponent_support_turn()
	else:
		# Calculate the reward values (this is where health would be subtracted)
		
		$"../arena/player/indicator".visible = false
		$"../arena/opponent/indicator".visible = false
		changeHeadExpression($"../arena/player/head", "neutral")
		await apply_end_round_perks()
		end_turn()

func opponent_support_turn():
	$"../arena/player/indicator".visible = false
	$"../arena/opponent/indicator".visible = true
	changeHeadExpression($"../arena/opponent/head", "thinking")
	lockPlayerInput = true
	await wait_for(OPPONENT_THINKING_TIME)
	
	# Get the card from the AI and play it
	var opponentHand = $"../opponentHand".opponentHand
	var card = opponentAI.choose_support_card(opponentHand, opponentCharacterCard, playerCharacterCard)
	
	if card != null:
		animate_opponent_playing_card(card, $"../cardSlots/opponentCardSlotSupport")
		opponentSupportCard = card
	
	changeHeadExpression($"../arena/opponent/head", "neutral")
	
	if whoStartedRound == "player":
		# Calculate the reward values (this is where health would be subtracted)
		
		$"../arena/player/indicator".visible = false
		$"../arena/opponent/indicator".visible = false
		await apply_end_round_perks()
		end_turn()
	else:
		# Always give the player the option of playing a support
		$"../arena/player/indicator".visible = true
		$"../arena/opponent/indicator".visible = false
		changeHeadExpression($"../arena/player/head", "thinking")
		lockPlayerInput = false
		roundStage = RoundStage.PLAYER_SUPPORT
		show_end_turn_button()
	
	opponentPlayedSupport = true

func end_turn():
	roundStage = RoundStage.END_CALCULATION
	# Apply any perks and do the calculation
	await calculate_damage()
	await wait_for(END_ROUND_TIME)
	
	# Check for game over first
	var playerHealth = int($"../arena/player/value".text)
	var opponentHealth = int($"../arena/opponent/value".text)
	
	if playerHealth <= 0 or opponentHealth <= 0:
		await end_round_sequence()
		return
	
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
	
	await repopolate_hand(playerHand, "player")
	await repopolate_hand(opponentHand, "opponent")
	
	turnNumber += 1
	cardsToDiscard = []
	
	resetTurn()

func _on_end_turn_button_pressed() -> void:
	hide_end_turn_button()
	changeHeadExpression($"../arena/player/head", "neutral")
	
	# If player played support, let the AI choose to play support, otherwise end
	if !opponentPlayedSupport:
		opponent_support_turn()
		return

	$"../arena/player/indicator".visible = false
	$"../arena/opponent/indicator".visible = false
	await apply_end_round_perks()
	end_turn()

# Helper functions
func wait_for(duration):
	$"../battleTimer".wait_time = duration
	$"../battleTimer".start()
	await $"../battleTimer".timeout

func animate_opponent_playing_card(opponentCard, opponentCardSlot):
	opponentCard.play_draw_sound()
	var tween = get_tree().create_tween()
	tween.finished.connect(func(): opponentCard.play_draw_sound())
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

func allow_support_cards():
	var playerCharacterCardRoles = playerCharacterCard.role.split("/")
	for card in $"../playerHand".playerHand:
		if card.type == "Support":
			var playerSupportCardRoles = card.role.split("/")
			for role in playerCharacterCardRoles:
				if role in playerSupportCardRoles:
					card.canBePlayed = true
	
	var opponentCharacterCardRoles = opponentCharacterCard.role.split("/")
	for card in $"../opponentHand".opponentHand:
		if card.type == "Support":
			var opponentSupportCardRoles = card.role.split("/")
			for role in opponentCharacterCardRoles:
				if role in opponentSupportCardRoles:
					card.canBePlayed = true

func reset_allowed_support_cards():
	if playerSupportCard:
		playerSupportCard.canBePlayed = false
	
	for card in $"../playerHand".playerHand:
		if card.type == "Support":
			card.canBePlayed = false
	
	if opponentSupportCard:
		opponentSupportCard.canBePlayed = false
	
	for card in $"../opponentHand".opponentHand:
		if card.type == "Support":
			card.canBePlayed = false

func apply_mid_round_perks():
	if playerCharacterCard.perk && playerCharacterCard.perk.timing == "midRound":
		await wait_for(1)
		await playerCharacterCard.perk.apply_mid_perk(playerCharacterCard, $"../playerHand".playerHand, opponentCharacterCard)
	
	if opponentCharacterCard.perk && opponentCharacterCard.perk.timing == "midRound":
		await opponentCharacterCard.perk.apply_mid_perk(opponentCharacterCard, $"../opponentHand".opponentHand, playerCharacterCard)

func apply_end_round_perks():
	# For now its just characters and characters happen AFTER support
	if playerCharacterCard.perk && playerCharacterCard.perk.timing == "endRound":
		await playerCharacterCard.perk.apply_end_perk(playerCharacterCard, playerSupportCard, opponentCharacterCard, opponentSupportCard, $"../playerHand".playerHand)
	
	if opponentCharacterCard.perk && opponentCharacterCard.perk.timing == "endRound":
		await opponentCharacterCard.perk.apply_end_perk(opponentCharacterCard, opponentSupportCard, playerCharacterCard, playerSupportCard, $"../opponentHand".opponentHand)
	
	# Check for the supply cache
	if playerSupportCard && playerSupportCard.perk && playerSupportCard.perk.timing == "endRound":
		await playerSupportCard.perk.apply_end_perk(playerCharacterCard, playerSupportCard, opponentCharacterCard, opponentSupportCard, $"../playerHand".playerHand)
	
	if opponentSupportCard && opponentSupportCard.perk && opponentSupportCard.perk.timing == "endRound":
		await opponentSupportCard.perk.apply_end_perk(opponentCharacterCard, opponentSupportCard, playerCharacterCard, playerSupportCard, $"../opponentHand".opponentHand)
	
	await wait_for(1)

func apply_calculation_round_perks(playerTotal, opponentTotal):
	if playerCharacterCard.perk && playerCharacterCard.perk.timing == "calculationRound":
		await playerCharacterCard.perk.apply_after_calculation_perk(playerCharacterCard, $"../playerHand".playerHand, playerTotal, opponentTotal)
	
	if opponentCharacterCard.perk && opponentCharacterCard.perk.timing == "calculationRound":
		await opponentCharacterCard.perk.apply_after_calculation_perk(opponentCharacterCard, $"../opponentHand".opponentHand, opponentTotal, playerTotal)

func reset_played_cards_perks():
	if playerCharacterCard.perk:
		playerCharacterCard.get_node("value").text = str(playerCharacterCard.value)
	
	if opponentCharacterCard.perk:
		opponentCharacterCard.get_node("value").text = str(opponentCharacterCard.value)

func move_cards_to_discard(cards):
	reset_played_cards_perks()
	reset_allowed_support_cards()
	
	for card in cards:
		discardedCards.append(card)
		card.play_draw_sound()
		card.scale = Vector2(1, 1)
		
		var tween = get_tree().create_tween()
		tween.finished.connect(func(): card.play_draw_sound())
		tween.tween_property(card, "position", DISCARD_PILE_POSITION, CARD_MOVE_FAST_SPEED)
		
		await tween.finished
	
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

func repopulate_decks(endGame: bool = false):
	var discardedCharacters := []
	var discardedSupports := []

	for card in discardedCards:
		if card.type == "Character":
			discardedCharacters.append(card)
		elif card.type == "Support":
			discardedSupports.append(card)

	if endGame or $"../characterDeck".deck.size() < MIN_CARDS_FOR_RESHUFFLE:
		await $"../characterDeck".reshuffle_from_discards(discardedCharacters)
		for card in discardedCharacters:
			discardedCards.erase(card)

	if endGame or $"../supportDeck".deck.size() < MIN_CARDS_FOR_RESHUFFLE:
		await $"../supportDeck".reshuffle_from_discards(discardedSupports)
		for card in discardedSupports:
			discardedCards.erase(card)

func calculate_damage():
	var playerTotal = int(playerCharacterCard.get_node("value").text)
	var opponentTotal = int(opponentCharacterCard.get_node("value").text)
	
	if playerSupportCard:
		playerTotal += playerSupportCard.value
	
	if opponentSupportCard:
		opponentTotal += opponentSupportCard.value
	
	apply_calculation_round_perks(playerTotal, opponentTotal)
	
	var damage = 0
	
	if playerTotal > opponentTotal:
		var opponentHealth = int($"../arena/opponent/value".text)
		damage = playerTotal - opponentTotal
		
		opponentHealth -= damage
		$"../arena/opponent/value".text = str(opponentHealth)
		
		changeHeadExpression($"../arena/player/head", "happy")
		changeHeadExpression($"../arena/opponent/head", "hurt")
		
		$"../arena/opponent/damage".text = "-" + str(damage)
		$"../arena/opponent/AnimationPlayer".queue("showDamage")
		
		#special case for bloater
		if opponentCharacterCard.cardKey == "Bloater" && opponentCharacterCard.perkValueAtRoundEnd:
			var playerHealth = int($"../arena/player/value".text) - opponentCharacterCard.perkValueAtRoundEnd
			await wait_for(0.5)
			$"../arena/player/value".text = str(playerHealth)
			$"../arena/player/damage".text = "-" + str(opponentCharacterCard.perkValueAtRoundEnd)
			$"../arena/player/AnimationPlayer".queue("showDamage")
		
		if playerCharacterCard.perkValueAtRoundEnd:
			opponentHealth -= playerCharacterCard.perkValueAtRoundEnd
			await $"../arena/opponent/AnimationPlayer".animation_finished
			await wait_for(0.5)
			
			$"../arena/opponent/value".text = str(opponentHealth)
			$"../arena/opponent/damage".text = "-" + str(playerCharacterCard.perkValueAtRoundEnd)
			$"../arena/opponent/AnimationPlayer".queue("showDamage")
	elif opponentTotal > playerTotal:
		var playerHealth = int($"../arena/player/value".text)
		damage = opponentTotal - playerTotal
		
		playerHealth -= damage
		$"../arena/player/value".text = str(playerHealth)
		
		changeHeadExpression($"../arena/player/head", "hurt")
		changeHeadExpression($"../arena/opponent/head", "happy")
		
		$"../arena/player/damage".text = "-" + str(damage)
		$"../arena/player/AnimationPlayer".queue("showDamage")
		
		#special case for bloater
		if playerCharacterCard.cardKey == "Bloater" && playerCharacterCard.perkValueAtRoundEnd:
			var opponentHealth = int($"../arena/opponent/value".text) - playerCharacterCard.perkValueAtRoundEnd
			await wait_for(0.5)
			$"../arena/opponent/value".text = str(opponentHealth)
			$"../arena/opponent/damage".text = "-" + str(playerCharacterCard.perkValueAtRoundEnd)
			$"../arena/opponent/AnimationPlayer".queue("showDamage")
		
		if opponentCharacterCard.perkValueAtRoundEnd:
			playerHealth -= opponentCharacterCard.perkValueAtRoundEnd
			await $"../arena/player/AnimationPlayer".animation_finished
			await wait_for(0.5)
			
			$"../arena/player/value".text = str(playerHealth)
			$"../arena/player/damage".text = "-" + str(opponentCharacterCard.perkValueAtRoundEnd)
			$"../arena/player/AnimationPlayer".queue("showDamage")
	elif opponentTotal == playerTotal: # Special Case for Lev
		if playerCharacterCard.cardKey == "LevRare":
			var opponentHealth = int($"../arena/opponent/value".text) - playerCharacterCard.perkValueAtRoundEnd
			await wait_for(0.5)
			$"../arena/opponent/value".text = str(opponentHealth)
			$"../arena/opponent/damage".text = "-" + str(playerCharacterCard.perkValueAtRoundEnd)
			$"../arena/opponent/AnimationPlayer".queue("showDamage")
		if opponentCharacterCard.cardKey == "LevRare":
			var playerHealth = int($"../arena/player/value".text) - opponentCharacterCard.perkValueAtRoundEnd
			await wait_for(0.5)
			$"../arena/player/value".text = str(playerHealth)
			$"../arena/player/damage".text = "-" + str(opponentCharacterCard.perkValueAtRoundEnd)
			$"../arena/player/AnimationPlayer".queue("showDamage")

func changeHeadExpression(head, expression):
	var states = ["neutral", "thinking", "hurt", "happy"]
	
	for state in states:
		head.get_node(state).visible = (state == expression)

func draw_cards_at_start():
	await $"../characterDeck".ready
	await $"../supportDeck".ready
	
	for i in range(4):
		await wait_for(CARD_MOVE_FAST_SPEED)
		$"../characterDeck".draw_card()
		await wait_for(CARD_MOVE_FAST_SPEED)
		$"../characterDeck".draw_opponent_card()
	
	for i in range(4):
		await wait_for(CARD_MOVE_FAST_SPEED)
		$"../supportDeck".draw_card()
		await wait_for(CARD_MOVE_FAST_SPEED)
		$"../supportDeck".draw_opponent_card()

func end_round_sequence():
	var cardsToDiscard = []
	
	if playerSupportCard:
		cardsToDiscard.append(playerSupportCard)
	
	cardsToDiscard.append(playerCharacterCard)
	cardsToDiscard.append(opponentCharacterCard)
	
	if opponentSupportCard:
		cardsToDiscard.append(opponentSupportCard)
	
	for card in $"../opponentHand".opponentHand:
		cardsToDiscard.append(card)
	
	for card in $"../playerHand".playerHand:
		cardsToDiscard.append(card)
	
	await move_cards_to_discard(cardsToDiscard)
	
	# Do the overlay of the game information somewhere here
	
	await repopulate_decks(true)
