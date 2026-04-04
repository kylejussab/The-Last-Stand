extends Node

const PERK_CALCULATION_TIME: float = 1.0
const PERK_CALCULATION_TIME_AFTER_ROUND_END: float = 0.5
const OPPONENT_THINKING_TIME: float = 1.0
const END_ROUND_TIME: float = 1.2
const CARD_MOVE_SPEED: float = 0.2
const CARD_MOVE_FAST_SPEED: float = 0.15

const DISCARD_PILE_POSITION: Vector2 = Vector2(135, 292)

const HALF_MAXIMUM_HAND_SIZE: int = 4

var minimumCardsForReshuffle: int = 5

# Modifiers
var cardRotActive: bool = false
var guerrillaTacticsActive: bool = false
var infectedDeckActive: bool = false
var humanityRestoredActive: bool = false
var slowBleedActive: bool = false
var alwaysFirstActive: bool = false
var volatileHandActive: bool = false
var reducedHandActive: bool = false
var noDefenseActive: bool = false
var loudNoiseActive: bool = false
var loneWolfActive: bool = false
var supplyLineActive: bool = false
var forsakenHonorActive: bool = false
var calculatedRiskActive: bool = false
var deepWoundsActive: bool = false
var heavyHitterActive: bool = false
var overExertionActive: bool = false
var stackedOddsActive: bool = false
var friendlyFireActive: bool = false
var desperateMeasuresActive: bool = false

var previousRoundFaction: String = ""
var previousRoundRoles: Array = []

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
var lockPlayerInput: bool = true:
	set(value):
		lockPlayerInput = value
		if value == true:
			currentThinkTime = 0.0
			
			if is_instance_valid(%cardManager):
				%cardManager.force_unhighlight_all_cards()

enum RoundStage { PLAYER_CHARACTER, OPPONENT_CHARACTER, PLAYER_SUPPORT, OPPONENT_SUPPORT, END_CALCULATION }

var whoStartedRound: Actor.Type = Actor.Type.PLAYER
var roundStage: RoundStage
var isRoundActive: bool = false
var currentThinkTime: float = 0.0

var opponentAI: OpponentAI

var discardedCards: Array = []
var discardedCardZIndex: int = 1

@onready var ui: Node2D = %arena
@onready var endScreenAnimator: Node = %holdoutEndScreenAnimator
var playerCardScene = preload("res://scenes/card.tscn")
var opponentCardScene = preload("res://scenes/opponentCard.tscn")

#Debug variable [also delete the check in opponentHand.gd when done]
var showOpponentsCards: bool = false

func _process(delta):
	if isRoundActive:
		HoldoutStats.count_time_played(delta)
		
		# Analysis Paralysis Accolade tracker
		if not lockPlayerInput:
			currentThinkTime += delta
			
			if currentThinkTime > HoldoutStats.longestThinkTime:
				HoldoutStats.longestThinkTime = currentThinkTime

func _ready() -> void:
	HoldoutStats.replayedRound = false
	
	$"../battleTimer".wait_time = OPPONENT_THINKING_TIME
	$"../cardManager".connect("characterPlayed", Callable(self, "_on_player_character_played"))
	$"../cardManager".connect("supportPlayed", Callable(self, "_on_player_support_played"))
	
	if SaveManager.isLoadingSave:
		_load_game_from_snapshot()
		SaveManager.isLoadingSave = false
	else:
		prepare_opponent()
		
		HoldoutStats.currentPlayer = Actor.Avatar.JUNE
		HoldoutStats.playerHealthValue = 99
		HoldoutStats.playerHealthAtRoundStart = 99
		
		ui.update_health(Actor.Type.PLAYER, HoldoutStats.playerHealthValue, true)
		GameStats.gameMode = GameStats.Mode.HOLDOUT
		initialize_game()

func prepare_opponent() -> void:
	if not HoldoutStats.replayedRound:
		HoldoutStats.currentOpponent = _pick_next_opponent()
	
	_initialize_opponent(HoldoutStats.currentPlayer, HoldoutStats.currentOpponent)

func initialize_game() -> void:
	if HoldoutStats.replayedRound:
		seed(HoldoutStats.currentBattleSeed)
	else:
		randomize() 
		HoldoutStats.currentBattleSeed = randi()
		seed(HoldoutStats.currentBattleSeed)
		
	%pauseIcon.show()
	
	if infectedDeckActive:
		$"../characterDeck".deck = Database.infectedHeavyCharacterDeck.duplicate()
		$"../supportDeck".deck = Database.infectedHeavySupportDeck.duplicate()
	elif humanityRestoredActive: 
		$"../characterDeck".deck = Database.humanityRestoredCharacterDeck.duplicate()
		$"../supportDeck".deck = Database.standardSupportDeck.duplicate()
	else:
		$"../characterDeck".deck = Database.standardCharacterDeck.duplicate()
		$"../supportDeck".deck = Database.standardSupportDeck.duplicate()
	
	$"../characterDeck".deck.shuffle()
	$"../supportDeck".deck.shuffle()
	
	await _draw_cards_at_start(false)
	
	whoStartedRound = Actor.Type.PLAYER
	roundStage = RoundStage.PLAYER_CHARACTER
	
	ui.set_indicator(Actor.Type.PLAYER)
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
	
	if supplyLineActive:
		await get_tree().create_timer(OPPONENT_THINKING_TIME).timeout
		%cardManager.play_top_character_from_deck()
	
	lockPlayerInput = false
	isRoundActive = true
	
	%bubbleContainer.render_active_modifiers()
	
	_save_round_checkpoint()

