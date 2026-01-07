extends Node

const PERK_CALCULATION_TIME: float = 1.0
const PERK_CALCULATION_TIME_AFTER_ROUND_END: float = 0.5
const OPPONENT_THINKING_TIME: float = 1.0
const END_ROUND_TIME: float = 1.2
const CARD_MOVE_SPEED: float = 0.2
const CARD_MOVE_FAST_SPEED: float = 0.15

const DISCARD_PILE_POSITION: Vector2 = Vector2(135, 292)

const MINIMUM_CARDS_FOR_RESHUFFLE: int = 3

var maximumCharacterCardsInHand: int = 4
var maximumSupportCardsInHand: int = 4

@onready var opponentCharacterCardSlot: Node2D = %opponentCardSlotCharacter
@onready var opponentSupportCardSlot: Node2D = %opponentCardSlotSupport
@onready var playerHand: Array = %playerHand.playerHand
@onready var opponentHand: Array = %opponentHand.opponentHand

var playerCharacterCard: Node2D
var playerSupportCard: Node2D
var opponentCharacterCard: Node2D
var opponentSupportCard: Node2D

var opponentPlayedSupport: bool = false
var lockPlayerInput: bool = true

enum RoundStage { PLAYER_CHARACTER, OPPONENT_CHARACTER, PLAYER_SUPPORT, OPPONENT_SUPPORT, END_CALCULATION }

var whoStartedRound: Actor.Type = Actor.Type.PLAYER
var roundStage: RoundStage

var opponentAI: OpponentAI

var discardedCards: Array = []
var discardedCardZIndex: int = 1

@onready var ui: Node2D = %arena
@onready var battleAnimator: Node = %battleAnimator

#Debug variable [also delete the check in opponentHand.gd when done]
var showOpponentsCards: bool = false

func _ready() -> void:
	randomize() # Resets the seed
	
	$"../battleTimer".wait_time = OPPONENT_THINKING_TIME
	$"../cardManager".connect("characterPlayed", Callable(self, "_on_player_character_played"))
	$"../cardManager".connect("supportPlayed", Callable(self, "_on_player_support_played"))
	
	match GameStats.gameMode:
		GameStats.Mode.JUNE_RAVEL:
			GameStats.currentPlayer = Actor.Avatar.JUNE
			GameStats.playerHealthValue = Database.AVATARS[Actor.Avatar.JUNE].health
		
		GameStats.Mode.LAST_STAND:
			# Maybe there should be an avatar thats always used for Last Stand
			GameStats.currentPlayer = Actor.Avatar.JUNE
			GameStats.playerHealthValue = 99 
	
	ui.update_health(Actor.Type.PLAYER, GameStats.playerHealthValue, true)
	
	start_new_match()

func start_new_match() -> void:
	if not GameStats.replayedRound:
		GameStats.currentOpponent = _pick_next_opponent()
	
	_initialize_opponent(GameStats.currentPlayer, GameStats.currentOpponent)
	
	await _initialize_game()

# Privates
func _initialize_game() -> void:
	%pauseIcon.show()
	
	await _draw_cards_at_start(false)
	
	whoStartedRound = Actor.Type.PLAYER
	roundStage = RoundStage.PLAYER_CHARACTER
	
	ui.set_indicator(Actor.Type.PLAYER)
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
	
	lockPlayerInput = false
	GameStats.set_start_time()

func _initialize_opponent(player: Actor.Avatar, opponent: Actor.Avatar) -> void:
	ui.setup_avatar(player, Actor.Type.PLAYER)
	
	# We assign different Ais here when they are made
	match opponent:
		Actor.Avatar.ETHAN:
			ui.setup_avatar(opponent, Actor.Type.OPPONENT)
			opponentAI = OpponentAIHighestValue.new()
		Actor.Avatar.RHEA:
			ui.setup_avatar(opponent, Actor.Type.OPPONENT)
			opponentAI = OpponentAIHighestValue.new()
		Actor.Avatar.UCKMANN:
			ui.setup_avatar(opponent, Actor.Type.OPPONENT)
			opponentAI = OpponentAIHighestValue.new()
		Actor.Avatar.ALLEY:
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

func _on_player_character_played(card: Node2D) -> void:
	playerCharacterCard = card
	
	# If the opponent started the round
	if opponentCharacterCard != null:
		_apply_mid_round_perks()
		_transition_to_support_phase()
	else:
		roundStage = RoundStage.OPPONENT_CHARACTER
		_execute_opponent_character_play()
	
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)

