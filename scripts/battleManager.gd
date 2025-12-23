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

enum RoundStage {
	PLAYER_CHARACTER,
	OPPONENT_CHARACTER,
	PLAYER_SUPPORT,
	OPPONENT_SUPPORT,
	END_CALCULATION}

var whoStartedRound: String = "player"
var roundStage: RoundStage

var opponentAI: OpponentAI

var discardedCards = []

var showOpponentsCards = false

@onready var stats = %gameStats
@onready var ui = %arena

@export var whooshSounds = [
	preload("res://assets/sounds/ui/whoosh.wav"),
	preload("res://assets/sounds/ui/whoosh2.wav")
]

func _ready() -> void:
	setupButtonSounds()
	
	$"../battleTimer".one_shot = true
	$"../battleTimer".wait_time = OPPONENT_THINKING_TIME
	
	$"../cardManager".connect("characterPlayed", Callable(self, "on_player_character_played"))
	$"../cardManager".connect("supportPlayed", Callable(self, "on_player_support_played"))
	
	setupArena("June", "Ethan")
	
	await draw_cards_at_start()
	
	# Player always starts
	ui.set_indicator("player")
	ui.change_expression("player", "thinking")
	ui.change_expression("opponent", "neutral")
	roundStage = RoundStage.PLAYER_CHARACTER
	
	lockPlayerInput = false
	
	stats.set_start_time()

func setupArena(player, opponent):
	match player:
		"June":
			ui.setup_character("June", true)
	match opponent:
		"Ethan":
			ui.setup_character("Ethan", false)
			opponentAI = OpponentAIHighestValue.new()

func resetTurn():
	playerCharacterCard = null
	playerSupportCard = null
	opponentCharacterCard = null
	opponentSupportCard = null
	
	opponentPlayedSupport = false
	
	ui.show_end_turn_button(false)
	
	# Shuffle cards from discard back into decks if needed
	await repopulate_decks()
	
	if stats.roundNumber % 2 == 0:
		whoStartedRound = "opponent"
		
		ui.change_expression("opponent", "thinking")
		ui.change_expression("player", "neutral")
		opponent_character_turn()
	else:
		whoStartedRound = "player"
		
		ui.set_indicator("player")
		ui.change_expression("player", "thinking")
		ui.change_expression("opponent", "neutral")
		
		lockPlayerInput = false

func on_player_character_played(card):
	playerCharacterCard = card
	
	# If the opponent started the round
	if opponentCharacterCard != null:
		init_support_round()
	else:
		roundStage = RoundStage.OPPONENT_CHARACTER
		opponent_character_turn()
	
	ui.change_expression("player", "neutral")

func opponent_character_turn():
	ui.set_indicator("opponent")
	ui.change_expression("opponent", "thinking")
	lockPlayerInput = true
	await wait_for(OPPONENT_THINKING_TIME)
	
	# Get the card from the AI and play it
	var opponentHand = $"../opponentHand".opponentHand
	var playerHand = $"../playerHand".playerHand
	var card = opponentAI.play_character_card(opponentHand, playerHand)
	
	await animate_opponent_playing_card(card, $"../cardSlots/opponentCardSlotCharacter")
	opponentCharacterCard = card
	
	ui.set_indicator("player")
	
	# If the player started the round
	if playerCharacterCard != null:
		ui.show_end_turn_button()
		init_support_round()
	else:
		ui.change_expression("player", "thinking")
		lockPlayerInput = false
		roundStage = RoundStage.PLAYER_CHARACTER
	
	ui.change_expression("opponent", "neutral")

func init_support_round():
	lockPlayerInput = false
	
	ui.change_expression("player", "neutral")
	ui.change_expression("opponent", "neutral")
	
	apply_mid_round_perks()
	allow_support_cards()
	
	if whoStartedRound == "player":
		roundStage = RoundStage.PLAYER_SUPPORT
		ui.change_expression("player", "thinking")
	else:
		roundStage = RoundStage.OPPONENT_SUPPORT
		ui.change_expression("opponent", "thinking")
		opponent_support_turn()