func add_modifier(modifier: Database.Modifier) -> void:
	var instance = Database.MODIFIERS[modifier].duplicate(true)
	instance["currentDuration"] = 0
	
	HoldoutStats.activeModifiers.append(instance)
	HoldoutStats.multiplierTotal += instance["multiplier"]
	
	match modifier:
		Database.Modifier.CARD_ROT:
			cardRotActive = true
		Database.Modifier.NO_DEFENSE:
			noDefenseActive = true
		Database.Modifier.LOUD_NOISE:
			loudNoiseActive = true
		Database.Modifier.CALCULATED_RISK:
			calculatedRiskActive = true
		Database.Modifier.DEEP_WOUNDS:
			deepWoundsActive = true
		Database.Modifier.HEAVY_HITTER:
			heavyHitterActive = true
		Database.Modifier.OVER_EXERTION:
			overExertionActive = true
		Database.Modifier.STACKED_ODDS:
			stackedOddsActive = true
		Database.Modifier.FRIENDLY_FIRE:
			friendlyFireActive = true
		Database.Modifier.DESPERATE_MEASURES:
			desperateMeasuresActive = true
		Database.Modifier.GUERRILLA_TACTICS:
			guerrillaTacticsActive = true
		Database.Modifier.INFECTED_DECK:
			infectedDeckActive = true
		Database.Modifier.HUMANITY_RESTORED:
			humanityRestoredActive = true
		Database.Modifier.FORSAKEN_HONOR:
			forsakenHonorActive = true
			ui.update_health(Actor.Type.PLAYER, HoldoutStats.playerHealthValue - 20)
		Database.Modifier.REDUCED_HAND:
			reducedHandActive = true
			if loneWolfActive:
				maximumCharacterCardsInHand = 6
				maximumSupportCardsInHand = 0
			else:
				maximumCharacterCardsInHand = 3
				maximumSupportCardsInHand = 3
		Database.Modifier.SLOW_BLEED:
			slowBleedActive = true
		Database.Modifier.ALWAYS_FIRST:
			alwaysFirstActive = true
		Database.Modifier.VOLATILE_HAND:
			minimumCardsForReshuffle = 6
			volatileHandActive = true
		Database.Modifier.LONE_WOLF:
			if volatileHandActive:
				minimumCardsForReshuffle = 10
			if reducedHandActive:
				maximumCharacterCardsInHand = 6
			else:
				maximumCharacterCardsInHand = 8
			maximumSupportCardsInHand = 0
			loneWolfActive = true
		Database.Modifier.SUPPLY_LINE:
			if volatileHandActive:
				minimumCardsForReshuffle = 10
			if reducedHandActive:
				maximumSupportCardsInHand = 6
			else:
				maximumSupportCardsInHand = 8
			maximumCharacterCardsInHand = 0
			supplyLineActive = true

func remove_modifier(modifier: Database.Modifier) -> void:
	for i in range(HoldoutStats.activeModifiers.size() - 1, -1, -1):
		if HoldoutStats.activeModifiers[i].get("id") == modifier:
			HoldoutStats.multiplierTotal -= HoldoutStats.activeModifiers[i]["multiplier"]
			HoldoutStats.activeModifiers.remove_at(i)
			break
	
	match modifier:
		Database.Modifier.CARD_ROT:
			cardRotActive = false
		Database.Modifier.NO_DEFENSE:
			noDefenseActive = false
		Database.Modifier.LOUD_NOISE:
			loudNoiseActive = false
		Database.Modifier.CALCULATED_RISK:
			calculatedRiskActive = false
		Database.Modifier.DEEP_WOUNDS:
			deepWoundsActive = false
		Database.Modifier.HEAVY_HITTER:
			heavyHitterActive = false
		Database.Modifier.OVER_EXERTION:
			overExertionActive = false
		Database.Modifier.STACKED_ODDS:
			stackedOddsActive = false
		Database.Modifier.FRIENDLY_FIRE:
			friendlyFireActive = false
		Database.Modifier.DESPERATE_MEASURES:
			desperateMeasuresActive = false
		Database.Modifier.INFECTED_DECK:
			infectedDeckActive = false
		Database.Modifier.HUMANITY_RESTORED:
			humanityRestoredActive = false
		Database.Modifier.GUERRILLA_TACTICS:
			guerrillaTacticsActive = false
		Database.Modifier.FORSAKEN_HONOR:
			forsakenHonorActive = false
		Database.Modifier.REDUCED_HAND:
			reducedHandActive = false
			maximumCharacterCardsInHand = 4
			maximumSupportCardsInHand = 4
		Database.Modifier.SLOW_BLEED:
			slowBleedActive = false
		Database.Modifier.ALWAYS_FIRST:
			alwaysFirstActive = false
		Database.Modifier.VOLATILE_HAND:
			minimumCardsForReshuffle = 3
			volatileHandActive = false
		Database.Modifier.LONE_WOLF:
			if volatileHandActive:
				minimumCardsForReshuffle = 5
			if reducedHandActive:
				maximumCharacterCardsInHand = 3
				maximumSupportCardsInHand = 3
			else:
				maximumCharacterCardsInHand = 4
				maximumSupportCardsInHand = 4
			loneWolfActive = false
		Database.Modifier.SUPPLY_LINE:
			if volatileHandActive:
				minimumCardsForReshuffle = 5
			if reducedHandActive:
				maximumCharacterCardsInHand = 3
				maximumSupportCardsInHand = 3
			else:
				maximumCharacterCardsInHand = 4
				maximumSupportCardsInHand = 4
			supplyLineActive = false

# Privates
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
		await _apply_mid_round_perks()
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
		await _apply_mid_round_perks()
		_transition_to_support_phase()

	else:
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
		lockPlayerInput = false
		roundStage = RoundStage.PLAYER_CHARACTER
		
		if supplyLineActive:
			ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
			await get_tree().create_timer(OPPONENT_THINKING_TIME).timeout
			%cardManager.play_top_character_from_deck()
	
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
	
	HoldoutStats.record_played_card("Support", playerSupportCard.cardKey, playerSupportCard.value)
	
	await _apply_player_support(playerSupportCard, opponentCharacterCard, playerCharacterCard)
	
	if whoStartedRound == Actor.Type.PLAYER:
		_execute_opponent_support_play()
	else:
		lockPlayerInput = true
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
		
		HoldoutStats.record_played_card("Support", opponentSupportCard.cardKey, opponentSupportCard.value, true)
		
		await _apply_opponent_support(opponentSupportCard, playerCharacterCard, opponentCharacterCard)
	
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
	
	if whoStartedRound == Actor.Type.PLAYER:
		ui.set_indicator(Actor.Type.NONE)
		await _apply_end_round_perks()
		_transition_to_resolution_phase()
	else:
		lockPlayerInput = false
		roundStage = RoundStage.PLAYER_SUPPORT
		ui.set_indicator(Actor.Type.PLAYER)
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
		ui.show_end_turn_button()

	
	opponentPlayedSupport = true

