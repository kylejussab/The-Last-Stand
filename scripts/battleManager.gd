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
var discardedCardZIndex = 1

var showOpponentsCards = false

@onready var ui = %arena
@onready var battleAnimator = %battleAnimator

func _ready() -> void:
	$"../battleTimer".one_shot = true
	$"../battleTimer".wait_time = OPPONENT_THINKING_TIME
	
	$"../cardManager".connect("characterPlayed", Callable(self, "on_player_character_played"))
	$"../cardManager".connect("supportPlayed", Callable(self, "on_player_support_played"))
	
	# For now forcing it to start with Ethan, but it shouldn't
	GameStats.currentPlayer = Actor.Avatar.JUNE
	GameStats.currentOpponent = Actor.Avatar.ETHAN
	GameStats.playerHealthValue = 100
	
	ui.update_health(Actor.Type.PLAYER, GameStats.playerHealthValue, true)
	setupArena(GameStats.currentPlayer, GameStats.currentOpponent)
	
	await draw_cards_at_start()
	
	ui.set_indicator(Actor.Type.PLAYER)
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
	roundStage = RoundStage.PLAYER_CHARACTER
	lockPlayerInput = false
	GameStats.set_start_time()

func setupArena(player, opponent):
	ui.setup_avatar(player, Actor.Type.PLAYER)
	
	# We assign different Ais here when they are made
	match opponent:
		Actor.Avatar.ETHAN:
			ui.setup_avatar(opponent, Actor.Type.OPPONENT)
			opponentAI = OpponentAIHighestValue.new()
		Actor.Avatar.SILAS:
			ui.setup_avatar(opponent, Actor.Type.OPPONENT)
			opponentAI = OpponentAIHighestValue.new()
		Actor.Avatar.MIRA:
			ui.setup_avatar(opponent, Actor.Type.OPPONENT)
			opponentAI = OpponentAIHighestValue.new()
		Actor.Avatar.KAEL:
			ui.setup_avatar(opponent, Actor.Type.OPPONENT)
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
	
	if GameStats.roundNumber % 2 == 0:
		whoStartedRound = "opponent"
		
		ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.THINKING)
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)
		opponent_character_turn()
	else:
		whoStartedRound = "player"
		
		ui.set_indicator(Actor.Type.PLAYER)
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
		ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
		
		lockPlayerInput = false

func on_player_character_played(card):
	playerCharacterCard = card
	
	# If the opponent started the round
	if opponentCharacterCard != null:
		init_support_round()
	else:
		roundStage = RoundStage.OPPONENT_CHARACTER
		opponent_character_turn()
	
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)

func opponent_character_turn():
	ui.set_indicator(Actor.Type.OPPONENT)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.THINKING)
	lockPlayerInput = true
	await wait_for(OPPONENT_THINKING_TIME)
	
	# Get the card from the AI and play it
	var opponentHand = $"../opponentHand".opponentHand
	var playerHand = $"../playerHand".playerHand
	var card = opponentAI.play_character_card(opponentHand, playerHand)
	
	await animate_opponent_playing_card(card, $"../cardSlots/opponentCardSlotCharacter")
	opponentCharacterCard = card
	
	ui.set_indicator(Actor.Type.PLAYER)
	
	# If the player started the round
	if playerCharacterCard != null:
		ui.show_end_turn_button()
		init_support_round()
	else:
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
		lockPlayerInput = false
		roundStage = RoundStage.PLAYER_CHARACTER
	
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)

func init_support_round():
	lockPlayerInput = false
	
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
	
	apply_mid_round_perks()
	allow_support_cards()
	
	if whoStartedRound == "player":
		roundStage = RoundStage.PLAYER_SUPPORT
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
	else:
		roundStage = RoundStage.OPPONENT_SUPPORT
		ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.THINKING)
		opponent_support_turn()

func on_player_support_played(card):
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)
	
	ui.show_end_turn_button(false)
	
	playerSupportCard = card
	
	if whoStartedRound == "player":
		opponent_support_turn()
	else:
		ui.set_indicator(Actor.Type.NONE)
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)
		await apply_end_round_perks()
		end_turn()