func on_player_support_played(card):
	ui.change_expression("player", "neutral")
	
	ui.show_end_turn_button(false)
	
	playerSupportCard = card
	
	if whoStartedRound == "player":
		opponent_support_turn()
	else:
		ui.set_indicator("none")
		ui.change_expression("player", "neutral")
		await apply_end_round_perks()
		end_turn()

func opponent_support_turn():
	ui.set_indicator("opponent")
	ui.change_expression("opponent", "thinking")
	
	lockPlayerInput = true
	await wait_for(OPPONENT_THINKING_TIME)
	
	# Get the card from the AI and play it
	var opponentHand = $"../opponentHand".opponentHand
	var card = opponentAI.choose_support_card(opponentHand, opponentCharacterCard, playerCharacterCard)
	
	if card != null:
		animate_opponent_playing_card(card, $"../cardSlots/opponentCardSlotSupport")
		opponentSupportCard = card
	
	ui.change_expression("opponent", "neutral")
	
	if whoStartedRound == "player":
		ui.set_indicator("none")
		await apply_end_round_perks()
		end_turn()
	else:
		# Always give the player the option of playing a support
		ui.set_indicator("player")
		ui.change_expression("player", "thinking")
		lockPlayerInput = false
		roundStage = RoundStage.PLAYER_SUPPORT
		ui.show_end_turn_button()
	
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
	ui.show_end_turn_button(false)
	
	await repopolate_hand(playerHand, "player")
	await repopolate_hand(opponentHand, "opponent")
	
	stats.roundNumber += 1
	cardsToDiscard = []
	
	resetTurn()

