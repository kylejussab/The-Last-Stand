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

# Stats for the game
var totalForceExerted = 0
var opponentForceExerted = 0
var highestDamageDealt = 0
var roundWinsUnderdog = 0
var allPlayedCards = []
var startTime
var endTime

@export var whooshSounds = [
	preload("res://assets/sounds/ui/whoosh.wav"),
	preload("res://assets/sounds/ui/whoosh2.wav")
]

func _ready() -> void:
	setupButtonSounds()
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
	
	startTime = Time.get_ticks_msec()

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
		playerTotal += int(playerSupportCard.get_node("value").text)
	
	if opponentSupportCard:
		opponentTotal += int(opponentSupportCard.get_node("value").text)
	
	totalForceExerted += playerTotal
	opponentForceExerted += opponentTotal
	
	allPlayedCards.append({"faction": playerCharacterCard.faction, "cardKey": playerCharacterCard.cardKey})
	
	if highestDamageDealt < playerTotal:
		highestDamageDealt = playerTotal
	
	apply_calculation_round_perks(playerTotal, opponentTotal)
	
	var damage = 0
	
	if playerTotal > opponentTotal:
		var opponentHealth = int($"../arena/opponent/value".text)
		damage = playerTotal - opponentTotal
		
		opponentHealth -= damage
		$"../arena/opponent/value".text = str(opponentHealth)
		
		changeHeadExpression($"../arena/player/head", "happy")
		changeHeadExpression($"../arena/opponent/head", "hurt")
		
		play_damage_sound()
		
		$"../arena/opponent/damage".text = "-" + str(damage)
		$"../arena/opponent/AnimationPlayer".queue("showDamage")
		
		#special case for bloater
		if opponentCharacterCard.cardKey == "Bloater" && opponentCharacterCard.perkValueAtRoundEnd:
			var playerHealth = int($"../arena/player/value".text) - opponentCharacterCard.perkValueAtRoundEnd
			await wait_for(0.5)
			play_damage_sound()
			$"../arena/player/value".text = str(playerHealth)
			$"../arena/player/damage".text = "-" + str(opponentCharacterCard.perkValueAtRoundEnd)
			$"../arena/player/AnimationPlayer".queue("showDamage")
		
		if playerCharacterCard.perkValueAtRoundEnd:
			opponentHealth -= playerCharacterCard.perkValueAtRoundEnd
			await $"../arena/opponent/AnimationPlayer".animation_finished
			await wait_for(0.5)
			play_damage_sound()
			$"../arena/opponent/value".text = str(opponentHealth)
			$"../arena/opponent/damage".text = "-" + str(playerCharacterCard.perkValueAtRoundEnd)
			$"../arena/opponent/AnimationPlayer".queue("showDamage")
		
		# Add to the underdog stat
		if playerCharacterCard.value < opponentCharacterCard.value:
			roundWinsUnderdog += 1
	elif opponentTotal > playerTotal:
		var playerHealth = int($"../arena/player/value".text)
		damage = opponentTotal - playerTotal
		
		playerHealth -= damage
		$"../arena/player/value".text = str(playerHealth)
		
		changeHeadExpression($"../arena/player/head", "hurt")
		changeHeadExpression($"../arena/opponent/head", "happy")
		
		play_damage_sound()
		
		$"../arena/player/damage".text = "-" + str(damage)
		$"../arena/player/AnimationPlayer".queue("showDamage")
		
		#special case for bloater
		if playerCharacterCard.cardKey == "Bloater" && playerCharacterCard.perkValueAtRoundEnd:
			var opponentHealth = int($"../arena/opponent/value".text) - playerCharacterCard.perkValueAtRoundEnd
			await wait_for(0.5)
			play_damage_sound()
			$"../arena/opponent/value".text = str(opponentHealth)
			$"../arena/opponent/damage".text = "-" + str(playerCharacterCard.perkValueAtRoundEnd)
			$"../arena/opponent/AnimationPlayer".queue("showDamage")
		
		if opponentCharacterCard.perkValueAtRoundEnd:
			playerHealth -= opponentCharacterCard.perkValueAtRoundEnd
			await $"../arena/player/AnimationPlayer".animation_finished
			await wait_for(0.5)
			play_damage_sound()
			$"../arena/player/value".text = str(playerHealth)
			$"../arena/player/damage".text = "-" + str(opponentCharacterCard.perkValueAtRoundEnd)
			$"../arena/player/AnimationPlayer".queue("showDamage")
	elif opponentTotal == playerTotal: # Special Case for Lev
		if playerCharacterCard.cardKey == "LevRare":
			var opponentHealth = int($"../arena/opponent/value".text) - playerCharacterCard.perkValueAtRoundEnd
			await wait_for(0.5)
			play_damage_sound()
			$"../arena/opponent/value".text = str(opponentHealth)
			$"../arena/opponent/damage".text = "-" + str(playerCharacterCard.perkValueAtRoundEnd)
			$"../arena/opponent/AnimationPlayer".queue("showDamage")
		if opponentCharacterCard.cardKey == "LevRare":
			var playerHealth = int($"../arena/player/value".text) - opponentCharacterCard.perkValueAtRoundEnd
			await wait_for(0.5)
			play_damage_sound()
			$"../arena/player/value".text = str(playerHealth)
			$"../arena/player/damage".text = "-" + str(opponentCharacterCard.perkValueAtRoundEnd)
			$"../arena/player/AnimationPlayer".queue("showDamage")