func opponent_support_turn():
	ui.set_indicator(Actor.Type.OPPONENT)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.THINKING)
	
	lockPlayerInput = true
	await wait_for(OPPONENT_THINKING_TIME)
	
	# Get the card from the AI and play it
	var opponentHand = $"../opponentHand".opponentHand
	var card = opponentAI.choose_support_card(opponentHand, opponentCharacterCard, playerCharacterCard)
	
	if card != null:
		animate_opponent_playing_card(card, $"../cardSlots/opponentCardSlotSupport")
		opponentSupportCard = card
	
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
	
	if whoStartedRound == "player":
		ui.set_indicator(Actor.Type.NONE)
		await apply_end_round_perks()
		end_turn()
	else:
		# Always give the player the option of playing a support
		ui.set_indicator(Actor.Type.PLAYER)
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
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
	var playerHealth = ui.get_health(Actor.Type.PLAYER)
	var opponentHealth = ui.get_health(Actor.Type.OPPONENT)
	
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
	
	GameStats.roundNumber += 1
	cardsToDiscard = []
	
	resetTurn()

func _on_end_turn_button_pressed() -> void:
	ui.show_end_turn_button(false)
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)
	
	# If player played support, let the AI choose to play support, otherwise end
	if !opponentPlayedSupport:
		opponent_support_turn()
		return

	ui.set_indicator(Actor.Type.NONE)
	await apply_end_round_perks()
	end_turn()

# Helper functions
func wait_for(duration):
	$"../battleTimer".wait_time = duration
	$"../battleTimer".start()
	await $"../battleTimer".timeout

func animate_opponent_playing_card(opponentCard, opponentCardSlot):
	opponentCard.play_draw_sound()
	
	opponentCard.get_node("AnimationPlayer").play("cardFlip")
	
	var tween = get_tree().create_tween()
	tween.finished.connect(func(): opponentCard.play_draw_sound())
	tween.tween_property(opponentCard, "position", opponentCardSlot.position, CARD_MOVE_SPEED)
	
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
		await wait_for(1)
		await opponentCharacterCard.perk.apply_mid_perk(opponentCharacterCard, $"../opponentHand".opponentHand, playerCharacterCard)
	
	# Handle the runner perk
	_handle_runner_perk()

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
		
		card.z_index = discardedCardZIndex
		discardedCardZIndex += 1
		var tween = get_tree().create_tween()
		tween.finished.connect(func(): card.play_draw_sound())
		tween.tween_property(card, "position", DISCARD_PILE_POSITION, CARD_MOVE_FAST_SPEED)
		
		await tween.finished
	
	$"../cardSlots/cardSlotSupport".occupied = false
	$"../cardSlots/cardSlotCharacter".occupied = false

func repopolate_hand(hand, handToUpdate):
	lockPlayerInput = true
	
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
	
	lockPlayerInput = false