func _on_end_turn_button_pressed() -> void:
	ui.show_end_turn_button(false)
	ui.change_expression("player", "neutral")
	
	# If player played support, let the AI choose to play support, otherwise end
	if !opponentPlayedSupport:
		opponent_support_turn()
		return

	ui.set_indicator("none")
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
	
	stats.totalForceExerted += playerTotal
	stats.opponentForceExerted += opponentTotal
	
	stats.allPlayedCards.append({"faction": playerCharacterCard.faction, "cardKey": playerCharacterCard.cardKey})
	
	if stats.highestDamageDealt < playerTotal:
		stats.highestDamageDealt = playerTotal
	
	apply_calculation_round_perks(playerTotal, opponentTotal)
	
	var damage = 0
	
	if playerTotal > opponentTotal:
		var opponentHealth = ui.get_health("opponent")
		damage = playerTotal - opponentTotal
		
		opponentHealth -= damage
		ui.set_health("opponent", opponentHealth)
		
		ui.change_expression("player", "happy")
		ui.change_expression("opponent", "hurt")
		
		play_damage_sound()
		await ui.show_damage("opponent", damage)
		
		#special case for bloater
		if opponentCharacterCard.cardKey == "Bloater" && opponentCharacterCard.perkValueAtRoundEnd:
			var playerHealth = ui.get_health("player") - opponentCharacterCard.perkValueAtRoundEnd
			await wait_for(0.5)
			
			play_damage_sound()
			ui.set_health("player", playerHealth)
			await ui.show_damage("player", opponentCharacterCard.perkValueAtRoundEnd)
		
		if playerCharacterCard.perkValueAtRoundEnd:
			opponentHealth -= playerCharacterCard.perkValueAtRoundEnd
			await wait_for(0.5)
			
			play_damage_sound()
			ui.set_health("opponent", opponentHealth)
			await ui.show_damage("opponent", playerCharacterCard.perkValueAtRoundEnd)
		
		# Add to the underdog stat
		if playerCharacterCard.value < opponentCharacterCard.value:
			stats.roundWinsUnderdog += 1
	elif opponentTotal > playerTotal:
		var playerHealth = ui.get_health("player")
		damage = opponentTotal - playerTotal
		
		playerHealth -= damage
		ui.set_health("player", playerHealth)
		
		ui.change_expression("player", "hurt")
		ui.change_expression("opponent", "happy")
		
		play_damage_sound()
		await ui.show_damage("player", damage)
		
		#special case for bloater
		if playerCharacterCard.cardKey == "Bloater" && playerCharacterCard.perkValueAtRoundEnd:
			var opponentHealth = ui.get_health("opponent") - playerCharacterCard.perkValueAtRoundEnd
			await wait_for(0.5)
			
			play_damage_sound()
			ui.set_health("opponent", opponentHealth)
			await ui.show_damage("opponent", playerCharacterCard.perkValueAtRoundEnd)
		
		if opponentCharacterCard.perkValueAtRoundEnd:
			playerHealth -= opponentCharacterCard.perkValueAtRoundEnd
			
			await wait_for(0.5)
			play_damage_sound()
			
			ui.set_health("player", playerHealth)
			await ui.show_damage("player", opponentCharacterCard.perkValueAtRoundEnd)
			
	elif opponentTotal == playerTotal: # Special Case for Lev
		if playerCharacterCard.cardKey == "LevRare":
			var opponentHealth = ui.get_health("opponent") - playerCharacterCard.perkValueAtRoundEnd
			await wait_for(0.5)
			play_damage_sound()
			
			ui.set_health("opponent", opponentHealth)
			await ui.show_damage("opponent", playerCharacterCard.perkValueAtRoundEnd)
		if opponentCharacterCard.cardKey == "LevRare":
			var playerHealth = ui.get_health("player") - opponentCharacterCard.perkValueAtRoundEnd
			await wait_for(0.5)
			play_damage_sound()
			
			ui.set_health("player", playerHealth)
			await ui.show_damage("player", opponentCharacterCard.perkValueAtRoundEnd)

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
	stats.set_end_time()
	
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
	animate_game_outcome_title(ui.get_health("player") > ui.get_health("opponent"))
	
	await wait_for(1.5)
	
	animate_game_outcome(ui.get_health("player") > ui.get_health("opponent"))

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
	$"../arena/gameOver/performance/stat1".text = str(stats.totalForceExerted)
	$"../arena/gameOver/performance/stat2".text = str(stats.opponentForceExerted)
	$"../arena/gameOver/performance/stat3".text = str(stats.roundNumber)
	$"../arena/gameOver/performance/stat4".text = format_time(stats.endTime - stats.startTime)
	var dominance = stats.totalForceExerted / float(stats.totalForceExerted + stats.opponentForceExerted)
	var momentum = ((stats.totalForceExerted/float(stats.roundNumber))/7) * dominance * 200 #7 is used as a base "average" value per round
	$"../arena/gameOver/performance/stat5".text = "%.1f%%" % momentum
	
	# Game stats
	var valuableCards = get_card_stats(stats.allPlayedCards)
	$"../arena/gameOver/game/stat1".text = valuableCards["card"]
	$"../arena/gameOver/game/stat2".text = valuableCards["faction"]
	$"../arena/gameOver/game/stat3".text = str(stats.highestDamageDealt)
	$"../arena/gameOver/game/stat4".text = str(stats.roundWinsUnderdog)
	
	# Score stats
	if int($"../arena/player/value".text) > int($"../arena/opponent/value".text):
		$"../arena/gameOver/score/stat1text".text = "Victory"
		var winingBase = 20
		$"../arena/gameOver/score/stat1".text = str(winingBase)
		var force = stats.totalForceExerted - stats.opponentForceExerted
		$"../arena/gameOver/score/stat2".text = str(force)
		var efficiency = (20 - stats.roundNumber) * 5 # 20 as an average number of rounds
		$"../arena/gameOver/score/stat3".text = str(efficiency)
		var underdog = stats.roundWinsUnderdog * 5
		$"../arena/gameOver/score/stat4".text = str(underdog)
		$"../arena/gameOver/score/stat5".text = str(int(momentum))
		# Multiplier
		$"../arena/gameOver/score/stat6".text = "**"
		$"../arena/gameOver/score/stat7".text = str(winingBase + force + efficiency + underdog + int(momentum))
	else:
		$"../arena/gameOver/score/stat1text".text = "Defeat"
		@warning_ignore("integer_division")
		var losingScore = str(int(stats.totalForceExerted) / 10)
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
	
	ui.change_expression("player", "neutral")
	ui.change_expression("opponent", "neutral")
	
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
	
	ui.set_indicator("player")
	ui.change_expression("player", "thinking")
	ui.change_expression("opponent", "neutral")
	
	lockPlayerInput = false
	
	stats.set_start_time()

func resetArenaValues():
	lockPlayerInput = true
	ui.show_end_turn_button(false)
	
	stats.reset_round_stats()
	
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