func _transition_to_resolution_phase() -> void:
	roundStage = RoundStage.END_CALCULATION
	
	if desperateMeasuresActive and !_is_player_support_matched():
		playerCharacterCard.get_node("ModifierIndicator").texture = load("res://assets/modifiers/Desperate Measures.png")
		playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
		await _deal_damage(Actor.Type.PLAYER, 3)
	
	if stackedOddsActive:
		opponentCharacterCard.get_node("ModifierIndicator").texture = load("res://assets/modifiers/Stacked Odds.png")
		opponentCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
		opponentCharacterCard.modify_value(1)
	
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
	
	HoldoutStats.roundsPlayed += 1
	cardsToDiscard = []
	
	_start_new_round()

func _conclude_match() -> void:
	isRoundActive = true
	GameStats.gameMode = GameStats.Mode.HOLDOUT_ROUND_COMPLETED
	GameStats.totalInGameTimePlayed += HoldoutStats.currentRoundDuration
	
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
	
	%bubbleContainer.clear_modifiers()
	
	endScreenAnimator.play_holdout_end_sequence(ui.get_health(Actor.Type.PLAYER) > 0)
	
	await _repopulate_decks(true)
	
	discardedCardZIndex = 1
	
	SaveManager.clear_holdout_save()

func _start_new_round() -> void:
	previousRoundFaction = playerCharacterCard.faction
	previousRoundRoles = Array(playerCharacterCard.role.split("/"))
	
	playerCharacterCard = null
	playerSupportCard = null
	opponentCharacterCard = null
	opponentSupportCard = null
	
	opponentPlayedSupport = false
	
	ui.show_end_turn_button(false)
	
	# Shuffle cards from discard back into decks if needed
	await _repopulate_decks()
	
	_apply_guerrilla_tactics_restrictions()
	
	if HoldoutStats.roundsPlayed % 2 == 0 and !alwaysFirstActive:
		whoStartedRound = Actor.Type.OPPONENT
		
		ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.THINKING)
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)
		_execute_opponent_character_play()
	else:
		whoStartedRound = Actor.Type.PLAYER
		
		ui.set_indicator(Actor.Type.PLAYER)
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
		ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
		
		if supplyLineActive:
			await get_tree().create_timer(OPPONENT_THINKING_TIME).timeout
			%cardManager.play_top_character_from_deck()
		
		lockPlayerInput = false
	
	_save_round_checkpoint()

func _on_end_turn_button_pressed() -> void:
	ui.show_end_turn_button(false)
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)
	
	lockPlayerInput = true
	
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
	
	var characterDrawLoop = max(maximumCharacterCardsInHand, HALF_MAXIMUM_HAND_SIZE)
	
	for i in range(characterDrawLoop):
		if i < maximumCharacterCardsInHand:
			await get_tree().create_timer(CARD_MOVE_FAST_SPEED).timeout
			$"../characterDeck".draw_card()
			
		if i < HALF_MAXIMUM_HAND_SIZE:
			await get_tree().create_timer(CARD_MOVE_FAST_SPEED).timeout
			$"../characterDeck".draw_opponent_card()
	
	var supportDrawLoop = max(maximumSupportCardsInHand, HALF_MAXIMUM_HAND_SIZE)

	for i in range(supportDrawLoop):
		if i < maximumSupportCardsInHand:
			await get_tree().create_timer(CARD_MOVE_FAST_SPEED).timeout
			$"../supportDeck".draw_card()
			
		if i < HALF_MAXIMUM_HAND_SIZE:
			await get_tree().create_timer(CARD_MOVE_FAST_SPEED).timeout
			$"../supportDeck".draw_opponent_card()
	
	GameStats.gameMode = GameStats.Mode.HOLDOUT
	
	%pauseIcon.show()

func _pick_next_opponent() -> Actor.Avatar:
	if HoldoutStats.opponentList.is_empty():
		match GameStats.gameMode:
			GameStats.Mode.JUNE_RAVEL:
				HoldoutStats.opponentList = Database.JUNE_OPPONENTS.duplicate()
			GameStats.Mode.HOLDOUT:
				var list = Database.AVATARS.keys()
				
				if HoldoutStats.currentPlayer in list:
					list.erase(HoldoutStats.currentPlayer)
				
				list.shuffle()
				
				if HoldoutStats.currentOpponent in list and list.size() > 1:
					if list[0] == HoldoutStats.currentOpponent:
						var temp = list[0]
						list[0] = list[1]
						list[1] = temp
				
				HoldoutStats.opponentList = list
	
	return HoldoutStats.opponentList.pop_front()

func _animate_opponent_playing_card(opponentCard: Node2D, opponentCardSlot: Node2D) -> void:
	AudioManager.play_random_card_draw()
	opponentCard.get_node("Area2D/CollisionShape2D").disabled = false
	
	opponentCard.get_node("AnimationPlayer").play("cardFlip")
	
	var tween = get_tree().create_tween()
	tween.finished.connect(AudioManager.play_random_card_draw)
	tween.tween_property(opponentCard, "position", opponentCardSlot.position, CARD_MOVE_SPEED)
	
	$"../opponentHand".remove_card_from_hand(opponentCard)