func changeHeadExpression(head, expression):
	var states = ["neutral", "thinking", "hurt", "happy"]
	
	for state in states:
		head.get_node(state).visible = (state == expression)

func draw_cards_at_start(firstStart: bool = true):
	if firstStart:
		await $"../characterDeck".ready
		await $"../supportDeck".ready
	
	for i in range(MAX_CHARACTER_CARDS):
		await wait_for(CARD_MOVE_FAST_SPEED)
		$"../characterDeck".draw_card()
		await wait_for(CARD_MOVE_FAST_SPEED)
		$"../characterDeck".draw_opponent_card()
	
	for i in range(MAX_SUPPORT_CARDS):
		await wait_for(CARD_MOVE_FAST_SPEED)
		$"../supportDeck".draw_card()
		await wait_for(CARD_MOVE_FAST_SPEED)
		$"../supportDeck".draw_opponent_card()

func end_round_sequence():
	endTime = Time.get_ticks_msec()
	
	var cardsToDiscard = []
	
	if playerSupportCard:
		cardsToDiscard.append(playerSupportCard)
	
	cardsToDiscard.append(playerCharacterCard)
	cardsToDiscard.append(opponentCharacterCard)
	
	if opponentSupportCard:
		cardsToDiscard.append(opponentSupportCard)
	
	for card in $"../playerHand".playerHand:
		cardsToDiscard.append(card)
	
	for card in $"../opponentHand".opponentHand:
		card.get_node("AnimationPlayer").play("cardFlip")
		card.get_node("image").visible = true
		cardsToDiscard.append(card)
	
	await move_cards_to_discard(cardsToDiscard)
	
	play_game_over_animation()
	
	await repopulate_decks(true)

func play_game_over_animation():
	animate_game_outcome_title(int($"../arena/player/value".text) > int($"../arena/opponent/value".text))
	
	await wait_for(1.5)
	
	animate_game_outcome(int($"../arena/player/value".text) > int($"../arena/opponent/value".text))

