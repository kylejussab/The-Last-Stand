extends Node

# --- TIMINGS & SPEEDS ---
@export_category("Battle Timings")
@export var perkCalculationTime: float = 1.0
@export var perkCalculationTimeAfterRoundEnd: float = 0.5
@export var opponentThinkingTime: float = 1.0
@export var endRoundTime: float = 1.2
@export var cardMoveSpeed: float = 0.2
@export var cardMoveFastSpeed: float = 0.15

# --- LAYOUT ---
@export_category("Layout & UI")
@export var discardPilePosition: Vector2 = Vector2(135, 292)

# --- DEBUG ---
@export_category("Debug")
@export var showOpponentsCards: bool = false

# --- SCENE REFERENCES ---
@onready var ui: Node2D = %arena
@onready var endScreenAnimator: Node = %holdoutEndScreenAnimator
@onready var opponentCharacterCardSlot: Node2D = %opponentCardSlotCharacter
@onready var opponentSupportCardSlot: Node2D = %opponentCardSlotSupport
@onready var playerHand: Array = %playerHand.playerHand
@onready var opponentHand: Array = %opponentHand.opponentHand

var playerCardScene = preload("res://scenes/card.tscn")
var opponentCardScene = preload("res://scenes/opponentCard.tscn")

# --- ENGINE & LOGIC ---
var battleEngine: HoldoutBattleEngine
var opponentAI: OpponentAI

# --- CURRENT ROUND STATE (Physical Cards) ---
var playerCharacterCard: Node2D
var playerSupportCard: Node2D
var opponentCharacterCard: Node2D
var opponentSupportCard: Node2D

var discardedCards: Array = []
var discardedCardZIndex: int = 1

# --- UI SEQUENCE FLAGS ---
var opponentPlayedSupport: bool = false
var lockPlayerInput: bool = true:
	set(value):
		lockPlayerInput = value
		battleEngine.set_player_thinking(not value)
		if value == true:
			if is_instance_valid(%cardManager):
				%cardManager.force_unhighlight_all_cards()

func _ready() -> void:
	battleEngine = HoldoutBattleEngine.new()
	add_child(battleEngine)
	
	$"../arena/HoldoutIntro".show()
	HoldoutStats.replayedRound = false
	
	$"../battleTimer".wait_time = opponentThinkingTime
	$"../cardManager".connect("characterPlayed", Callable(self, "_on_player_character_played"))
	$"../cardManager".connect("supportPlayed", Callable(self, "_on_player_support_played"))
	
	# Tutorial from main menu intercept
	if GameStats.gameMode == GameStats.Mode.HOLDOUT_TUTORIAL:
		$"../arena/HoldoutIntro".hide()
		
		HoldoutStats.currentPlayer = Actor.Avatar.JUNE
		HoldoutStats.playerHealthValue = 99
		HoldoutStats.playerHealthAtRoundStart = 99
		ui.update_health(Actor.Type.PLAYER, HoldoutStats.playerHealthValue, true)
		
		call_deferred("start_tutorial")
		return
	
	if SaveManager.isLoadingSave:
		await _load_game_from_snapshot()
		SaveManager.isLoadingSave = false
	else:
		prepare_opponent()
		
		HoldoutStats.currentPlayer = Actor.Avatar.JUNE
		HoldoutStats.playerHealthValue = 99
		HoldoutStats.playerHealthAtRoundStart = 99
		
		ui.update_health(Actor.Type.PLAYER, HoldoutStats.playerHealthValue, true)
		GameStats.gameMode = GameStats.Mode.HOLDOUT

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
	
	if battleEngine.has_modifier(Database.Modifier.INFECTED_DECK):
		$"../characterDeck".deck = Database.infectedHeavyCharacterDeck.duplicate()
		$"../supportDeck".deck = Database.infectedHeavySupportDeck.duplicate()
	elif battleEngine.has_modifier(Database.Modifier.HUMANITY_RESTORED): 
		$"../characterDeck".deck = Database.humanityRestoredCharacterDeck.duplicate()
		$"../supportDeck".deck = Database.humanityRestoredSupportDeck.duplicate()
	else:
		$"../characterDeck".deck = Database.standardCharacterDeck.duplicate()
		$"../supportDeck".deck = Database.standardSupportDeck.duplicate()
	
	$"../characterDeck".deck.shuffle()
	$"../supportDeck".deck.shuffle()
	
	await _draw_cards_at_start(false)
	
	battleEngine.start_new_round(battleEngine.has_modifier(Database.Modifier.ALWAYS_FIRST), 1)
	
	ui.set_indicator(Actor.Type.PLAYER)
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
	
	if battleEngine.has_modifier(Database.Modifier.SUPPLY_LINE):
		await get_tree().create_timer(opponentThinkingTime).timeout
		%cardManager.play_top_character_from_deck()
	
	lockPlayerInput = false
	battleEngine.isRoundActive = true
	
	%bubbleContainer.render_active_modifiers()
	
	_save_round_checkpoint()