func repopulate_decks(endGame: bool = false):
	var discardedCharacters := []
	var discardedSupports := []
	
	for card in discardedCards:
		if card.type == "Character":
			discardedCharacters.append(card)
		elif card.type == "Support":
			discardedSupports.append(card)
	
	var discardedCharactersReversed = discardedCharacters.duplicate()
	var discardedSupportsReversed = discardedSupports.duplicate()
	discardedCharactersReversed.reverse()
	discardedSupportsReversed.reverse()
	
	if endGame:
		discardedCards = discardedCharactersReversed + discardedSupportsReversed
		
		for i in range(discardedSupportsReversed.size()):
			discardedSupportsReversed[i].z_index = 100 - i
		
		await $"../supportDeck".reshuffle_from_discards(discardedSupportsReversed)
		for card in discardedSupportsReversed:
			discardedCards.erase(card)
			
		await $"../characterDeck".reshuffle_from_discards(discardedCharactersReversed)
		for card in discardedCharactersReversed:
			discardedCards.erase(card)
		
		return
	
	if $"../supportDeck".deck.size() < MIN_CARDS_FOR_RESHUFFLE:
		discardedCards = discardedCharactersReversed + discardedSupportsReversed
		
		for i in range(discardedSupportsReversed.size()):
			discardedSupportsReversed[i].z_index = 100 - i
		
		await $"../supportDeck".reshuffle_from_discards(discardedSupportsReversed)
		for card in discardedSupportsReversed:
			discardedCards.erase(card)
		
		return
	
	if $"../characterDeck".deck.size() < MIN_CARDS_FOR_RESHUFFLE:
		discardedCards = discardedSupportsReversed + discardedCharactersReversed
		
		for i in range(discardedCharactersReversed.size()):
			discardedCharactersReversed[i].z_index = 100 - i
		
		await $"../characterDeck".reshuffle_from_discards(discardedCharactersReversed)
		for card in discardedCharactersReversed:
			discardedCards.erase(card)
		
		return

func calculate_damage():
	var playerTotal = int(playerCharacterCard.get_node("value").text)
	var opponentTotal = int(opponentCharacterCard.get_node("value").text)
	
	if playerSupportCard:
		playerTotal += int(playerSupportCard.get_node("value").text)
	
	if opponentSupportCard:
		opponentTotal += int(opponentSupportCard.get_node("value").text)
	
	GameStats.totalForceExerted += playerTotal
	GameStats.opponentForceExerted += opponentTotal
	
	GameStats.allPlayedCards.append({"faction": playerCharacterCard.faction, "cardKey": playerCharacterCard.cardKey})
	
	if GameStats.highestDamageDealt < playerTotal:
		GameStats.highestDamageDealt = playerTotal
	
	apply_calculation_round_perks(playerTotal, opponentTotal)
	
	var damage = 0
	
	if playerTotal > opponentTotal:
		var opponentHealth = ui.get_health(Actor.Type.OPPONENT)
		damage = playerTotal - opponentTotal
		
		opponentHealth -= damage
		ui.update_health(Actor.Type.OPPONENT, opponentHealth)
		
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.HAPPY)
		ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.HURT)
		
		await ui.play_damage_effect(Actor.Type.OPPONENT, damage)
		
		#special case for bloater
		if opponentCharacterCard.cardKey == "Bloater" && opponentCharacterCard.perkValueAtRoundEnd:
			var playerHealth = ui.get_health(Actor.Type.PLAYER) - opponentCharacterCard.perkValueAtRoundEnd
			await wait_for(0.5)
			
			ui.update_health(Actor.Type.PLAYER, playerHealth)
			await ui.play_damage_effect(Actor.Type.PLAYER, opponentCharacterCard.perkValueAtRoundEnd)
		
		if playerCharacterCard.perkValueAtRoundEnd:
			opponentHealth -= playerCharacterCard.perkValueAtRoundEnd
			await wait_for(0.5)
			
			ui.update_health(Actor.Type.OPPONENT, opponentHealth)
			await ui.play_damage_effect(Actor.Type.OPPONENT, playerCharacterCard.perkValueAtRoundEnd)
		
		# Add to the underdog stat
		if playerCharacterCard.value < opponentCharacterCard.value:
			GameStats.roundWinsUnderdog += 1
	elif opponentTotal > playerTotal:
		var playerHealth = ui.get_health(Actor.Type.PLAYER)
		damage = opponentTotal - playerTotal
		
		playerHealth -= damage
		ui.update_health(Actor.Type.PLAYER, playerHealth)
		
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.HURT)
		ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.HAPPY)
		
		await ui.play_damage_effect(Actor.Type.PLAYER, damage)
		
		#special case for bloater
		if playerCharacterCard.cardKey == "Bloater" && playerCharacterCard.perkValueAtRoundEnd:
			var opponentHealth = ui.get_health(Actor.Type.OPPONENT) - playerCharacterCard.perkValueAtRoundEnd
			await wait_for(0.5)
			
			ui.update_health(Actor.Type.OPPONENT, opponentHealth)
			await ui.play_damage_effect(Actor.Type.OPPONENT, playerCharacterCard.perkValueAtRoundEnd)
		
		if opponentCharacterCard.perkValueAtRoundEnd:
			playerHealth -= opponentCharacterCard.perkValueAtRoundEnd
			
			await wait_for(0.5)
			
			ui.update_health(Actor.Type.PLAYER, playerHealth)
			await ui.play_damage_effect(Actor.Type.PLAYER, opponentCharacterCard.perkValueAtRoundEnd)
	
	elif opponentTotal == playerTotal: # Special Case for Lev
		if playerCharacterCard.cardKey == "Lev":
			var opponentHealth = ui.get_health(Actor.Type.OPPONENT) - playerCharacterCard.perkValueAtRoundEnd
			await wait_for(0.5)
			
			ui.update_health(Actor.Type.OPPONENT, opponentHealth)
			await ui.play_damage_effect(Actor.Type.OPPONENT, playerCharacterCard.perkValueAtRoundEnd)
		if opponentCharacterCard.cardKey == "Lev":
			var playerHealth = ui.get_health(Actor.Type.PLAYER) - opponentCharacterCard.perkValueAtRoundEnd
			await wait_for(0.5)
			
			ui.update_health(Actor.Type.PLAYER, playerHealth)
			await ui.play_damage_effect(Actor.Type.PLAYER, opponentCharacterCard.perkValueAtRoundEnd)