func _execute_opponent_character_play() -> void:
	ui.set_indicator(Actor.Type.OPPONENT)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.THINKING)
	lockPlayerInput = true
	await get_tree().create_timer(OPPONENT_THINKING_TIME).timeout
	
	var card = opponentAI.play_character_card(opponentHand, playerHand)
	card.cardSlot = opponentCharacterCardSlot
	
	_animate_opponent_playing_card(card, opponentCharacterCardSlot)
	opponentCharacterCard = card
	
	ui.set_indicator(Actor.Type.PLAYER)
	
	# If the player started the round
	if playerCharacterCard != null:
		ui.show_end_turn_button()
		_apply_mid_round_perks()
		_transition_to_support_phase()
	else:
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
		lockPlayerInput = false
		roundStage = RoundStage.PLAYER_CHARACTER
	
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)

func _transition_to_support_phase() -> void:
	lockPlayerInput = false
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
	
	_update_playable_support_cards()
	
	if whoStartedRound == Actor.Type.PLAYER:
		roundStage = RoundStage.PLAYER_SUPPORT
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
	else:
		roundStage = RoundStage.OPPONENT_SUPPORT
		ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.THINKING)
		_execute_opponent_support_play()

func _on_player_support_played(card: Node2D) -> void:
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)
	
	ui.show_end_turn_button(false)
	
	playerSupportCard = card
	
	if whoStartedRound == Actor.Type.PLAYER:
		_execute_opponent_support_play()
	else:
		ui.set_indicator(Actor.Type.NONE)
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)
		await _apply_end_round_perks()
		_transition_to_resolution_phase()

func _execute_opponent_support_play() -> void:
	ui.set_indicator(Actor.Type.OPPONENT)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.THINKING)
	
	lockPlayerInput = true
	
	await get_tree().create_timer(OPPONENT_THINKING_TIME).timeout
	
	var card = opponentAI.choose_support_card(opponentHand, opponentCharacterCard, playerCharacterCard)
	
	if card != null:
		card.cardSlot = opponentSupportCardSlot
		_animate_opponent_playing_card(card, opponentSupportCardSlot)
		opponentSupportCard = card
	
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
	
	if whoStartedRound == Actor.Type.PLAYER:
		ui.set_indicator(Actor.Type.NONE)
		await _apply_end_round_perks()
		_transition_to_resolution_phase()
	else:
		# Always give the player the option of playing a support
		ui.set_indicator(Actor.Type.PLAYER)
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
		lockPlayerInput = false
		roundStage = RoundStage.PLAYER_SUPPORT
		ui.show_end_turn_button()
	
	opponentPlayedSupport = true

func _transition_to_resolution_phase() -> void:
	roundStage = RoundStage.END_CALCULATION
	await _calculate_damage()
	await get_tree().create_timer(END_ROUND_TIME).timeout
	
	# Check for game over first
	var playerHealth = ui.get_health(Actor.Type.PLAYER)
	var opponentHealth = ui.get_health(Actor.Type.OPPONENT)
	
	if playerHealth <= 0 or opponentHealth <= 0:
		await _conclude_match()
		return
	
	var cardsToDiscard = []
	
	if playerSupportCard:
		cardsToDiscard.append(playerSupportCard)

	cardsToDiscard.append(playerCharacterCard)
	cardsToDiscard.append(opponentCharacterCard)
	
	if opponentSupportCard:
		cardsToDiscard.append(opponentSupportCard)
	
	await _move_cards_to_discard(cardsToDiscard)
	ui.show_end_turn_button(false)
	
	await _repopulate_hand(playerHand, Actor.Type.PLAYER)
	await _repopulate_hand(opponentHand, Actor.Type.OPPONENT)
	
	GameStats.roundNumber += 1
	cardsToDiscard = []
	
	_start_new_round()

func _conclude_match() -> void:
	GameStats.set_end_time()
	GameStats.gameMode = GameStats.Mode.LAST_STAND_ROUND_COMPLETED
	GameStats.totalInGameTimePlayed += GameStats.currentRoundDuration
	%pauseIcon.hide()
	
	var cardsToDiscard = []
	
	if playerSupportCard: cardsToDiscard.append(playerSupportCard)
	cardsToDiscard.append(playerCharacterCard)
	cardsToDiscard.append(opponentCharacterCard)
	if opponentSupportCard: cardsToDiscard.append(opponentSupportCard)
	
	cardsToDiscard.append_array(playerHand)
	
	for card in opponentHand:
		card.get_node("AnimationPlayer").play("cardFlip")
		card.get_node("image").visible = true
		cardsToDiscard.append(card)
	
	await _move_cards_to_discard(cardsToDiscard)
	
	battleAnimator.play_game_over_sequence(ui.get_health(Actor.Type.PLAYER) > 0)
	
	await _repopulate_decks(true)
	
	discardedCardZIndex = 1