func add_modifier(modifier: Database.Modifier) -> void:
	var instance = Database.MODIFIERS[modifier].duplicate(true)
	instance["currentDuration"] = 0
	
	HoldoutStats.activeModifiers.append(instance)
	HoldoutStats.multiplierTotal += instance["multiplier"]
	
	battleEngine.add_modifier(modifier)
	
	if modifier == Database.Modifier.FORSAKEN_HONOR:
		ui.update_health(Actor.Type.PLAYER, HoldoutStats.playerHealthValue - 20)

func remove_modifier(modifier: Database.Modifier) -> void:
	for i in range(HoldoutStats.activeModifiers.size() - 1, -1, -1):
		if HoldoutStats.activeModifiers[i].get("id") == modifier:
			HoldoutStats.multiplierTotal -= HoldoutStats.activeModifiers[i]["multiplier"]
			HoldoutStats.activeModifiers.remove_at(i)
			break
			
	battleEngine.remove_modifier(modifier)

# --- PRIVATES ---
func _initialize_opponent(player: Actor.Avatar, opponent: Actor.Avatar) -> void:
	ui.setup_avatar(player, Actor.Type.PLAYER)
	
	match opponent:
		Actor.Avatar.DUMMY:
			ui.setup_avatar(opponent, Actor.Type.OPPONENT)
			opponentAI = OpponentAITutorialDummy.new()
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
	
	if isTutorialActive:
		advance_tutorial("player_played_character", card)
	
	if opponentCharacterCard != null:
		await _apply_mid_round_perks()
		_transition_to_support_phase()
	else:
		battleEngine.player_played_character()
		_execute_opponent_character_play()
	
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)

func _execute_opponent_character_play() -> void:
	ui.set_indicator(Actor.Type.OPPONENT)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.THINKING)
	lockPlayerInput = true
	await get_tree().create_timer(opponentThinkingTime).timeout
	
	var card = opponentAI.play_character_card(opponentHand, playerHand)
	card.cardSlot = opponentCharacterCardSlot
	
	_animate_opponent_playing_card(card, opponentCharacterCardSlot)
	opponentCharacterCard = card
	
	ui.set_indicator(Actor.Type.PLAYER)
	
	if playerCharacterCard != null:
		ui.show_end_turn_button()
		await _apply_mid_round_perks()
		_transition_to_support_phase()
	else:
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
		lockPlayerInput = false
		battleEngine.opponent_played_character()
		
		if battleEngine.has_modifier(Database.Modifier.SUPPLY_LINE):
			ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
			await get_tree().create_timer(opponentThinkingTime).timeout
			%cardManager.play_top_character_from_deck()
	
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)

func _transition_to_support_phase() -> void:
	lockPlayerInput = false
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
	
	_update_playable_support_cards()
	
	if isTutorialActive:
		advance_tutorial("support_phase_started")
	
	if battleEngine.whoStartedRound == Actor.Type.PLAYER:
		battleEngine.set_phase(battleEngine.RoundStage.PLAYER_SUPPORT)
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
	else:
		battleEngine.set_phase(battleEngine.RoundStage.OPPONENT_SUPPORT)
		ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.THINKING)
		_execute_opponent_support_play()

func _on_player_support_played(card: Node2D) -> void:
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)
	ui.show_end_turn_button(false)
	
	playerSupportCard = card
	
	if isTutorialActive:
		advance_tutorial("player_played_support", card)
	
	HoldoutStats.record_played_card("Support", playerSupportCard.cardKey, playerSupportCard.value)
	
	await _apply_player_support(playerSupportCard, opponentCharacterCard, playerCharacterCard)
	
	battleEngine.player_played_support()
	
	if battleEngine.whoStartedRound == Actor.Type.PLAYER:
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
	
	await get_tree().create_timer(opponentThinkingTime).timeout
	
	var card = opponentAI.choose_support_card(opponentHand, opponentCharacterCard, playerCharacterCard)
	
	if card != null:
		card.cardSlot = opponentSupportCardSlot
		_animate_opponent_playing_card(card, opponentSupportCardSlot)
		opponentSupportCard = card
		
		HoldoutStats.record_played_card("Support", opponentSupportCard.cardKey, opponentSupportCard.value, true)
		
		await _apply_opponent_support(opponentSupportCard, playerCharacterCard, opponentCharacterCard)
	
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
	
	battleEngine.opponent_played_support()
	
	if battleEngine.whoStartedRound == Actor.Type.PLAYER:
		ui.set_indicator(Actor.Type.NONE)
		await _apply_end_round_perks()
		_transition_to_resolution_phase()
	else:
		lockPlayerInput = false
		ui.set_indicator(Actor.Type.PLAYER)
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
		ui.show_end_turn_button()

	opponentPlayedSupport = true