func _apply_mid_round_perks() -> void:
	if friendlyFireActive and (playerCharacterCard.faction == opponentCharacterCard.faction):
		await get_tree().create_timer(0.3).timeout
		playerCharacterCard.get_node("ModifierIndicator").texture = load("res://assets/modifiers/Friendly Fire.png")
		playerCharacterCard.get_node("AnimationPlayer").queue("modifierIndicator")
		playerCharacterCard.modify_value(-int(ceil(playerCharacterCard.value / 2.0)))
		await playerCharacterCard.get_node("AnimationPlayer").animation_finished
	
	if whoStartedRound == Actor.Type.PLAYER:
		await _execute_player_mid_perk()
		await _execute_opponent_mid_perk()
	else:
		await _execute_opponent_mid_perk()
		await _execute_player_mid_perk()
	
	if heavyHitterActive && playerCharacterCard.value >= 5:
		playerCharacterCard.get_node("ModifierIndicator").texture = load("res://assets/modifiers/Heavy Hitter.png")
		playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
		await _deal_damage(Actor.Type.PLAYER, 1)
	
	_handle_runner_perk()

func _update_playable_support_cards() -> void:
	var playerCharacterCardRoles = playerCharacterCard.role.split("/")
	for card in playerHand:
		if is_instance_valid(card) and card.type == "Support":
			if desperateMeasuresActive:
				card.canBePlayed = true
			else:
				var playerSupportCardRoles = card.role.split("/")
				for role in playerCharacterCardRoles:
					if role in playerSupportCardRoles:
						card.canBePlayed = true
	
	var opponentCharacterCardRoles = opponentCharacterCard.role.split("/")
	for card in opponentHand:
		if is_instance_valid(card) and card.type == "Support":
			var opponentSupportCardRoles = card.role.split("/")
			for role in opponentCharacterCardRoles:
				if role in opponentSupportCardRoles:
					card.canBePlayed = true

func _apply_end_round_perks() -> void:
	if whoStartedRound == Actor.Type.PLAYER:
		# Character Phase
		await _execute_player_char_end_perk()
		await _execute_opponent_char_end_perk()
		# Support Phase
		await _execute_player_supp_end_perk()
		await _execute_opponent_supp_end_perk()
		# Late Phase
		await _execute_player_late_end_perk()
		await _execute_opponent_late_end_perk()
	else:
		await _execute_opponent_char_end_perk()
		await _execute_player_char_end_perk()
		
		await _execute_opponent_supp_end_perk()
		await _execute_player_supp_end_perk()
		
		await _execute_opponent_late_end_perk()
		await _execute_player_late_end_perk()

	await get_tree().create_timer(PERK_CALCULATION_TIME).timeout

func _calculate_damage() -> void:
	var playerTotal = playerCharacterCard.value
	var opponentTotal = opponentCharacterCard.value
	
	HoldoutStats.record_played_card(playerCharacterCard.faction, playerCharacterCard.cardKey, playerTotal)
	HoldoutStats.record_played_card(opponentCharacterCard.faction, opponentCharacterCard.cardKey, opponentTotal, true)
	
	if HoldoutStats.highestDominance < playerTotal - opponentTotal:
		HoldoutStats.highestDominance = playerTotal - opponentTotal
	
	_apply_calculation_round_perks(playerTotal, opponentTotal)
	
	if playerTotal >= 10 && overExertionActive:
		playerCharacterCard.get_node("ModifierIndicator").texture = load("res://assets/modifiers/Over Exertion.png")
		playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
		_deal_damage(Actor.Type.PLAYER, 1)
		await _deal_damage(Actor.Type.OPPONENT, 2)
	
	if playerTotal > opponentTotal:
		await _handle_player_win(playerTotal, opponentTotal)
	elif opponentTotal > playerTotal:
		await _handle_opponent_win(playerTotal, opponentTotal)
	else:
		HoldoutStats.currentStreak = 0
	
	if slowBleedActive and HoldoutStats.roundsPlayed % 2 == 0 and Database.MODIFIERS.has(Database.Modifier.SLOW_BLEED):
		await _deal_damage(Actor.Type.PLAYER, Database.MODIFIERS.get(Database.Modifier.SLOW_BLEED)["amount"])
	
	if cardRotActive and HoldoutStats.roundsPlayed % 3 == 0:
		for card in playerHand:
			card.get_node("ModifierIndicator").texture = load("res://assets/modifiers/Card Rot.png")
			card.get_node("AnimationPlayer").queue("modifierIndicator")
			card.modify_value(-1)

func _apply_player_support(support: Node2D, opponentCharacter: Node2D, playerCharacter: Node2D) -> void:
	await get_tree().create_timer(1.0).timeout
	
	if support.cardKey == "SupplyCache": # 0 card, no need to change value by 0
		return
	
	if Database.SUPPORTS[support.cardKey][3] == "Negative":
		var value = support.value
		support.modify_value(-value)
		await opponentCharacter.modify_value(-value)
	else:
		var value = support.value
		support.modify_value(-value)
		await playerCharacter.modify_value(value)

func _apply_opponent_support(support: Node2D, playerCharacter: Node2D, opponentCharacter: Node2D) -> void:
	await get_tree().create_timer(1.0).timeout
	
	if support.cardKey == "SupplyCache": # 0 card, no need to change value by 0
		return
	
	if Database.SUPPORTS[support.cardKey][3] == "Negative":
		var value = support.value
		support.modify_value(-value)
		await playerCharacter.modify_value(-value)
	else:
		var value = support.value
		support.modify_value(-value)
		await opponentCharacter.modify_value(value)

func _apply_calculation_round_perks(playerTotal: int, opponentTotal: int) -> void:
	if whoStartedRound == Actor.Type.PLAYER:
		await _execute_player_calc_perk(playerTotal, opponentTotal)
		await _execute_opponent_calc_perk(playerTotal, opponentTotal)
	else:
		await _execute_opponent_calc_perk(playerTotal, opponentTotal)
		await _execute_player_calc_perk(playerTotal, opponentTotal)