func _start_new_round() -> void:
	playerCharacterCard = null
	playerSupportCard = null
	opponentCharacterCard = null
	opponentSupportCard = null
	
	opponentPlayedSupport = false
	
	ui.show_end_turn_button(false)
	
	# Shuffle cards from discard back into decks if needed
	await _repopulate_decks()
	
	if GameStats.roundNumber % 2 == 0:
		whoStartedRound = Actor.Type.OPPONENT
		
		ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.THINKING)
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)
		_execute_opponent_character_play()
	else:
		whoStartedRound = Actor.Type.PLAYER
		
		ui.set_indicator(Actor.Type.PLAYER)
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
		ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
		
		lockPlayerInput = false

func _on_end_turn_button_pressed() -> void:
	ui.show_end_turn_button(false)
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)
	
	if !opponentPlayedSupport:
		_execute_opponent_support_play()
		return

	ui.set_indicator(Actor.Type.NONE)
	await _apply_end_round_perks()
	_transition_to_resolution_phase()

# Helpers
func _draw_cards_at_start(firstStart: bool = true) -> void:
	%pauseIcon.hide()
	
	if firstStart:
		await $"../characterDeck".ready
		await $"../supportDeck".ready
		await get_tree().create_timer(.5).timeout
	
	GameStats.gameMode = GameStats.Mode.CARD_DRAW
	
	for i in range(maximumCharacterCardsInHand):
		await get_tree().create_timer(CARD_MOVE_FAST_SPEED).timeout
		$"../characterDeck".draw_card()
		await get_tree().create_timer(CARD_MOVE_FAST_SPEED).timeout
		$"../characterDeck".draw_opponent_card()
	
	for i in range(maximumSupportCardsInHand):
		await get_tree().create_timer(CARD_MOVE_FAST_SPEED).timeout
		$"../supportDeck".draw_card()
		await get_tree().create_timer(CARD_MOVE_FAST_SPEED).timeout
		$"../supportDeck".draw_opponent_card()
	
	GameStats.gameMode = GameStats.Mode.LAST_STAND
	
	%pauseIcon.show()

func _pick_next_opponent() -> Actor.Avatar:
	if GameStats.opponentList.is_empty():
		match GameStats.gameMode:
			GameStats.Mode.JUNE_RAVEL:
				GameStats.opponentList = Database.JUNE_OPPONENTS.duplicate()
			GameStats.Mode.LAST_STAND:
				var list = Database.AVATARS.keys()
				
				if GameStats.currentPlayer in list:
					list.erase(GameStats.currentPlayer)
				
				list.shuffle()
				
				if GameStats.currentOpponent in list and list.size() > 1:
					if list[0] == GameStats.currentOpponent:
						var temp = list[0]
						list[0] = list[1]
						list[1] = temp
				
				GameStats.opponentList = list
	
	return GameStats.opponentList.pop_front()

func _animate_opponent_playing_card(opponentCard: Node2D, opponentCardSlot: Node2D) -> void:
	opponentCard.play_draw_sound()
	opponentCard.get_node("Area2D/CollisionShape2D").disabled = false
	
	opponentCard.get_node("AnimationPlayer").play("cardFlip")
	
	var tween = get_tree().create_tween()
	tween.finished.connect(func(): opponentCard.play_draw_sound())
	tween.tween_property(opponentCard, "position", opponentCardSlot.position, CARD_MOVE_SPEED)
	
	$"../opponentHand".remove_card_from_hand(opponentCard)

func _apply_mid_round_perks() -> void:
	if playerCharacterCard.perk && playerCharacterCard.perk.timing == "midRound":
		await get_tree().create_timer(PERK_CALCULATION_TIME).timeout
		await playerCharacterCard.perk.apply_mid_perk(playerCharacterCard, playerHand, opponentCharacterCard)
	
	if opponentCharacterCard.perk && opponentCharacterCard.perk.timing == "midRound":
		await get_tree().create_timer(PERK_CALCULATION_TIME).timeout
		await opponentCharacterCard.perk.apply_mid_perk(opponentCharacterCard, opponentHand, playerCharacterCard)
	
	# Handle the runner perk
	_handle_runner_perk()

func _update_playable_support_cards() -> void:
	var playerCharacterCardRoles = playerCharacterCard.role.split("/")
	for card in playerHand:
		if card.type == "Support":
			var playerSupportCardRoles = card.role.split("/")
			for role in playerCharacterCardRoles:
				if role in playerSupportCardRoles:
					card.canBePlayed = true
	
	var opponentCharacterCardRoles = opponentCharacterCard.role.split("/")
	for card in opponentHand:
		if card.type == "Support":
			var opponentSupportCardRoles = card.role.split("/")
			for role in opponentCharacterCardRoles:
				if role in opponentSupportCardRoles:
					card.canBePlayed = true