func _transition_to_resolution_phase() -> void:
	battleEngine.set_phase(battleEngine.RoundStage.END_CALCULATION)
	
	if battleEngine.has_modifier(Database.Modifier.DESPERATE_MEASURES) and !_is_player_support_matched():
		playerCharacterCard.get_node("ModifierIndicator").texture = load("res://assets/modifiers/Desperate Measures.png")
		playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
		await _deal_damage(Actor.Type.PLAYER, 3)
	
	if battleEngine.has_modifier(Database.Modifier.STACKED_ODDS):
		opponentCharacterCard.get_node("ModifierIndicator").texture = load("res://assets/modifiers/Stacked Odds.png")
		opponentCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
		opponentCharacterCard.modify_value(1)
	
	await _calculate_damage()
	await get_tree().create_timer(endRoundTime).timeout
	
	var playerHealth = ui.get_health(Actor.Type.PLAYER)
	var opponentHealth = ui.get_health(Actor.Type.OPPONENT)
	
	if playerHealth <= 0 or opponentHealth <= 0:
		if isTutorialRun:
			await _conclude_tutorial_match()
		else:
			await _conclude_match()
		return
	
	var cardsToDiscard = []
	if playerSupportCard: cardsToDiscard.append(playerSupportCard)
	cardsToDiscard.append(playerCharacterCard)
	cardsToDiscard.append(opponentCharacterCard)
	if opponentSupportCard: cardsToDiscard.append(opponentSupportCard)
	
	await _move_cards_to_discard(cardsToDiscard)
	ui.show_end_turn_button(false)
	
	await _repopulate_hand(playerHand, Actor.Type.PLAYER)
	await _repopulate_hand(opponentHand, Actor.Type.OPPONENT)
	
	battleEngine.end_round_cleanup(playerCharacterCard.faction, playerCharacterCard.role)
	
	cardsToDiscard = []
	_start_new_round()

func _conclude_match() -> void:
	battleEngine.isRoundActive = true
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
	
	if ui.get_health(Actor.Type.PLAYER) <= 0:
		SaveManager.clear_holdout_save()
	else:
		_save_round_checkpoint()
	
	GameStats.push_holdout_battle_stats(ui.get_health(Actor.Type.PLAYER) > 0)

func _start_new_round() -> void:
	playerCharacterCard = null
	playerSupportCard = null
	opponentCharacterCard = null
	opponentSupportCard = null
	
	opponentPlayedSupport = false
	ui.show_end_turn_button(false)
	
	await _repopulate_decks()
	_apply_guerrilla_tactics_restrictions()
	
	if isTutorialActive:
		advance_tutorial("round_started")
	
	battleEngine.start_new_round(battleEngine.has_modifier(Database.Modifier.ALWAYS_FIRST), HoldoutStats.roundsPlayed)
	
	if battleEngine.whoStartedRound == Actor.Type.OPPONENT:
		ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.THINKING)
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)
		_execute_opponent_character_play()
	else:
		ui.set_indicator(Actor.Type.PLAYER)
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
		ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
		
		if battleEngine.has_modifier(Database.Modifier.SUPPLY_LINE):
			await get_tree().create_timer(opponentThinkingTime).timeout
			%cardManager.play_top_character_from_deck()
		
		lockPlayerInput = false
	
	_save_round_checkpoint()

func _on_end_turn_button_pressed() -> void:
	if isTutorialActive and (tutorialStep == 4 or tutorialStep == 5 or tutorialStep == 6):
		return
	
	ui.show_end_turn_button(false)
	
	if tutorialStep == 2:
		tutorialAnimationPlayer.play_backwards("show_tutorial_box")
		await tutorialAnimationPlayer.animation_finished
	
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)
	
	lockPlayerInput = true
	
	if !opponentPlayedSupport:
		_execute_opponent_support_play()
		return

	ui.set_indicator(Actor.Type.NONE)
	await _apply_end_round_perks()
	_transition_to_resolution_phase()

# --- HELPERS ---
func _draw_cards_at_start(firstStart: bool = true) -> void:
	%pauseIcon.hide()
	
	if firstStart:
		await $"../characterDeck".ready
		await $"../supportDeck".ready
		await get_tree().create_timer(.5).timeout
	
	GameStats.gameMode = GameStats.Mode.CARD_DRAW
	
	var characterDrawLoop = max(battleEngine.maxCharacterCards, battleEngine.opponentMaxCards)
	
	for i in range(characterDrawLoop):
		if i < battleEngine.maxCharacterCards:
			await get_tree().create_timer(cardMoveFastSpeed).timeout
			$"../characterDeck".draw_card()
			
		if i < battleEngine.opponentMaxCards:
			await get_tree().create_timer(cardMoveFastSpeed).timeout
			$"../characterDeck".draw_opponent_card()
	
	var supportDrawLoop = max(battleEngine.maxSupportCards, battleEngine.opponentMaxCards)

	for i in range(supportDrawLoop):
		if i < battleEngine.maxSupportCards:
			await get_tree().create_timer(cardMoveFastSpeed).timeout
			$"../supportDeck".draw_card()
			
		if i < battleEngine.opponentMaxCards:
			await get_tree().create_timer(cardMoveFastSpeed).timeout
			$"../supportDeck".draw_opponent_card()
	
	GameStats.gameMode = GameStats.Mode.HOLDOUT
	
	%pauseIcon.show()

func _pick_next_opponent() -> Actor.Avatar:
	if HoldoutStats.opponentList.is_empty():
		assert(GameStats.gameMode == GameStats.Mode.HOLDOUT, "CRITICAL: holdoutBattle.gd run without HOLDOUT mode set. RUn the game fully or load from the Main Menu.")
		
		var list = Database.AVATARS.keys()
		
		if HoldoutStats.currentPlayer in list:
			list.erase(HoldoutStats.currentPlayer)
			
		if Actor.Avatar.DUMMY in list:
			list.erase(Actor.Avatar.DUMMY)
		
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
	tween.tween_property(opponentCard, "position", opponentCardSlot.position, cardMoveSpeed)
	
	$"../opponentHand".remove_card_from_hand(opponentCard)