func _move_cards_to_discard(cards: Array) -> void:
	_reset_played_cards_perks()
	_reset_allowed_support_cards()
	
	if is_instance_valid(%cardManager) and %cardManager.hoveredCard in cards:
		%cardManager.hoveredCard = null
	
	for card in cards:
		discardedCards.append(card)
		AudioManager.play_random_card_draw()
		card.scale = Vector2(1, 1)
		
		if "perk" in card and card.perk != null:
			var anim = card.get_node("AnimationPlayer")
			if anim.has_animation("showPerkDescription"):
				anim.play("showPerkDescription")
				anim.seek(0, true)
				anim.stop()
		
		card.get_node("Area2D/CollisionShape2D").disabled = true
		
		card.z_index = discardedCardZIndex
		discardedCardZIndex += 1
		var tween = get_tree().create_tween()
		tween.finished.connect(AudioManager.play_random_card_draw)
		tween.tween_property(card, "position", DISCARD_PILE_POSITION, CARD_MOVE_FAST_SPEED)
		
		await tween.finished
	
	$"../cardSlots/cardSlotSupport".occupied = false
	$"../cardSlots/cardSlotCharacter".occupied = false
	
	if HoldoutStats.roundsPlayed % 2 == 0 and volatileHandActive and GameStats.gameMode == GameStats.Mode.HOLDOUT:
		for card in playerHand.duplicate():
			await _place_card_in_discard(card, %playerHand)

func _reset_played_cards_perks() -> void:
	if playerCharacterCard.perk:
		playerCharacterCard.get_node("value").text = str(playerCharacterCard.value)
	
	if opponentCharacterCard.perk:
		opponentCharacterCard.get_node("value").text = str(opponentCharacterCard.value)

func _reset_allowed_support_cards() -> void:
	if playerSupportCard:
		playerSupportCard.canBePlayed = false
	
	for card in playerHand:
		if is_instance_valid(card) and card.type == "Support":
			card.canBePlayed = false
	
	if opponentSupportCard:
		opponentSupportCard.canBePlayed = false
	
	for card in opponentHand:
		if is_instance_valid(card) and card.type == "Support":
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
	
	if who == Actor.Type.PLAYER:
		while characterCount < maximumCharacterCardsInHand:
			characterDeckReference.draw_card()
			characterCount += 1
			await get_tree().create_timer(CARD_MOVE_SPEED).timeout
	else:
		@warning_ignore("integer_division")
		while characterCount < HALF_MAXIMUM_HAND_SIZE:
			characterDeckReference.draw_opponent_card()
			characterCount += 1
			await get_tree().create_timer(CARD_MOVE_SPEED).timeout
	
	if who == Actor.Type.PLAYER:
		while supportCount < maximumSupportCardsInHand:
			supportDeckReference.draw_card()
			supportCount += 1
			await get_tree().create_timer(CARD_MOVE_SPEED).timeout
	else:
		@warning_ignore("integer_division")
		while supportCount < HALF_MAXIMUM_HAND_SIZE:
			supportDeckReference.draw_opponent_card()
			supportCount += 1
			await get_tree().create_timer(CARD_MOVE_SPEED).timeout
	lockPlayerInput = false

func _repopulate_decks(endGame: bool = false) -> void:
	var discardedCharacters := []
	var discardedSupports := []
	
	for card in discardedCards:
		if is_instance_valid(card) and card.type == "Character":
			discardedCharacters.append(card)
		elif is_instance_valid(card) and card.type == "Support":
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
	
	if $"../supportDeck".deck.size() < minimumCardsForReshuffle:
		discardedCards = discardedCharactersReversed + discardedSupportsReversed
		
		for i in range(discardedSupportsReversed.size()):
			discardedSupportsReversed[i].z_index = 100 - i
		
		$"../supportDeck".reshuffle_from_discards(discardedSupportsReversed)
		for card in discardedSupportsReversed:
			discardedCards.erase(card)
		
		return
	
	if $"../characterDeck".deck.size() < minimumCardsForReshuffle:
		discardedCards = discardedSupportsReversed + discardedCharactersReversed
		
		for i in range(discardedCharactersReversed.size()):
			discardedCharactersReversed[i].z_index = 100 - i
		
		$"../characterDeck".reshuffle_from_discards(discardedCharactersReversed)
		for card in discardedCharactersReversed:
			discardedCards.erase(card)
		
		return

func _place_card_in_discard(card: Node2D, hand: Node2D) -> void:
	discardedCards.append(card)
	AudioManager.play_random_card_draw()
	card.scale = Vector2(1, 1)
	card.get_node("Area2D/CollisionShape2D").disabled = true
	
	card.z_index = discardedCardZIndex
	discardedCardZIndex += 1
	var tween = get_tree().create_tween()
	tween.finished.connect(func(): AudioManager.play_random_card_draw())
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
	HoldoutStats.currentStreak += 1
	if HoldoutStats.longestStreak < HoldoutStats.currentStreak:
		HoldoutStats.longestStreak = HoldoutStats.currentStreak
		
	var damage = playerTotal - opponentTotal
	
	_check_old_wounds_accolade()
	
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.HAPPY)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.HURT)
	
	if opponentCharacterCard.cardKey == "Owen":
		await get_tree().create_timer(PERK_CALCULATION_TIME_AFTER_ROUND_END).timeout
		return
	
	await _deal_damage(Actor.Type.OPPONENT, damage, false)
	
	await _handle_shambler_perk(Actor.Type.PLAYER)
	
	if playerCharacterCard.perkValueAtRoundEnd: # Any non-special perks that need triggering on round end
		await _deal_damage(Actor.Type.OPPONENT, playerCharacterCard.perkValueAtRoundEnd)
	
	if calculatedRiskActive and damage == 1:
		playerCharacterCard.get_node("ModifierIndicator").texture = load("res://assets/modifiers/Calculated Risk.png")
		playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
		await _deal_damage(Actor.Type.OPPONENT, 3)
	
	if Database.CHARACTERS[playerCharacterCard.cardKey][0] <= 3 or Database.CHARACTERS[playerCharacterCard.cardKey][0] < Database.CHARACTERS[opponentCharacterCard.cardKey][0]:
		HoldoutStats.underdogWins += 1