func _apply_end_round_perks() -> void:
	if playerCharacterCard.perk && playerCharacterCard.perk.timing == "endRound":
		await playerCharacterCard.perk.apply_end_perk(playerCharacterCard, playerSupportCard, opponentCharacterCard, opponentSupportCard, playerHand)
	
	if opponentCharacterCard.perk && opponentCharacterCard.perk.timing == "endRound":
		await opponentCharacterCard.perk.apply_end_perk(opponentCharacterCard, opponentSupportCard, playerCharacterCard, playerSupportCard, opponentHand)
	
	# Check for the supply cache
	if playerSupportCard && playerSupportCard.perk && playerSupportCard.perk.timing == "endRound":
		await playerSupportCard.perk.apply_end_perk(playerCharacterCard, playerSupportCard, opponentCharacterCard, opponentSupportCard, playerHand)
	
	if opponentSupportCard && opponentSupportCard.perk && opponentSupportCard.perk.timing == "endRound":
		await opponentSupportCard.perk.apply_end_perk(opponentCharacterCard, opponentSupportCard, playerCharacterCard, playerSupportCard, opponentHand)
	
	await get_tree().create_timer(PERK_CALCULATION_TIME).timeout

func _calculate_damage() -> void:
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
	
	_apply_calculation_round_perks(playerTotal, opponentTotal)
	
	if playerTotal > opponentTotal:
		await _handle_player_win(playerTotal, opponentTotal)
	elif opponentTotal > playerTotal:
		await _handle_opponent_win(playerTotal, opponentTotal)
	elif opponentTotal == playerTotal:
		await _handle_lev_perk()

func _apply_calculation_round_perks(playerTotal: int, opponentTotal: int) -> void:
	if playerCharacterCard.perk && playerCharacterCard.perk.timing == "calculationRound":
		await playerCharacterCard.perk.apply_after_calculation_perk(playerCharacterCard, playerHand, playerTotal, opponentTotal)
	
	if opponentCharacterCard.perk && opponentCharacterCard.perk.timing == "calculationRound":
		await opponentCharacterCard.perk.apply_after_calculation_perk(opponentCharacterCard, opponentHand, opponentTotal, playerTotal)

func _move_cards_to_discard(cards: Array) -> void:
	_reset_played_cards_perks()
	_reset_allowed_support_cards()
	
	for card in cards:
		discardedCards.append(card)
		card.play_draw_sound()
		card.scale = Vector2(1, 1)
		card.get_node("Area2D/CollisionShape2D").disabled = true
		
		card.z_index = discardedCardZIndex
		discardedCardZIndex += 1
		var tween = get_tree().create_tween()
		tween.finished.connect(func(): card.play_draw_sound())
		tween.tween_property(card, "position", DISCARD_PILE_POSITION, CARD_MOVE_FAST_SPEED)
		
		await tween.finished
	
	$"../cardSlots/cardSlotSupport".occupied = false
	$"../cardSlots/cardSlotCharacter".occupied = false

func _reset_played_cards_perks() -> void:
	if playerCharacterCard.perk:
		playerCharacterCard.get_node("value").text = str(playerCharacterCard.value)
	
	if opponentCharacterCard.perk:
		opponentCharacterCard.get_node("value").text = str(opponentCharacterCard.value)

func _reset_allowed_support_cards() -> void:
	if playerSupportCard:
		playerSupportCard.canBePlayed = false
	
	for card in playerHand:
		if card.type == "Support":
			card.canBePlayed = false
	
	if opponentSupportCard:
		opponentSupportCard.canBePlayed = false
	
	for card in opponentHand:
		if card.type == "Support":
			card.canBePlayed = false

func _repopulate_hand(hand: Array, who: Actor.Type) -> void:
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
	
	while characterCount < maximumCharacterCardsInHand:
		if who == Actor.Type.PLAYER:
			characterDeckReference.draw_card()
		else:
			characterDeckReference.draw_opponent_card()
		
		characterCount += 1
		await get_tree().create_timer(CARD_MOVE_SPEED).timeout
	
	while supportCount < maximumSupportCardsInHand:
		if who == Actor.Type.PLAYER:
			supportDeckReference.draw_card()
		else:
			supportDeckReference.draw_opponent_card()
		supportCount += 1
		await get_tree().create_timer(CARD_MOVE_SPEED).timeout
	
	lockPlayerInput = false