func _apply_mid_round_perks() -> void:
	if isTutorialActive and not arePerksActiveInTutorial:
		return
		
	if battleEngine.has_modifier(Database.Modifier.FRIENDLY_FIRE) and (playerCharacterCard.faction == opponentCharacterCard.faction):
		await get_tree().create_timer(0.3).timeout
		playerCharacterCard.get_node("ModifierIndicator").texture = load("res://assets/modifiers/Friendly Fire.png")
		playerCharacterCard.get_node("AnimationPlayer").queue("modifierIndicator")
		playerCharacterCard.modify_value(-int(ceil(playerCharacterCard.value / 2.0)))
		await playerCharacterCard.get_node("AnimationPlayer").animation_finished
	
	if battleEngine.whoStartedRound == Actor.Type.PLAYER:
		await _execute_player_mid_perk()
		await _execute_opponent_mid_perk()
	else:
		await _execute_opponent_mid_perk()
		await _execute_player_mid_perk()
	
	if battleEngine.has_modifier(Database.Modifier.HEAVY_HITTER) && playerCharacterCard.value >= 5:
		playerCharacterCard.get_node("ModifierIndicator").texture = load("res://assets/modifiers/Heavy Hitter.png")
		playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
		await _deal_damage(Actor.Type.PLAYER, 1)
	
	_handle_runner_perk()

func _update_playable_support_cards() -> void:
	for card in playerHand:
		if is_instance_valid(card) and card.type == "Support":
			if battleEngine.has_modifier(Database.Modifier.DESPERATE_MEASURES):
				card.canBePlayed = true
			else:
				card.canBePlayed = battleEngine.check_support_match(playerCharacterCard.role, card.role)
	
	for card in opponentHand:
		if is_instance_valid(card) and card.type == "Support":
			card.canBePlayed = battleEngine.check_support_match(opponentCharacterCard.role, card.role)

func _apply_end_round_perks() -> void:
	if isTutorialActive and not arePerksActiveInTutorial:
		return
		
	if battleEngine.whoStartedRound == Actor.Type.PLAYER:
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

	await get_tree().create_timer(perkCalculationTime).timeout

func _calculate_damage() -> void:
	var playerTotal = playerCharacterCard.value
	var opponentTotal = opponentCharacterCard.value
	
	HoldoutStats.record_played_card(playerCharacterCard.faction, playerCharacterCard.cardKey, playerTotal)
	HoldoutStats.record_played_card(opponentCharacterCard.faction, opponentCharacterCard.cardKey, opponentTotal, true)
	
	_apply_calculation_round_perks(playerTotal, opponentTotal)
	
	var report = battleEngine.process_combat_stats(playerTotal, opponentTotal, playerCharacterCard.cardKey, opponentCharacterCard.cardKey)
	
	if report.triggerOverExertion:
		playerCharacterCard.get_node("ModifierIndicator").texture = load("res://assets/modifiers/Over Exertion.png")
		playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
		_deal_damage(Actor.Type.PLAYER, 1)
		await _deal_damage(Actor.Type.OPPONENT, 2)
	
	if report.winner == battleEngine.Winner.PLAYER:
		await _handle_player_win(report.damage, report.triggerCalculatedRisk)
	elif report.winner == battleEngine.Winner.OPPONENT:
		await _handle_opponent_win(report.damage, report.triggerDeepWounds)
	
	if battleEngine.has_modifier(Database.Modifier.SLOW_BLEED) and HoldoutStats.roundsPlayed % 2 == 0 and Database.MODIFIERS.has(Database.Modifier.SLOW_BLEED):
		await _deal_damage(Actor.Type.PLAYER, Database.MODIFIERS.get(Database.Modifier.SLOW_BLEED)["amount"])
	
	if battleEngine.has_modifier(Database.Modifier.CARD_ROT) and HoldoutStats.roundsPlayed % 3 == 0:
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
	if isTutorialActive and not arePerksActiveInTutorial:
		return
		
	if battleEngine.whoStartedRound == Actor.Type.PLAYER:
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
		tween.tween_property(card, "position", discardPilePosition, cardMoveFastSpeed)
		
		await tween.finished
	
	$"../cardSlots/cardSlotSupport".occupied = false
	$"../cardSlots/cardSlotCharacter".occupied = false
	
	if HoldoutStats.roundsPlayed % 2 == 0 and battleEngine.has_modifier(Database.Modifier.VOLATILE_HAND) and GameStats.gameMode == GameStats.Mode.HOLDOUT:
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
		while characterCount < battleEngine.maxCharacterCards:
			characterDeckReference.draw_card()
			characterCount += 1
			await get_tree().create_timer(cardMoveSpeed).timeout
	else:
		@warning_ignore("integer_division")
		while characterCount < battleEngine.opponentMaxCards:
			characterDeckReference.draw_opponent_card()
			characterCount += 1
			await get_tree().create_timer(cardMoveSpeed).timeout
	
	if who == Actor.Type.PLAYER:
		while supportCount < battleEngine.maxSupportCards:
			supportDeckReference.draw_card()
			supportCount += 1
			await get_tree().create_timer(cardMoveSpeed).timeout
	else:
		@warning_ignore("integer_division")
		while supportCount < battleEngine.opponentMaxCards:
			supportDeckReference.draw_opponent_card()
			supportCount += 1
			await get_tree().create_timer(cardMoveSpeed).timeout
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
	
	if $"../supportDeck".deck.size() < battleEngine.minCardsForReshuffle:
		discardedCards = discardedCharactersReversed + discardedSupportsReversed
		
		for i in range(discardedSupportsReversed.size()):
			discardedSupportsReversed[i].z_index = 100 - i
		
		$"../supportDeck".reshuffle_from_discards(discardedSupportsReversed)
		for card in discardedSupportsReversed:
			discardedCards.erase(card)
		
		return
	
	if $"../characterDeck".deck.size() < battleEngine.minCardsForReshuffle:
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
	tween.tween_property(card, "position", discardPilePosition, cardMoveFastSpeed)
	
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