func _handle_opponent_win(playerTotal: int, opponentTotal: int) -> void:
	HoldoutStats.currentStreak = 0
	
	var damage = opponentTotal - playerTotal
	
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.HURT)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.HAPPY)
	
	if playerCharacterCard.cardKey == "Owen":
		await get_tree().create_timer(PERK_CALCULATION_TIME_AFTER_ROUND_END).timeout
		return
	
	await _deal_damage(Actor.Type.PLAYER, damage, false)
	
	await _handle_shambler_perk(Actor.Type.OPPONENT)
	
	if opponentCharacterCard.perkValueAtRoundEnd: # Any non-special perks that need triggering on round end
		await _deal_damage(Actor.Type.PLAYER, opponentCharacterCard.perkValueAtRoundEnd)
	
	if deepWoundsActive and damage >= 5:
		playerCharacterCard.get_node("ModifierIndicator").texture = load("res://assets/modifiers/Deep Wounds.png")
		playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
		await _deal_damage(Actor.Type.PLAYER, 2)

func _handle_shambler_perk(winner: Actor.Type) -> void:
	if winner == Actor.Type.PLAYER:
		if opponentCharacterCard.cardKey == "Shambler" and opponentCharacterCard.perkValueAtRoundEnd:
			await _deal_damage(Actor.Type.PLAYER, opponentCharacterCard.perkValueAtRoundEnd)
	elif winner == Actor.Type.OPPONENT:
		if playerCharacterCard.cardKey == "Shambler" and playerCharacterCard.perkValueAtRoundEnd:
			await _deal_damage(Actor.Type.OPPONENT, playerCharacterCard.perkValueAtRoundEnd)

func _deal_damage(who: Actor.Type, amount: int, isDelay: bool = true) -> void:
	if isDelay:
		await get_tree().create_timer(PERK_CALCULATION_TIME_AFTER_ROUND_END).timeout
	
	var currentHealth = ui.get_health(who)
	currentHealth -= amount
	ui.update_health(who, currentHealth)
	
	await ui.play_damage_effect(who, amount)

func _apply_guerrilla_tactics_restrictions() -> void:
	for card in playerHand:
		if card.type == "Character":
			card.canBePlayed = true
	
	if not guerrillaTacticsActive or previousRoundFaction == "":
		for card in playerHand:
			if card.type == "Character":
				_animate_card_unlock(card)
		return
	
	var cards_to_lock: Array = []
	
	for card in playerHand:
		if card.type == "Character":
			var isRestricted: bool = false
			
			if card.faction == previousRoundFaction:
				isRestricted = true
			
			if not isRestricted:
				var currentCardRoles = card.role.split("/")
				for role in currentCardRoles:
					if role in previousRoundRoles:
						isRestricted = true
						break
			
			if isRestricted:
				cards_to_lock.append(card)
	
	var totalCharacters: int = 0
	for card in playerHand:
		if is_instance_valid(card) and card.type == "Character":
			totalCharacters += 1
			
	
	var fail_safe_active = (totalCharacters > 0 and cards_to_lock.size() == totalCharacters)
	
	if fail_safe_active:
		for card in cards_to_lock:
			card.canBePlayed = false
			_animate_card_lock(card)
		
		await get_tree().create_timer(0.5).timeout
		
		for card in playerHand:
			if card.type == "Character":
				card.canBePlayed = true
				_animate_card_unlock(card)
				
	else:
		for card in playerHand:
			if card.type == "Character":
				if card in cards_to_lock:
					card.canBePlayed = false
					_animate_card_lock(card)
				else:
					card.canBePlayed = true
					_animate_card_unlock(card)

func _animate_card_lock(card):
	if card.get_node("lockIcon/top").modulate.a < 0.9:
		card.get_node("AnimationPlayer").play("lock")
		await get_tree().create_timer(0.35).timeout
		AudioManager.play_card_lock()

func _animate_card_unlock(card):
	if card.get_node("lockIcon/top").modulate.a > 0.1:
		card.get_node("AnimationPlayer").play_backwards("lock")
		await get_tree().create_timer(0.35).timeout
		AudioManager.play_card_lock()

func _is_player_support_matched() -> bool:
	if playerSupportCard == null: 
		return true
	
	var characterRoles = playerCharacterCard.role.split("/")
	var supportRoles = playerSupportCard.role.split("/")
	
	for role in characterRoles:
		if role in supportRoles:
			return true
		
	return false

func _check_old_wounds_accolade() -> void:
	if HoldoutStats.RIVALRIES.has(playerCharacterCard.cardKey):
		var rivals = HoldoutStats.RIVALRIES[playerCharacterCard.cardKey]
		if opponentCharacterCard.cardKey in rivals:
			HoldoutStats.achievedOldWounds = true

# Perk Helpers
func _execute_player_mid_perk() -> void:
	if playerCharacterCard.perk && playerCharacterCard.perk.timing == "midRound":
		await get_tree().create_timer(PERK_CALCULATION_TIME).timeout
		await playerCharacterCard.perk.apply_mid_perk(playerCharacterCard, playerHand, opponentCharacterCard)

func _execute_opponent_mid_perk() -> void:
	if opponentCharacterCard.perk && opponentCharacterCard.perk.timing == "midRound":
		var playerRealRole = playerCharacterCard.role
		var playerRealFaction = playerCharacterCard.faction
		
		if forsakenHonorActive:
			if opponentCharacterCard.perk.has_method("would_perk_trigger") and opponentCharacterCard.perk.would_perk_trigger(opponentCharacterCard, opponentHand, playerCharacterCard):
				playerCharacterCard.get_node("ModifierIndicator").texture = load("res://assets/modifiers/Forsaken Honor.png")
				playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
				await playerCharacterCard.get_node("AnimationPlayer").animation_finished
			
			playerCharacterCard.role = "Unknown"
			playerCharacterCard.faction = "Unknown"
		
		await get_tree().create_timer(PERK_CALCULATION_TIME).timeout
		await opponentCharacterCard.perk.apply_mid_perk(opponentCharacterCard, opponentHand, playerCharacterCard)
		
		if forsakenHonorActive:
			playerCharacterCard.role = playerRealRole
			playerCharacterCard.faction = playerRealFaction
			_update_playable_support_cards()