func animate_game_outcome_title(playerWon: bool):
	$"../arena/gameOver/overlay".visible = true
	$"../arena/gameOver/title".visible = true
	
	var resultLabel = $"../arena/gameOver/title"
	resultLabel.text = "SURVIVED" if playerWon else "DEFEATED"
	resultLabel.pivot_offset = resultLabel.size / 2
	
	var screenSize = get_viewport().get_visible_rect().size
	resultLabel.global_position = screenSize / 2 - resultLabel.size / 2
	resultLabel.scale = Vector2(2.0, 2.0)
	resultLabel.modulate.a = 0.0
	resultLabel.visible = true
	
	var growTween = create_tween().set_parallel(true)
	growTween.tween_property(resultLabel, "modulate:a", 1.0, 0.5)
	growTween.tween_property(resultLabel, "scale", Vector2(4.0, 4.0), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	$"../arena/gameOver/effects".stream = whooshSounds[0]
	$"../arena/gameOver/effects".play()
	
	var fadeTween = create_tween()
	fadeTween.tween_property(resultLabel, "modulate:a", 1.0, 0.3)
	await fadeTween.finished
	
	var slamTween = create_tween()
	slamTween.tween_property(resultLabel, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	await slamTween.finished

func animate_game_outcome(playerWon: bool):
	var slideTween = create_tween().set_parallel(true)
	var targetPosition = Vector2(150, 80)
	
	$"../arena/gameOver/effects".stream = whooshSounds[1]
	$"../arena/gameOver/effects".play()
	
	slideTween.tween_property($"../arena/gameOver/title", "global_position", targetPosition, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	slideTween.tween_property($"../arena/gameOver/title", "scale", Vector2(1, 1), 0.5)
	
	await slideTween.finished
	
	await wait_for(.3)
	
	animate_game_stats(playerWon)

func animate_game_stats(playerWon: bool):
	set_end_game_stats()
	
	var performanceNode = $"../arena/gameOver/performance"
	var gameNode = $"../arena/gameOver/game"
	var scoreNode = $"../arena/gameOver/score"
	var lineNode = $"../arena/gameOver/line"
	var replayButton = $"../arena/gameOver/ReplayButton"
	replayButton.disabled = true
	var mainMenuButton = $"../arena/gameOver/MainMenuButton"
	mainMenuButton.disabled = true
	var continueButton = $"../arena/gameOver/ContinueButton"
	continueButton.disabled = true
	
	for node in [performanceNode, gameNode, scoreNode, lineNode, replayButton, mainMenuButton, continueButton]:
		node.modulate.a = 0.0
		node.visible = true
	
	performanceNode.position.y += 20
	gameNode.position.y += 20
	scoreNode.position.y += 20
	
	if playerWon:
		# Show the continue button
		replayButton.position.y = 805
		mainMenuButton.position.y = 875
		continueButton.position.y = 945
	else:
		replayButton.position.y = 875
		mainMenuButton.position.y = 945
		continueButton.position.y = 1015

	var uiTween = create_tween()

	$"../arena/gameOver/effects".stream = whooshSounds[1]
	
	uiTween.tween_callback($"../arena/gameOver/effects".play)
	uiTween.tween_property(performanceNode, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	uiTween.parallel().tween_property(performanceNode, "position:y", performanceNode.position.y - 20, 0.8).set_trans(Tween.TRANS_CUBIC)
	uiTween.parallel().tween_property(lineNode, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	
	uiTween.tween_interval(0.3)
	
	uiTween.tween_callback($"../arena/gameOver/effects".play)
	uiTween.tween_property(gameNode, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	uiTween.parallel().tween_property(gameNode, "position:y", gameNode.position.y - 20, 0.8).set_trans(Tween.TRANS_CUBIC)
	
	uiTween.tween_interval(0.3)
	
	uiTween.tween_callback($"../arena/gameOver/effects".play)
	uiTween.tween_property(scoreNode, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	uiTween.parallel().tween_property(scoreNode, "position:y", scoreNode.position.y - 20, 0.8).set_trans(Tween.TRANS_CUBIC)
	
	await uiTween.finished 
	
	var buttonTween = create_tween()
	
	buttonTween.tween_property(replayButton, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	replayButton.disabled = false
	buttonTween.tween_property(mainMenuButton, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	mainMenuButton.disabled = false
	
	if playerWon:
		buttonTween.tween_property(continueButton, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
		continueButton.disabled = false
	
	await buttonTween.finished

func set_end_game_stats():
	# Performance stats
	$"../arena/gameOver/performance/stat1".text = str(totalForceExerted)
	$"../arena/gameOver/performance/stat2".text = str(opponentForceExerted)
	$"../arena/gameOver/performance/stat3".text = str(turnNumber)
	$"../arena/gameOver/performance/stat4".text = format_time(endTime - startTime)
	var dominance = totalForceExerted / float(totalForceExerted + opponentForceExerted)
	var momentum = ((totalForceExerted/float(turnNumber))/7) * dominance * 200 #7 is used as a base "average" value per round
	$"../arena/gameOver/performance/stat5".text = "%.1f%%" % momentum
	
	# Game stats
	var valuableCards = get_card_stats(allPlayedCards)
	$"../arena/gameOver/game/stat1".text = valuableCards["card"]
	$"../arena/gameOver/game/stat2".text = valuableCards["faction"]
	$"../arena/gameOver/game/stat3".text = str(highestDamageDealt)
	$"../arena/gameOver/game/stat4".text = str(roundWinsUnderdog)
	
	# Score stats
	if int($"../arena/player/value".text) > int($"../arena/opponent/value".text):
		$"../arena/gameOver/score/stat1text".text = "Victory"
		var winingBase = 20
		$"../arena/gameOver/score/stat1".text = str(winingBase)
		var force = totalForceExerted - opponentForceExerted
		$"../arena/gameOver/score/stat2".text = str(force)
		var efficiency = (20 - turnNumber) * 5 # 20 as an average number of rounds
		$"../arena/gameOver/score/stat3".text = str(efficiency)
		var underdog = roundWinsUnderdog * 5
		$"../arena/gameOver/score/stat4".text = str(underdog)
		$"../arena/gameOver/score/stat5".text = str(int(momentum))
		# Multiplier
		$"../arena/gameOver/score/stat6".text = "**"
		$"../arena/gameOver/score/stat7".text = str(winingBase + force + efficiency + underdog + int(momentum))
	else:
		$"../arena/gameOver/score/stat1text".text = "Defeat"
		@warning_ignore("integer_division")
		var losingScore = str(int(totalForceExerted) / 10)
		$"../arena/gameOver/score/stat1".text = losingScore
		$"../arena/gameOver/score/stat2".text = "-"
		$"../arena/gameOver/score/stat3".text = "-"
		$"../arena/gameOver/score/stat4".text = "-"
		$"../arena/gameOver/score/stat5".text = "-"
		$"../arena/gameOver/score/stat6".text = "**"
		$"../arena/gameOver/score/stat7".text = losingScore

func format_time(time: float) -> String:
	var totalSeconds = int(time / 1000.0)
	@warning_ignore("integer_division")
	var minutes = totalSeconds / 60
	var seconds = totalSeconds % 60
	return "%02d:%02d" % [minutes, seconds]

func get_card_stats(playedCards):
	var factionCounts = {}
	var cardCounts = {}

	for card in playedCards:
		var faction = card["faction"]
		var mvp = card["cardKey"]
		
		factionCounts[faction] = factionCounts.get(faction, 0) + 1
		cardCounts[mvp] = cardCounts.get(mvp, 0) + 1
		
	var topFaction = "None"
	var highestFactionCount = 0
	
	for faction in factionCounts:
		if factionCounts[faction] > highestFactionCount:
			highestFactionCount = factionCounts[faction]
			topFaction = faction
	
	var cardKey = "None"
	var highestCharacterCount = 0
	
	for card in cardCounts:
		if cardCounts[card] > highestCharacterCount:
			highestCharacterCount = cardCounts[card]
			cardKey = card
	
	var cardName = ""
	
	for i in range(cardKey.length()):
		var letter = cardKey[i]
		if i > 0 and letter == letter.to_upper():
			cardName += " "
		cardName += letter
	
	return {"faction": topFaction, "card": cardName}

func _on_replay_button_pressed() -> void:
	$"../arena/fade".modulate.a = 0.0
	$"../arena/fade".visible = true
	
	var fadeInTween = create_tween()
	fadeInTween.tween_property($"../arena/fade", "modulate:a", 1.0, .5)
	await fadeInTween.finished
	
	resetArenaValues()
	
	setupArena("June", "Ethan")
	
	changeHeadExpression($"../arena/player/head", "neutral")
	changeHeadExpression($"../arena/opponent/head", "neutral")
	
	$"../arena/gameOver/overlay".visible = false
	$"../arena/gameOver/title".visible = false
	$"../arena/gameOver/line".visible = false
	$"../arena/gameOver/performance".visible = false
	$"../arena/gameOver/game".visible = false
	$"../arena/gameOver/score".visible = false
	$"../arena/gameOver/ReplayButton".visible = false
	$"../arena/gameOver/ReplayButton".disabled = true
	$"../arena/gameOver/MainMenuButton".visible = false
	$"../arena/gameOver/MainMenuButton".disabled = true
	$"../arena/gameOver/ContinueButton".visible = false
	$"../arena/gameOver/ContinueButton".disabled = true
	
	await wait_for(1)
	
	var fadeOutTween = create_tween()
	fadeOutTween.tween_property($"../arena/fade", "modulate:a", 0, .5)
	await fadeOutTween.finished
	$"../arena/fade".visible = false
	
	await draw_cards_at_start(false)
	
	# Player always starts
	whoStartedRound = "player"
	roundStage = RoundStage.PLAYER_CHARACTER
	$"../arena/player/indicator".visible = true
	$"../arena/opponent/indicator".visible = false
	changeHeadExpression($"../arena/player/head", "thinking")
	changeHeadExpression($"../arena/opponent/head", "neutral")
	
	lockPlayerInput = false
	
	startTime = Time.get_ticks_msec()

func resetArenaValues():
	lockPlayerInput = true
	hide_end_turn_button()
	
	turnNumber = 1
	totalForceExerted = 0
	opponentForceExerted = 0
	highestDamageDealt = 0
	roundWinsUnderdog = 0
	allPlayedCards = []
	
	$"../playerHand".playerHand = []
	$"../opponentHand".opponentHand = []

func setupButtonSounds():
	for button in $"../arena/gameOver".get_children():
		if button is Button:
			button.mouse_entered.connect(_play_hover)
			button.pressed.connect(_play_click)

func _play_hover():
	$"../arena/ButtonHoverSound".play()

func _play_click():
	$"../arena/ButtonClickSound".play()

func play_damage_sound():
	$"../arena/damageSound".play()