func _handle_player_win(damage: int, triggerCalculatedRisk: bool) -> void:
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.HAPPY)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.HURT)
	
	if opponentCharacterCard.cardKey == "Owen":
		await get_tree().create_timer(perkCalculationTimeAfterRoundEnd).timeout
		return
	
	await _deal_damage(Actor.Type.OPPONENT, damage, false)
	await _handle_shambler_perk(Actor.Type.PLAYER)
	
	if playerCharacterCard.perkValueAtRoundEnd:
		await _deal_damage(Actor.Type.OPPONENT, playerCharacterCard.perkValueAtRoundEnd)
	
	if triggerCalculatedRisk:
		playerCharacterCard.get_node("ModifierIndicator").texture = load("res://assets/modifiers/Calculated Risk.png")
		playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
		await _deal_damage(Actor.Type.OPPONENT, 3)

func _handle_opponent_win(damage: int, triggerDeepWounds: bool) -> void:
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.HURT)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.HAPPY)
	
	if playerCharacterCard.cardKey == "Owen":
		await get_tree().create_timer(perkCalculationTimeAfterRoundEnd).timeout
		return
	
	await _deal_damage(Actor.Type.PLAYER, damage, false)
	await _handle_shambler_perk(Actor.Type.OPPONENT)
	
	if opponentCharacterCard.perkValueAtRoundEnd: 
		await _deal_damage(Actor.Type.PLAYER, opponentCharacterCard.perkValueAtRoundEnd)
	
	if triggerDeepWounds:
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
		await get_tree().create_timer(perkCalculationTimeAfterRoundEnd).timeout
	
	var currentHealth = ui.get_health(who)
	currentHealth -= amount
	ui.update_health(who, currentHealth)
	
	await ui.play_damage_effect(who, amount)

func _apply_guerrilla_tactics_restrictions() -> void:
	for card in playerHand:
		if card.type == "Character":
			card.canBePlayed = true
	
	if not battleEngine.has_modifier(Database.Modifier.GUERRILLA_TACTICS) or battleEngine.previous_round_faction == "":
		for card in playerHand:
			if card.type == "Character":
				_animate_card_unlock(card)
		return
	
	var cardsToLock: Array = []
	for card in playerHand:
		if card.type == "Character":
			var isRestricted = battleEngine.check_guerrilla_restriction(card.faction, card.role)
			if isRestricted:
				cardsToLock.append(card)
	
	var totalCharacters: int = 0
	for card in playerHand:
		if is_instance_valid(card) and card.type == "Character":
			totalCharacters += 1
			
	var failSafeActive = (totalCharacters > 0 and cardsToLock.size() == totalCharacters)
	
	if failSafeActive:
		for card in cardsToLock:
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
				if card in cardsToLock:
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
		
	return battleEngine.check_support_match(playerCharacterCard.role, playerSupportCard.role)

func _check_old_wounds_accolade() -> void:
	if HoldoutStats.RIVALRIES.has(playerCharacterCard.cardKey):
		var rivals = HoldoutStats.RIVALRIES[playerCharacterCard.cardKey]
		if opponentCharacterCard.cardKey in rivals:
			HoldoutStats.achievedOldWounds = true

# --- PERK HELPERS ---
func _execute_player_mid_perk() -> void:
	if playerCharacterCard.perk && playerCharacterCard.perk.timing == "midRound":
		await get_tree().create_timer(perkCalculationTime).timeout
		await playerCharacterCard.perk.apply_mid_perk(playerCharacterCard, playerHand, opponentCharacterCard)