func _execute_player_char_end_perk() -> void:
	if playerCharacterCard.perk && playerCharacterCard.perk.timing == "endRound":
		await playerCharacterCard.perk.apply_end_perk(playerCharacterCard, playerSupportCard, opponentCharacterCard, opponentSupportCard, playerHand)

func _execute_opponent_char_end_perk() -> void:
	if opponentCharacterCard.perk && opponentCharacterCard.perk.timing == "endRound":
		var playerRealRole = playerCharacterCard.role
		var playerRealFaction = playerCharacterCard.faction
		
		if forsakenHonorActive:
			if opponentCharacterCard.perk.has_method("would_perk_trigger") and opponentCharacterCard.perk.would_perk_trigger(opponentCharacterCard, opponentSupportCard, playerCharacterCard, playerSupportCard, opponentHand):
				playerCharacterCard.get_node("ModifierIndicator").texture = load("res://assets/modifiers/Forsaken Honor.png")
				playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
				await playerCharacterCard.get_node("AnimationPlayer").animation_finished
			
			playerCharacterCard.role = "Unknown"
			playerCharacterCard.faction = "Unknown"
			
		await opponentCharacterCard.perk.apply_end_perk(opponentCharacterCard, opponentSupportCard, playerCharacterCard, playerSupportCard, opponentHand)
		
		if forsakenHonorActive:
			playerCharacterCard.role = playerRealRole
			playerCharacterCard.faction = playerRealFaction
			_update_playable_support_cards()

func _execute_player_supp_end_perk() -> void:
	if playerSupportCard && playerSupportCard.perk && playerSupportCard.perk.timing == "endRound":
		await playerSupportCard.perk.apply_end_perk(playerCharacterCard, playerSupportCard, opponentCharacterCard, opponentSupportCard, playerHand)

func _execute_opponent_supp_end_perk() -> void:
	if opponentSupportCard && opponentSupportCard.perk && opponentSupportCard.perk.timing == "endRound":
		await get_tree().create_timer(PERK_CALCULATION_TIME).timeout
		await opponentSupportCard.perk.apply_end_perk(opponentCharacterCard, opponentSupportCard, playerCharacterCard, playerSupportCard, opponentHand)

func _execute_player_late_end_perk() -> void:
	if playerCharacterCard.perk && playerCharacterCard.perk.timing == "lateEndRound":
		await get_tree().create_timer(PERK_CALCULATION_TIME).timeout
		await playerCharacterCard.perk.apply_end_perk(playerCharacterCard, playerSupportCard, opponentCharacterCard, opponentSupportCard, playerHand)

func _execute_opponent_late_end_perk() -> void:
	if opponentCharacterCard.perk && opponentCharacterCard.perk.timing == "lateEndRound":
		await opponentCharacterCard.perk.apply_end_perk(opponentCharacterCard, opponentSupportCard, playerCharacterCard, playerSupportCard, opponentHand)

func _execute_player_calc_perk(playerTotal: int, opponentTotal: int) -> void:
	if playerCharacterCard.perk && playerCharacterCard.perk.timing == "calculationRound":
		await playerCharacterCard.perk.apply_after_calculation_perk(playerCharacterCard, playerHand, playerTotal, opponentTotal)

func _execute_opponent_calc_perk(playerTotal: int, opponentTotal: int) -> void:
	if opponentCharacterCard.perk && opponentCharacterCard.perk.timing == "calculationRound":
		await opponentCharacterCard.perk.apply_after_calculation_perk(opponentCharacterCard, opponentHand, opponentTotal, playerTotal)

# Saving and loading extractors
func _get_card_array_save_data(cardArray: Array) -> Array:
	var parsedData = []
	for card in cardArray:
		if is_instance_valid(card):
			parsedData.append({
				"cardKey": card.cardKey, 
				"value": card.value,
				"role": card.role
			})
	return parsedData

func get_arena_save_dict() -> Dictionary:
	return {
		"whoStartedRound": whoStartedRound,
		"opponentHealth": ui.get_health(Actor.Type.OPPONENT),
		"characterDeck": $"../characterDeck".deck,
		"supportDeck": $"../supportDeck".deck,
		"playerHand": _get_card_array_save_data(playerHand),
		"opponentHand": _get_card_array_save_data(opponentHand),
		"discardedCards": _get_card_array_save_data(discardedCards)
	}

func _save_round_checkpoint() -> void:
	if SaveManager.isLoadingSave:
		return 

	var fullSaveData = {
		"stats": HoldoutStats.get_save_dict(),
		"arena": get_arena_save_dict()
	}
	
	SaveManager.save_holdout_state(fullSaveData)

func _load_game_from_snapshot() -> void:
	var save_data = SaveManager.load_holdout_state()
	
	if save_data.is_empty():
		printerr("Save data corrupted. Starting fresh Holdout run.")
		
		HoldoutStats.currentPlayer = Actor.Avatar.JUNE
		HoldoutStats.playerHealthValue = 99
		HoldoutStats.playerHealthAtRoundStart = 99
		
		ui.update_health(Actor.Type.PLAYER, HoldoutStats.playerHealthValue, true)
		prepare_opponent()
		initialize_game()
		return

	var stats = save_data["stats"]
	var arena = save_data["arena"]

	HoldoutStats.load_save_dict(stats)
	_restore_modifier_flags()
	
	_initialize_opponent(HoldoutStats.currentPlayer, HoldoutStats.currentOpponent)
	
	ui.update_health(Actor.Type.PLAYER, HoldoutStats.playerHealthValue, true)
	if arena.has("opponentHealth"): 
		ui.update_health(Actor.Type.OPPONENT, arena["opponentHealth"], true)
	
	seed(HoldoutStats.currentBattleSeed) 
	
	whoStartedRound = int(arena["whoStartedRound"]) as Actor.Type
	$"../characterDeck".deck = arena["characterDeck"]
	$"../supportDeck".deck = arena["supportDeck"]
	
	await get_tree().process_frame
	
	%playerHand.centerScreenX = get_viewport().get_visible_rect().size.x / 2.0
	%opponentHand.centerScreenX = get_viewport().get_visible_rect().size.x / 2.0
	
	_rebuild_cards_from_save(arena["playerHand"], %playerHand)
	_rebuild_cards_from_save(arena["opponentHand"], %opponentHand)
	
	for saved_card in arena["discardedCards"]:
		var new_card = _spawn_single_card(saved_card)
		new_card.position = DISCARD_PILE_POSITION
		new_card.scale = Vector2(1, 1)
		new_card.z_index = discardedCardZIndex
		discardedCardZIndex += 1
		new_card.get_node("Area2D/CollisionShape2D").disabled = true
		discardedCards.append(new_card)
		$"../cardManager".add_child(new_card) 

	isRoundActive = true
	%pauseIcon.show()
	%bubbleContainer.render_active_modifiers()
	
	_apply_guerrilla_tactics_restrictions()
	
	if whoStartedRound == Actor.Type.PLAYER:
		roundStage = RoundStage.PLAYER_CHARACTER
		ui.set_indicator(Actor.Type.PLAYER)
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
		ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
		lockPlayerInput = false
		
		if supplyLineActive:
			await get_tree().create_timer(OPPONENT_THINKING_TIME).timeout
			%cardManager.play_top_character_from_deck()
	else:
		roundStage = RoundStage.OPPONENT_CHARACTER
		ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.THINKING)
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)
		_execute_opponent_character_play()