func draw_cards_at_start(firstStart: bool = true):
	if firstStart:
		await $"../characterDeck".ready
		await $"../supportDeck".ready
		await get_tree().create_timer(.5).timeout
	
	GameStats.gameMode = "Card Draw Animation"
	
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
	
	GameStats.gameMode = "Last Stand"

func end_round_sequence():
	GameStats.set_end_time()
	GameStats.gameMode = "Last Stand Round Complete"
	GameStats.totalInGameTimePlayed += GameStats.currentRoundDuration
	$"../pauseIcon".hide()
	
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
	
	battleAnimator.play_game_over_sequence(ui.get_health(Actor.Type.PLAYER) > ui.get_health(Actor.Type.OPPONENT))
	
	await repopulate_decks(true)
	
	discardedCardZIndex = 1

func resetArena():
	$"../pauseIcon".show()
	
	await draw_cards_at_start(false)
	
	# Player always starts
	whoStartedRound = "player"
	roundStage = RoundStage.PLAYER_CHARACTER
	
	ui.set_indicator(Actor.Type.PLAYER)
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
	
	lockPlayerInput = false
	
	GameStats.set_start_time()

func place_card_in_discard(card, hand):
	discardedCards.append(card)
	card.play_draw_sound()
	card.scale = Vector2(1, 1)
	
	card.z_index = discardedCardZIndex
	discardedCardZIndex += 1
	var tween = get_tree().create_tween()
	tween.finished.connect(func(): card.play_draw_sound())
	tween.tween_property(card, "position", DISCARD_PILE_POSITION, CARD_MOVE_FAST_SPEED)
	
	await tween.finished
	
	hand.remove_card_from_hand(card)

func _handle_runner_perk() -> void:
	if playerCharacterCard.cardKey == "Runner" or opponentCharacterCard.cardKey == "Runner":
		var runnerCards = []
		
		if playerCharacterCard.cardKey == "Runner":
			for card in %playerHand.playerHand:
				if card.cardKey == "Runner":
					runnerCards.append(card)
					card.disable_interaction()
			
			for card in runnerCards:
				await place_card_in_discard(card, %playerHand)
		
		if opponentCharacterCard.cardKey == "Runner":
			for card in %opponentHand.opponentHand:
				if card.cardKey == "Runner":
					runnerCards.append(card)
			
			for card in runnerCards:
				card.get_node("AnimationPlayer").play("cardFlip")
				await place_card_in_discard(card, %opponentHand)