func _execute_opponent_mid_perk() -> void:
	if opponentCharacterCard.perk && opponentCharacterCard.perk.timing == "midRound":
		var playerRealRole = playerCharacterCard.role
		var playerRealFaction = playerCharacterCard.faction
		
		if battleEngine.has_modifier(Database.Modifier.FORSAKEN_HONOR):
			if opponentCharacterCard.perk.has_method("would_perk_trigger") and opponentCharacterCard.perk.would_perk_trigger(opponentCharacterCard, opponentHand, playerCharacterCard):
				playerCharacterCard.get_node("ModifierIndicator").texture = load("res://assets/modifiers/Forsaken Honor.png")
				playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
				await playerCharacterCard.get_node("AnimationPlayer").animation_finished
			
			playerCharacterCard.role = "Unknown"
			playerCharacterCard.faction = "Unknown"
		
		await get_tree().create_timer(perkCalculationTime).timeout
		await opponentCharacterCard.perk.apply_mid_perk(opponentCharacterCard, opponentHand, playerCharacterCard)
		
		if battleEngine.has_modifier(Database.Modifier.FORSAKEN_HONOR):
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
		
		if battleEngine.has_modifier(Database.Modifier.FORSAKEN_HONOR):
			if opponentCharacterCard.perk.has_method("would_perk_trigger") and opponentCharacterCard.perk.would_perk_trigger(opponentCharacterCard, opponentSupportCard, playerCharacterCard, playerSupportCard, opponentHand):
				playerCharacterCard.get_node("ModifierIndicator").texture = load("res://assets/modifiers/Forsaken Honor.png")
				playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
				await playerCharacterCard.get_node("AnimationPlayer").animation_finished
			
			playerCharacterCard.role = "Unknown"
			playerCharacterCard.faction = "Unknown"
			
		await opponentCharacterCard.perk.apply_end_perk(opponentCharacterCard, opponentSupportCard, playerCharacterCard, playerSupportCard, opponentHand)
		
		if battleEngine.has_modifier(Database.Modifier.FORSAKEN_HONOR):
			playerCharacterCard.role = playerRealRole
			playerCharacterCard.faction = playerRealFaction
			_update_playable_support_cards()

func _execute_player_supp_end_perk() -> void:
	if playerSupportCard && playerSupportCard.perk && playerSupportCard.perk.timing == "endRound":
		await playerSupportCard.perk.apply_end_perk(playerCharacterCard, playerSupportCard, opponentCharacterCard, opponentSupportCard, playerHand)

func _execute_opponent_supp_end_perk() -> void:
	if opponentSupportCard && opponentSupportCard.perk && opponentSupportCard.perk.timing == "endRound":
		await get_tree().create_timer(perkCalculationTime).timeout
		await opponentSupportCard.perk.apply_end_perk(opponentCharacterCard, opponentSupportCard, playerCharacterCard, playerSupportCard, opponentHand)

func _execute_player_late_end_perk() -> void:
	if playerCharacterCard.perk && playerCharacterCard.perk.timing == "lateEndRound":
		await get_tree().create_timer(perkCalculationTime).timeout
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

# --- SAVE & LOAD EXTRACTORS ---
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
	var arenaData = battleEngine.get_engine_save_dict()

	arenaData["opponentHealth"] = ui.get_health(Actor.Type.OPPONENT)
	arenaData["characterDeck"] = $"../characterDeck".deck
	arenaData["supportDeck"] = $"../supportDeck".deck
	arenaData["playerHand"] = _get_card_array_save_data(playerHand)
	arenaData["opponentHand"] = _get_card_array_save_data(opponentHand)
	arenaData["discardedCards"] = _get_card_array_save_data(discardedCards)
	
	return arenaData

func _save_round_checkpoint() -> void:
	if SaveManager.isLoadingSave or isTutorialRun:
		return

	var fullSaveData = {
		"stats": HoldoutStats.get_save_dict(),
		"arena": get_arena_save_dict()
	}
	
	SaveManager.save_holdout_state(fullSaveData)