func _repopulate_decks(endGame: bool = false) -> void:
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
	
	if $"../supportDeck".deck.size() < MINIMUM_CARDS_FOR_RESHUFFLE:
		discardedCards = discardedCharactersReversed + discardedSupportsReversed
		
		for i in range(discardedSupportsReversed.size()):
			discardedSupportsReversed[i].z_index = 100 - i
		
		$"../supportDeck".reshuffle_from_discards(discardedSupportsReversed)
		for card in discardedSupportsReversed:
			discardedCards.erase(card)
		
		return
	
	if $"../characterDeck".deck.size() < MINIMUM_CARDS_FOR_RESHUFFLE:
		discardedCards = discardedSupportsReversed + discardedCharactersReversed
		
		for i in range(discardedCharactersReversed.size()):
			discardedCharactersReversed[i].z_index = 100 - i
		
		$"../characterDeck".reshuffle_from_discards(discardedCharactersReversed)
		for card in discardedCharactersReversed:
			discardedCards.erase(card)
		
		return

func _place_card_in_discard(card: Node2D, hand: Node2D) -> void:
	discardedCards.append(card)
	card.play_draw_sound()
	card.scale = Vector2(1, 1)
	card.get_node("Area2D/CollisionShape2D").disabled = true
	
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
			for card in playerHand:
				if card.cardKey == "Runner":
					runnerCards.append(card)
					card.disable_interaction()
			
			for card in runnerCards:
				await _place_card_in_discard(card, %playerHand)
		
		if opponentCharacterCard.cardKey == "Runner":
			for card in opponentHand:
				if card.cardKey == "Runner":
					runnerCards.append(card)
			
			for card in runnerCards:
				card.get_node("AnimationPlayer").play("cardFlip")
				await _place_card_in_discard(card, %opponentHand)

func _handle_player_win(playerTotal: int, opponentTotal: int) -> void:
	var damage = playerTotal - opponentTotal
	
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.HAPPY)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.HURT)
	
	await _deal_damage(Actor.Type.OPPONENT, damage, false)
	
	await _handle_bloater_perk(Actor.Type.PLAYER)
	
	if playerCharacterCard.perkValueAtRoundEnd: # Any non-special perks that need triggering on round end
		await _deal_damage(Actor.Type.OPPONENT, playerCharacterCard.perkValueAtRoundEnd)

	if playerCharacterCard.value < opponentCharacterCard.value:
		GameStats.roundWinsUnderdog += 1

func _handle_opponent_win(playerTotal: int, opponentTotal: int) -> void:
	var damage = opponentTotal - playerTotal
	
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.HURT)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.HAPPY)
	
	await _deal_damage(Actor.Type.PLAYER, damage, false)
	
	await _handle_bloater_perk(Actor.Type.OPPONENT)
	
	if opponentCharacterCard.perkValueAtRoundEnd: # Any non-special perks that need triggering on round end
		await _deal_damage(Actor.Type.PLAYER, opponentCharacterCard.perkValueAtRoundEnd)

func _handle_bloater_perk(winner: Actor.Type) -> void:
	if winner == Actor.Type.PLAYER:
		if opponentCharacterCard.cardKey == "Bloater" and opponentCharacterCard.perkValueAtRoundEnd:
			await _deal_damage(Actor.Type.PLAYER, opponentCharacterCard.perkValueAtRoundEnd)
	elif winner == Actor.Type.OPPONENT:
		if playerCharacterCard.cardKey == "Bloater" and playerCharacterCard.perkValueAtRoundEnd:
			await _deal_damage(Actor.Type.OPPONENT, playerCharacterCard.perkValueAtRoundEnd)

func _handle_lev_perk() -> void:
	if playerCharacterCard.cardKey == "Lev" and playerCharacterCard.perkValueAtRoundEnd:
		await _deal_damage(Actor.Type.OPPONENT, playerCharacterCard.perkValueAtRoundEnd)
	
	if opponentCharacterCard.cardKey == "Lev" and opponentCharacterCard.perkValueAtRoundEnd:
		await _deal_damage(Actor.Type.PLAYER, opponentCharacterCard.perkValueAtRoundEnd)

func _deal_damage(who: Actor.Type, amount: int, isDelay: bool = true) -> void:
	if isDelay:
		await get_tree().create_timer(PERK_CALCULATION_TIME_AFTER_ROUND_END).timeout
	
	var currentHealth = ui.get_health(who)
	currentHealth -= amount
	ui.update_health(who, currentHealth)
	
	await ui.play_damage_effect(who, amount)