func _rebuild_cards_from_save(saved_card_array: Array, hand_node: Node) -> void:
	var is_opponent = (hand_node == %opponentHand)
	
	for saved_card in saved_card_array:
		var new_card = _spawn_single_card(saved_card, is_opponent)
		
		new_card.position = Vector2(hand_node.centerScreenX, hand_node.HAND_Y_POSITION)
		
		$"../cardManager".add_child(new_card)
		
		hand_node.add_card_to_hand(new_card, 0.0)

func _spawn_single_card(card_data: Dictionary, is_opponent: bool = false) -> Node2D:
	var new_card
	if is_opponent:
		new_card = opponentCardScene.instantiate()
	else:
		new_card = playerCardScene.instantiate()
	
	var key = card_data["cardKey"]
	new_card.cardKey = key
	
	if Database.CHARACTERS.has(key):
		var char_data = Database.CHARACTERS[key]
		new_card.type = char_data[1]
		new_card.faction = char_data[2]
		new_card.role = char_data[3]
		new_card.nameText = char_data[4]
		if char_data.size() > 5:
			new_card.perkDescription = char_data[5]
		
		new_card.canBePlayed = true
		
	elif Database.SUPPORTS.has(key):
		var supp_data = Database.SUPPORTS[key]
		new_card.type = supp_data[1]
		new_card.faction = "Support" 
		new_card.role = supp_data[2]
		new_card.nameText = supp_data[4]
		if supp_data.size() > 5:
			new_card.perkDescription = supp_data[5]
		
		new_card.canBePlayed = false
		
	if Database.PERKS.has(key):
		var perk_script = load(Database.PERKS[key])
		if perk_script:
			new_card.perk = perk_script.new()

	new_card.value = card_data["value"]
	
	if card_data.has("role"):
		new_card.role = card_data["role"]
	
	new_card.update_visuals()
	
	if is_opponent and not showOpponentsCards:
		if new_card.has_node("image"): 
			new_card.get_node("image").visible = false
		if new_card.has_node("imageBack"): 
			new_card.get_node("imageBack").visible = true
	
	return new_card

func _restore_modifier_flags() -> void:
	maximumCharacterCardsInHand = 4
	maximumSupportCardsInHand = 4
	minimumCardsForReshuffle = 5
	
	for mod in HoldoutStats.activeModifiers:
		var modifier_id = int(mod["id"])
		
		match modifier_id:
			Database.Modifier.CARD_ROT: cardRotActive = true
			Database.Modifier.NO_DEFENSE: noDefenseActive = true
			Database.Modifier.LOUD_NOISE: loudNoiseActive = true
			Database.Modifier.CALCULATED_RISK: calculatedRiskActive = true
			Database.Modifier.DEEP_WOUNDS: deepWoundsActive = true
			Database.Modifier.HEAVY_HITTER: heavyHitterActive = true
			Database.Modifier.OVER_EXERTION: overExertionActive = true
			Database.Modifier.STACKED_ODDS: stackedOddsActive = true
			Database.Modifier.FRIENDLY_FIRE: friendlyFireActive = true
			Database.Modifier.DESPERATE_MEASURES: desperateMeasuresActive = true
			Database.Modifier.GUERRILLA_TACTICS: guerrillaTacticsActive = true
			Database.Modifier.INFECTED_DECK: infectedDeckActive = true
			Database.Modifier.HUMANITY_RESTORED: humanityRestoredActive = true
			Database.Modifier.FORSAKEN_HONOR: forsakenHonorActive = true
			Database.Modifier.SLOW_BLEED: slowBleedActive = true
			Database.Modifier.ALWAYS_FIRST: alwaysFirstActive = true
			
			Database.Modifier.REDUCED_HAND:
				reducedHandActive = true
				if loneWolfActive:
					maximumCharacterCardsInHand = 6
					maximumSupportCardsInHand = 0
				else:
					maximumCharacterCardsInHand = 3
					maximumSupportCardsInHand = 3
					
			Database.Modifier.VOLATILE_HAND:
				volatileHandActive = true
				minimumCardsForReshuffle = 6
				
			Database.Modifier.LONE_WOLF:
				loneWolfActive = true
				if volatileHandActive: minimumCardsForReshuffle = 10
				if reducedHandActive: maximumCharacterCardsInHand = 6
				else: maximumCharacterCardsInHand = 8
				maximumSupportCardsInHand = 0
				
			Database.Modifier.SUPPLY_LINE:
				supplyLineActive = true
				if volatileHandActive: minimumCardsForReshuffle = 10
				if reducedHandActive: maximumSupportCardsInHand = 6
				else: maximumSupportCardsInHand = 8
				maximumCharacterCardsInHand = 0