func _load_game_from_snapshot() -> void:
	var saveData = SaveManager.load_holdout_state()
	
	if saveData.is_empty():
		printerr("Save data corrupted.")
		
		%saveFileCorrupt.modulate.a = 1.0
		HoldoutStats.currentPlayer = Actor.Avatar.JUNE
		HoldoutStats.playerHealthValue = 99
		HoldoutStats.playerHealthAtRoundStart = 99
		
		ui.update_health(Actor.Type.PLAYER, HoldoutStats.playerHealthValue, true)
		prepare_opponent()
		
		$"../arena/saveFileCorrupt/CorruptStartNewRunButton".mouse_entered.connect(AudioManager.play_button_hover)
		$"../arena/saveFileCorrupt/CorruptStartNewRunButton".focus_mode = Control.FOCUS_NONE
		$"../arena/saveFileCorrupt/CorruptStartNewRunButton".pressed.connect(AudioManager.play_button_click)
		
		$"../arena/saveFileCorrupt/CorruptMainMenuButton".mouse_entered.connect(AudioManager.play_button_hover)
		$"../arena/saveFileCorrupt/CorruptMainMenuButton".focus_mode = Control.FOCUS_NONE
		$"../arena/saveFileCorrupt/CorruptMainMenuButton".pressed.connect(AudioManager.play_button_click)
		
		%saveFileCorrupt.visible = true
		%pauseIcon.visible = false
		return
		
	var stats = saveData["stats"]
	var arena = saveData["arena"]
	
	HoldoutStats.load_save_dict(stats)
	
	battleEngine.load_engine_save_dict(arena)
	
	# If coming from the main menu on a round win
	if arena.has("opponentHealth") and int(arena["opponentHealth"]) <= 0:
		await get_tree().process_frame 
		
		ui.update_health(Actor.Type.PLAYER, HoldoutStats.playerHealthValue, true)
		
		HoldoutStats.replayedRound = false
		HoldoutStats.totalRunRations = HoldoutStats.currentRunRations
		GameStats.gameMode = GameStats.Mode.HOLDOUT
		
		ui.holdoutEndScreenAnimator.handle_modifier_durations()
		ui._reset_board_state()
		
		prepare_opponent()
		
		if HoldoutStats.numberOfWins % 2 == 1 and not HoldoutStats.replayedRound:
			GameStats.gameMode = GameStats.Mode.MODIFIER_SELECTION
			ui.modifierUI.show_modifier_menu()
		else:
			initialize_game()
			
		return
	
	_initialize_opponent(HoldoutStats.currentPlayer, HoldoutStats.currentOpponent)
	
	ui.update_health(Actor.Type.PLAYER, HoldoutStats.playerHealthValue, true)
	if arena.has("opponentHealth"): 
		ui.update_health(Actor.Type.OPPONENT, arena["opponentHealth"], true)
	
	seed(HoldoutStats.currentBattleSeed) 
	
	$"../characterDeck".deck = arena["characterDeck"]
	$"../supportDeck".deck = arena["supportDeck"]
	
	await get_tree().process_frame
	
	%playerHand.centerScreenX = get_viewport().get_visible_rect().size.x / 2.0
	%opponentHand.centerScreenX = get_viewport().get_visible_rect().size.x / 2.0
	
	_rebuild_cards_from_save(arena["playerHand"], %playerHand)
	_rebuild_cards_from_save(arena["opponentHand"], %opponentHand)
	
	for saved_card in arena["discardedCards"]:
		var new_card = _spawn_single_card(saved_card)
		new_card.position = discardPilePosition
		new_card.scale = Vector2(1, 1)
		new_card.z_index = discardedCardZIndex
		discardedCardZIndex += 1
		new_card.get_node("Area2D/CollisionShape2D").disabled = true
		discardedCards.append(new_card)
		$"../cardManager".add_child(new_card) 

	battleEngine.isRoundActive = true
	%pauseIcon.show()
	%bubbleContainer.render_active_modifiers()
	
	_apply_guerrilla_tactics_restrictions()
	
	if battleEngine.whoStartedRound == Actor.Type.PLAYER:
		ui.set_indicator(Actor.Type.PLAYER)
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
		ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
		lockPlayerInput = false
		
		if battleEngine.has_modifier(Database.Modifier.SUPPLY_LINE):
			await get_tree().create_timer(opponentThinkingTime).timeout
			%cardManager.play_top_character_from_deck()
	else:
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

func _on_corrupt_start_new_run_button_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(%saveFileCorrupt, "modulate:a", 0.0, 0.2)
	await tween.finished
	
	%saveFileCorrupt.visible = false
	
	initialize_game()

# --- TUTORIAL ---
var isTutorialRun: bool = false
var isTutorialActive: bool = false
var arePerksActiveInTutorial: bool = false
var tutorialStep: int = 0
@onready var tutorialAnimationPlayer = $"../arena/tutorialBox/AnimationPlayer"

func start_tutorial() -> void:
	isTutorialRun = true
	isTutorialActive = true
	tutorialStep = 1
	
	HoldoutStats.currentOpponent = Actor.Avatar.DUMMY 
	_initialize_opponent(HoldoutStats.currentPlayer, HoldoutStats.currentOpponent)
	
	%pauseIcon.show()
	
	$"../characterDeck".deck = Database.tutorialCharacterDeck.duplicate()
	$"../supportDeck".deck = Database.tutorialSupportDeck.duplicate()
	
	battleEngine.whoStartedRound = Actor.Type.PLAYER
	battleEngine.roundStage = battleEngine.RoundStage.PLAYER_CHARACTER
	
	ui.set_indicator(Actor.Type.PLAYER)
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
	
	lockPlayerInput = false
	battleEngine.isRoundActive = true
	
	await _draw_cards_at_start(false)
	
	%number.text = "1/6"
	%heading.text = "Character Cards"
	%instruction.text = "A character's value is located in the top-left corner of the card.\n\nClick and drag Marlene to the Character Slot to play her.\n\nAlternatively you can double click to instantly play it."
	%Box.size.y = 450
	
	_update_tutorial_card_locks(tutorialStep)
	
	await get_tree().create_timer(0.75).timeout
	
	tutorialAnimationPlayer.play("show_tutorial_box")
	await tutorialAnimationPlayer.animation_finished

func _update_tutorial_card_locks(step: int) -> void:
	var allowed_card_keys: Array = []
	var enforce_tutorial_locks: bool = true
	
	match step:
		1:
			allowed_card_keys = ["Marlene"]
		2:
			allowed_card_keys = [] 
			enforce_tutorial_locks = true
		3:  
			allowed_card_keys = ["Li"] 
			enforce_tutorial_locks = true
		4:
			allowed_card_keys = ["Resilience"]
			enforce_tutorial_locks = true 
		5:
			allowed_card_keys = ["Dina"]
			enforce_tutorial_locks = true
		6:
			enforce_tutorial_locks = false
		_:
			enforce_tutorial_locks = false
			
	for card in playerHand:
		if not is_instance_valid(card):
			continue
			
		if enforce_tutorial_locks:
			card.canBePlayed = (card.cardKey in allowed_card_keys)
		else:
			if card.type == "Character":
				card.canBePlayed = true

func advance_tutorial(trigger: String, card: Node2D = null) -> void:
	if not isTutorialActive:
		return
		
	match tutorialStep:
		1:
			if trigger == "player_played_character" and card.cardKey == "Marlene":
				tutorialStep = 2
				
				tutorialAnimationPlayer.play_backwards("show_tutorial_box")
				await tutorialAnimationPlayer.animation_finished
				
				if opponentAI is OpponentAITutorialDummy:
					opponentAI.forcedCharacterKey = "Runner"
					opponentAI.forcedSupportKey = ""
				
				%number.text = "2/6"
				%heading.text = "Dealing Damage"
				%instruction.text = "The damage dealt is the difference between your value and your opponent’s.\n\nClick End Turn to resolve combat."
				%Box.size.y = 330
				
				await get_tree().create_timer(0.75).timeout
				
				tutorialAnimationPlayer.play("show_tutorial_box")
				await tutorialAnimationPlayer.animation_finished
		2:
			if trigger == "support_phase_started":
				_update_tutorial_card_locks(tutorialStep)
			elif trigger == "round_started":
				tutorialStep = 3
				if opponentAI is OpponentAITutorialDummy:
					opponentAI.forcedCharacterKey = "Tommy"
					opponentAI.forcedSupportKey = ""
				
				await get_tree().create_timer(1.5).timeout
				
				%number.text = "3/6"
				%heading.text = "Character Cards"
				%instruction.text = "Play Li."
				%Box.size.y = 180
				
				tutorialAnimationPlayer.play("show_tutorial_box")
				await tutorialAnimationPlayer.animation_finished
				
				_update_tutorial_card_locks(tutorialStep)
		3:
			if trigger == "player_played_character":
				tutorialStep = 4
				tutorialAnimationPlayer.play_backwards("show_tutorial_box")
				await tutorialAnimationPlayer.animation_finished
		4:
			if trigger == "support_phase_started":
				_update_tutorial_card_locks(tutorialStep)
				ui.show_end_turn_button(false)
				
				await get_tree().create_timer(1.5).timeout
				
				%number.text = "4/6"
				%heading.text = "Support Cards"
				%instruction.text = "Support cards are optional. They can be played after your character to tactically boost your value in battle.\n\nYour opponent chose not to play a support.\n\nPlay a support card that matches Li's card type."
				%Box.size.y = 480
				
				tutorialAnimationPlayer.play("show_tutorial_box")
				await tutorialAnimationPlayer.animation_finished
			elif trigger == "player_played_support":
				tutorialAnimationPlayer.play_backwards("show_tutorial_box")
				await tutorialAnimationPlayer.animation_finished
			elif trigger == "round_started":
				tutorialStep = 5
				arePerksActiveInTutorial = true
				
				if opponentAI is OpponentAITutorialDummy:
					opponentAI.forcedCharacterKey = "SeraphiteInitiate"
					opponentAI.forcedSupportKey = "ScavengedParts"
				
				_update_tutorial_card_locks(tutorialStep)
				
				await get_tree().create_timer(0.75).timeout
				
				%number.text = "5/6"
				%heading.text = "Card Perks"
				%instruction.text = "All Characters have perks.\n\nPerks offer additional boosts if the requirements are met.\n\nHover over Dina to view her perk, then play her."
				%Box.size.y = 400
				
				tutorialAnimationPlayer.play("show_tutorial_box")
				await tutorialAnimationPlayer.animation_finished
		5:
			if trigger == "player_played_character" and card.cardKey == "Dina":
				tutorialAnimationPlayer.play_backwards("show_tutorial_box")
				await tutorialAnimationPlayer.animation_finished
			if trigger == "support_phase_started":
				tutorialStep = 6
				
				_update_tutorial_card_locks(tutorialStep)
				
				%number.text = "6/6"
				%heading.text = "Conclusion"
				%instruction.text = "The combination of both supports and perks can swing a losing battle into a winning one.\n\nUse both wisely to deal more, or take less damage.\n\nPlay a matching support to deal additional damage."
				%Box.size.y = 470
				
				tutorialAnimationPlayer.play("show_tutorial_box")
				await tutorialAnimationPlayer.animation_finished
		6:
			if trigger == "player_played_support":
				tutorialAnimationPlayer.play_backwards("show_tutorial_box")
				await tutorialAnimationPlayer.animation_finished
				
				isTutorialActive = false

func _conclude_tutorial_match() -> void:
	battleEngine.isRoundActive = false
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
	
	endScreenAnimator.play_holdout_tutorial_end_sequence()
	
	await _repopulate_decks(true)
	discardedCardZIndex = 1
	
	GameStats.showHoldoutTutorial = false
	GameStats.save_game()
