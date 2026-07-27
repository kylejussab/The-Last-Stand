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

var playerCardScene = preload("res://core/cards/card.tscn")
var opponentCardScene = preload("res://core/cards/opponentCard.tscn")

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

const BACKFIRE_CAPABLE = ["Molotov", "TrapMine", "ShotgunShells", "SmokeBomb", "Brick", "Bottle"]
const FACTION_FUNGUS_COLORS = {
	"Firefly": ["C2A23E", "9D7F2E", "4F4119"],
	"Infected": ["CD6429", "96371F", "6F2214"],
	"Jackson": ["546E32", "3D4F23", "29331B"],
	"Seraphite": ["8657A3", "724099", "4B2B74"],
	"WLF": ["81B0DE", "4A89C8", "185799"],
}

# --- UI SEQUENCE FLAGS ---
var opponentPlayedSupport: bool = false
var lockPlayerInput: bool = true:
	set(value):
		lockPlayerInput = value
		battleEngine.set_player_thinking(not value)
		if value == true:
			if is_instance_valid(%cardManager):
				%cardManager.force_unhighlight_all_cards()
var pendingDeepWoundsBonus: bool = false

func _ready() -> void:
	battleEngine = HoldoutBattleEngine.new()
	add_child(battleEngine)
	
	$"../arena/intro".show()
	HoldoutStats.replayedRound = false
	%phaseTracker.modulate.a = 0.0
	
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
	
	var maxIndex = Database.OPPONENT_HEALTH_AMOUNTS.size() - 1
	var roundIndex = mini(HoldoutStats.numberOfWins, maxIndex)
	
	ui.update_health(Actor.Type.OPPONENT, Database.OPPONENT_HEALTH_AMOUNTS[roundIndex], true)


func initialize_game() -> void:
	pendingDeepWoundsBonus = false
	
	if HoldoutStats.replayedRound:
		seed(HoldoutStats.currentBattleSeed)
		battleEngine.clear_history() # remove the combat history
	else:
		randomize() 
		HoldoutStats.currentBattleSeed = randi()
		seed(HoldoutStats.currentBattleSeed)
		
	%pauseIcon.show()
	
	if battleEngine.has_modifier(Database.Modifier.INFECTED_DECK):
		$"../characterDeck".deck = Database.build_run_deck(Database.infectedHeavyCharacterDeck)
		$"../supportDeck".deck = Database.build_run_deck(Database.infectedHeavySupportDeck)
	elif battleEngine.has_modifier(Database.Modifier.HUMANITY_RESTORED): 
		$"../characterDeck".deck = Database.build_run_deck(Database.humanityRestoredCharacterDeck)
		$"../supportDeck".deck = Database.build_run_deck(Database.humanityRestoredSupportDeck)
	else:
		$"../characterDeck".deck = Database.build_run_deck(Database.standardCharacterDeck)
		$"../supportDeck".deck = Database.build_run_deck(Database.standardSupportDeck)
	
	if opponentAI.has_method("initialize_deck"):
		opponentAI.initialize_deck($"../characterDeck".deck)
	
	$"../characterDeck".deck.shuffle()
	$"../supportDeck".deck.shuffle()
	
	await _draw_cards_at_start(false)
	
	if not isTutorialActive:
		var tween = get_tree().create_tween()
		tween.tween_property(%phaseTracker, "modulate:a", 1.0, perkCalculationTime)
	
	battleEngine.start_new_round(battleEngine.has_modifier(Database.Modifier.FRONT_RUNNER), 1)
	
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


func add_modifier(modifier: Database.Modifier, addToFront: bool = false) -> void:
	var instance = Database.MODIFIERS[modifier].duplicate(true)
	instance["currentDuration"] = 0
	
	if addToFront:
		HoldoutStats.activeModifiers.insert(0, instance)
	else:
		HoldoutStats.activeModifiers.append(instance)
	
	HoldoutStats.multiplierTotal += instance["multiplier"]
	
	battleEngine.add_modifier(modifier)
	
	if modifier == Database.Modifier.FORSAKEN_HONOR:
		_deal_damage(Actor.Type.PLAYER, Database.MODIFIERS[Database.Modifier.FORSAKEN_HONOR].healthCost)


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
			opponentAI = OpponentAIAggressive.new()
		Actor.Avatar.RHEA:
			ui.setup_avatar(opponent, Actor.Type.OPPONENT)
			opponentAI = OpponentAIAttrition.new()
		Actor.Avatar.KNEEL:
			ui.setup_avatar(opponent, Actor.Type.OPPONENT)
			opponentAI = OpponentAIBalanced.new()
		Actor.Avatar.ALLEY:
			ui.setup_avatar(opponent, Actor.Type.OPPONENT)
			opponentAI = OpponentAICalculator.new()
		Actor.Avatar.WARREN:
			ui.setup_avatar(opponent, Actor.Type.OPPONENT)
			opponentAI = OpponentAICounter.new()
		Actor.Avatar.MIRA:
			ui.setup_avatar(opponent, Actor.Type.OPPONENT)
			opponentAI = OpponentAIMomentum.new()
		Actor.Avatar.KAEL:
			ui.setup_avatar(opponent, Actor.Type.OPPONENT)
			opponentAI = OpponentAIPredictive.new()


func _on_player_character_played(card: Node2D) -> void:
	playerCharacterCard = card
	
	if pendingDeepWoundsBonus:
		pendingDeepWoundsBonus = false
		card.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Deep Wounds.png")
		card.get_node("AnimationPlayer").queue("modifierIndicator")
		card.modify_value(3)
		battleEngine.log_action("System. Deep Wounds modifier activated. " + card.nameText + " gained +3 from resolve.")
	
	if isTutorialActive:
		advance_tutorial("player_played_character", card)
	
	battleEngine.log_action("Player. You played " + card.nameText + ".")
	
	_play_dust_effect(playerCharacterCard)
	
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
	
	opponentAI.set_flip_script_active(battleEngine.has_modifier(Database.Modifier.FLIP_SCRIPT))
	
	var card = opponentAI.play_character_card(opponentHand, playerHand, playerCharacterCard)
	card.cardSlot = opponentCharacterCardSlot
	
	_animate_opponent_playing_card(card, opponentCharacterCardSlot)
	opponentCharacterCard = card
	
	if opponentAI.has_method("record_opponent_play"):
		opponentAI.record_opponent_play(card)
	
	var opponentName: String = Actor.Avatar.keys()[HoldoutStats.currentOpponent].capitalize()
	battleEngine.log_action("Opponent. " + opponentName + " played " + card.nameText + ".")
	
	if battleEngine.has_modifier(Database.Modifier.GAMBLER) and randf() <= battleEngine.gamblerChance:
		await get_tree().create_timer(opponentThinkingTime).timeout
		opponentCharacterCard.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Gambler.png")
		opponentCharacterCard.get_node("AnimationPlayer").queue("modifierIndicator")
		await opponentCharacterCard.get_node("AnimationPlayer").animation_finished
		
		opponentCharacterCard.modify_value(int(opponentCharacterCard.value / 2.0))
		
		battleEngine.log_action("System. Gambler modifier activated. " + opponentName + "'s " + opponentCharacterCard.nameText + " gained +" + str(int(opponentCharacterCard.value / 2.0)) + " value.")
		
	if playerCharacterCard != null:
		ui.show_end_turn_button()
		await _apply_mid_round_perks()
		_transition_to_support_phase()
	else:
		ui.set_indicator(Actor.Type.PLAYER)
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
	
	if battleEngine.get_support_starter() == Actor.Type.PLAYER:
		battleEngine.set_phase(battleEngine.RoundStage.PLAYER_SUPPORT)
		ui.set_indicator(Actor.Type.PLAYER)
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
	else:
		battleEngine.set_phase(battleEngine.RoundStage.OPPONENT_SUPPORT)
		ui.set_indicator(Actor.Type.OPPONENT)
		ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.THINKING)
		_execute_opponent_support_play()


func _on_player_support_played(card: Node2D) -> void:
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)
	ui.show_end_turn_button(false)
	
	playerSupportCard = card
	
	if isTutorialActive:
		advance_tutorial("player_played_support", card)
	
	HoldoutStats.record_played_card("Support", playerSupportCard.cardKey, playerSupportCard.value)
	battleEngine.log_action("Player. You played " + card.nameText + ".")
	
	_play_dust_effect(playerSupportCard)
	
	var forceNoBackfire = battleEngine.has_modifier(Database.Modifier.DESPERATE_MEASURES)
	var handled = false
	
	if playerSupportCard.perk and playerSupportCard.perk.timing == "onPlay":
		await get_tree().create_timer(opponentThinkingTime).timeout
		var result = await playerSupportCard.perk.apply_on_play_perk(playerCharacterCard, playerSupportCard, opponentCharacterCard, opponentSupportCard, playerHand, forceNoBackfire)
		_log_perk_result(playerSupportCard, result.get("log", 0), true)
		handled = result.get("handled", false)
		
		if result.get("blockOpponentSupport", false):
			battleEngine.block_support(Actor.Type.OPPONENT)
		
		if result.has("directDamageAmount"):
			var target = Actor.Type.PLAYER if result.get("directDamageSelf", false) else Actor.Type.OPPONENT
			await _deal_damage(target, result["directDamageAmount"])
		
		if result.get("backfired", false) and battleEngine.has_modifier(Database.Modifier.PSYCHO_MANIA):
			_apply_psycho_mania_bonus(playerHand)
	
	if forceNoBackfire and playerSupportCard.cardKey in BACKFIRE_CAPABLE:
		battleEngine.log_action("System. Desperate Measures modifier activated. You took 1 damage.")
		playerSupportCard.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Desperate Measures.png")
		playerSupportCard.get_node("AnimationPlayer").play("modifierIndicator")
		await playerSupportCard.get_node("AnimationPlayer").animation_finished
		await _deal_damage(Actor.Type.PLAYER, 1)
	
	if not handled:
		await _apply_player_support(playerSupportCard, opponentCharacterCard, playerCharacterCard)
	
	battleEngine.player_played_support()

	if battleEngine.get_support_starter() == Actor.Type.PLAYER:
		_execute_opponent_support_play()
	else:
		lockPlayerInput = true
		ui.set_indicator(Actor.Type.NONE)
		await _apply_end_round_perks()
		_transition_to_resolution_phase()


func _execute_opponent_support_play() -> void:
	ui.set_indicator(Actor.Type.OPPONENT)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.THINKING)
	
	lockPlayerInput = true
	
	await get_tree().create_timer(opponentThinkingTime).timeout
	
	if battleEngine.is_support_blocked(Actor.Type.OPPONENT):
		battleEngine.log_action("System. The opponent's support was blocked this round.")
	else:
		opponentAI.set_flip_script_active(battleEngine.has_modifier(Database.Modifier.FLIP_SCRIPT))
		var card = opponentAI.choose_support_card(opponentHand, opponentCharacterCard, playerCharacterCard, ui.get_health(Actor.Type.OPPONENT), ui.get_health(Actor.Type.PLAYER))
		
		if card != null:
			card.cardSlot = opponentSupportCardSlot
			_animate_opponent_playing_card(card, opponentSupportCardSlot)
			opponentSupportCard = card
			
			HoldoutStats.record_played_card("Support", opponentSupportCard.cardKey, opponentSupportCard.value, true)
			var opponentName: String = Actor.Avatar.keys()[HoldoutStats.currentOpponent].capitalize()
			battleEngine.log_action("Opponent. " + opponentName + " played " + card.nameText + ".")
			
			if battleEngine.has_modifier(Database.Modifier.GAMBLER) and randf() <= battleEngine.gamblerChance:
				await get_tree().create_timer(opponentThinkingTime).timeout
				opponentSupportCard.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Gambler.png")
				opponentSupportCard.get_node("AnimationPlayer").queue("modifierIndicator")
				await opponentSupportCard.get_node("AnimationPlayer").animation_finished
				
				opponentSupportCard.modify_value(int(opponentCharacterCard.value / 2.0))
				
				battleEngine.log_action("System. Gambler modifier activated. " + opponentName + "'s " + opponentSupportCard.nameText + " gained +" + str(int(opponentCharacterCard.value / 2.0)) + " value.")
			
			var handled = false
			
			if opponentSupportCard.perk and opponentSupportCard.perk.timing == "onPlay":
				await get_tree().create_timer(opponentThinkingTime).timeout
				var result = await opponentSupportCard.perk.apply_on_play_perk(opponentCharacterCard, opponentSupportCard, playerCharacterCard, playerSupportCard, opponentHand)
				_log_perk_result(opponentSupportCard, result.get("log", 0), false)
				handled = result.get("handled", false)
				
				if result.get("blockOpponentSupport", false):
					battleEngine.block_support(Actor.Type.PLAYER)
				
				if result.has("directDamageAmount"):
					var target = Actor.Type.OPPONENT if result.get("directDamageSelf", false) else Actor.Type.PLAYER
					await _deal_damage(target, result["directDamageAmount"])
				
				if result.get("backfired", false) and battleEngine.has_modifier(Database.Modifier.PSYCHO_MANIA):
					_apply_psycho_mania_bonus(playerHand)
			
			
			if not handled:
				await _apply_opponent_support(opponentSupportCard, playerCharacterCard, opponentCharacterCard)
	
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
	
	battleEngine.opponent_played_support()
	
	if battleEngine.get_support_starter() == Actor.Type.PLAYER:
		ui.set_indicator(Actor.Type.NONE)
		await _apply_end_round_perks()
		_transition_to_resolution_phase()
	else:
		lockPlayerInput = false
		ui.set_indicator(Actor.Type.PLAYER)
		ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
		ui.show_end_turn_button()
		_update_playable_support_cards()

	opponentPlayedSupport = true


func _transition_to_resolution_phase() -> void:
	battleEngine.set_phase(battleEngine.RoundStage.END_CALCULATION)
	
	if battleEngine.isBlindEyeActiveThisRound:
		var waitTime: float = 0.0
		
		if opponentCharacterCard:
			opponentCharacterCard.get_node("AnimationPlayer").play("cardFlip")
			waitTime = opponentCharacterCard.get_node("AnimationPlayer").current_animation_length
			
		if opponentSupportCard:
			opponentSupportCard.get_node("AnimationPlayer").play("cardFlip")
			
		if waitTime > 0:
			await get_tree().create_timer(waitTime + 0.5).timeout
	
	await _calculate_damage()
	await get_tree().create_timer(endRoundTime).timeout
	
	var playerHealth = ui.get_health(Actor.Type.PLAYER)
	var opponentHealth = ui.get_health(Actor.Type.OPPONENT)
	
	var opponentDefeated = opponentHealth <= 0 and not battleEngine.has_modifier(Database.Modifier.ENDURE)
	
	if playerHealth <= 0 or opponentDefeated:
		if isTutorialRun:
			await _conclude_tutorial_match()
		else:
			await _conclude_match()
		return
	
	_apply_in_hand_growth(playerHand, battleEngine.lastRoundWinner == battleEngine.Winner.PLAYER, true)
	_apply_in_hand_growth(opponentHand, battleEngine.lastRoundWinner == battleEngine.Winner.OPPONENT, false)
	
	var deadWeightSavesPlayerCard = battleEngine.has_modifier(Database.Modifier.DEAD_WEIGHT) and battleEngine.lastRoundWinner == battleEngine.Winner.OPPONENT
	var baitedDefenseSteal = battleEngine.has_modifier(Database.Modifier.BAITED_DEFENSE) and battleEngine.lastRoundWinner == battleEngine.Winner.OPPONENT and "Defensive" in playerCharacterCard.role
	
	if baitedDefenseSteal:
		battleEngine.log_action("System. Baited Defense modifier activated. " + opponentCharacterCard.nameText + " was stolen and added to your hand.")
		await _steal_character_to_hand(opponentCharacterCard)
	
	var cardsToDiscard = []
	if playerSupportCard: cardsToDiscard.append(playerSupportCard)
	if not deadWeightSavesPlayerCard:
		cardsToDiscard.append(playerCharacterCard)
	if not baitedDefenseSteal:
		cardsToDiscard.append(opponentCharacterCard)
	if opponentSupportCard: cardsToDiscard.append(opponentSupportCard)
	
	await _move_cards_to_discard(cardsToDiscard)
	
	if deadWeightSavesPlayerCard:
		battleEngine.log_action("System. Dead Weight modifier activated. " + playerCharacterCard.nameText + " was returned to your hand.")
		await _return_character_to_hand(playerCharacterCard)
	
	ui.show_end_turn_button(false)
	
	await _repopulate_hand(playerHand, Actor.Type.PLAYER)
	await _repopulate_hand(opponentHand, Actor.Type.OPPONENT)
	
	battleEngine.end_round_cleanup(playerCharacterCard.faction, playerCharacterCard.role)
	
	cardsToDiscard = []
	
	battleEngine.log_action("System. End of round.")
	
	_start_new_round()


func _conclude_match() -> void:
	battleEngine.isRoundActive = true
	GameStats.gameMode = GameStats.Mode.HOLDOUT_ROUND_COMPLETED
	GameStats.totalInGameTimePlayed += HoldoutStats.currentRoundDuration
	
	%pauseIcon.hide()
	
	if not isTutorialActive:
		var tween = get_tree().create_tween()
		tween.tween_property(%phaseTracker, "modulate:a", 0.0, perkCalculationTime)
	
	var cardsToDiscard = []
	
	if playerSupportCard: cardsToDiscard.append(playerSupportCard)
	if playerCharacterCard: cardsToDiscard.append(playerCharacterCard)
	if opponentCharacterCard: cardsToDiscard.append(opponentCharacterCard)
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
	
	battleEngine.clear_history()

func _start_new_round() -> void:
	playerCharacterCard = null
	playerSupportCard = null
	opponentCharacterCard = null
	opponentSupportCard = null

	opponentPlayedSupport = false
	ui.show_end_turn_button(false)
	
	var deckRanOut = await _repopulate_decks()
	
	if deckRanOut and battleEngine.has_modifier(Database.Modifier.ENDURE):
		battleEngine.log_action("System. Endure modifier activated. A deck ran out — you win.")
		await _conclude_match()
		return
	
	_apply_guerrilla_tactics_restrictions()
	
	battleEngine.start_new_round(battleEngine.has_modifier(Database.Modifier.FRONT_RUNNER), HoldoutStats.roundsPlayed)
	_update_playable_support_cards()
	
	if isTutorialActive:
		advance_tutorial("round_started")
	else:
		var tween = get_tree().create_tween()
		tween.tween_property(%phaseTracker, "modulate:a", 1.0, perkCalculationTime)
	
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
	if isTutorialActive and (battleEngine.tutorialStep == 4 or battleEngine.tutorialStep == 5 or battleEngine.tutorialStep == 6):
		return
	
	ui.show_end_turn_button(false)
	
	if battleEngine.tutorialStep == 2:
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
		if i < battleEngine.startingSupportCards:
			await get_tree().create_timer(cardMoveFastSpeed).timeout
			$"../supportDeck".draw_card()
			
		if i < battleEngine.opponentStartingSupportCards:
			await get_tree().create_timer(cardMoveFastSpeed).timeout
			$"../supportDeck".draw_opponent_card()
	
	GameStats.gameMode = GameStats.Mode.HOLDOUT
	
	%pauseIcon.show()

func _pick_next_opponent() -> Actor.Avatar:
	if HoldoutStats.opponentList.is_empty():
		assert(GameStats.gameMode == GameStats.Mode.HOLDOUT, "CRITICAL: holdoutBattle.gd run without HOLDOUT mode set. Run the game fully or load from the Main Menu.")
		
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
	
	if !battleEngine.isBlindEyeActiveThisRound:
		opponentCard.get_node("AnimationPlayer").play("cardFlip")
	
	var tween = get_tree().create_tween()
	tween.finished.connect(AudioManager.play_random_card_draw)
	tween.tween_property(opponentCard, "position", opponentCardSlot.position, cardMoveSpeed)
	
	if !battleEngine.isBlindEyeActiveThisRound:
		await opponentCard.get_node("AnimationPlayer").animation_finished
	
	_play_dust_effect(opponentCard, true)
	
	$"../opponentHand".remove_card_from_hand(opponentCard)

func _apply_mid_round_perks() -> void:
	if isTutorialActive and not arePerksActiveInTutorial:
		return
		
	if battleEngine.has_modifier(Database.Modifier.FRIENDLY_FIRE):
		if playerCharacterCard.faction == opponentCharacterCard.faction:
			await get_tree().create_timer(0.3).timeout
			battleEngine.log_action("System. Friendly Fire modifier activated. Your character's value was halved.")
			playerCharacterCard.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Friendly Fire.png")
			playerCharacterCard.get_node("AnimationPlayer").queue("modifierIndicator")
			playerCharacterCard.modify_value(-int(ceil(playerCharacterCard.value / 2.0)))
			await playerCharacterCard.get_node("AnimationPlayer").animation_finished
		
		if _hand_has_all_different_factions(playerHand):
			await get_tree().create_timer(0.3).timeout
			battleEngine.log_action("System. Friendly Fire modifier activated. Your hand's diversity granted +3.")
			playerCharacterCard.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Friendly Fire.png")
			playerCharacterCard.get_node("AnimationPlayer").queue("modifierIndicator")
			playerCharacterCard.modify_value(2)
			await playerCharacterCard.get_node("AnimationPlayer").animation_finished
	
	if battleEngine.whoStartedRound == Actor.Type.PLAYER:
		await _execute_player_mid_perk()
		await _execute_opponent_mid_perk()
	else:
		await _execute_opponent_mid_perk()
		await _execute_player_mid_perk()
	
	_handle_runner_perk()

func _update_playable_support_cards() -> void:
	var playerBlocked = battleEngine.is_support_blocked(Actor.Type.PLAYER)
	
	for card in playerHand:
		if is_instance_valid(card) and card.type == "Support":
			if playerBlocked:
				card.canBePlayed = false
				_animate_card_lock(card)
			else:
				card.canBePlayed = true
				_animate_card_unlock(card)
	
	var opponentBlocked = battleEngine.is_support_blocked(Actor.Type.OPPONENT)
	for card in opponentHand:
		if is_instance_valid(card) and card.type == "Support":
			card.canBePlayed = not opponentBlocked

func _apply_end_round_perks() -> void:
	if isTutorialActive and not arePerksActiveInTutorial:
		return
		
	if battleEngine.whoStartedRound == Actor.Type.PLAYER:
		await _execute_player_char_end_perk()
		await _execute_opponent_char_end_perk()
		
		await _execute_player_late_end_perk()
		await _execute_opponent_late_end_perk()
	else:
		await _execute_opponent_char_end_perk()
		await _execute_player_char_end_perk()
		
		await _execute_opponent_late_end_perk()
		await _execute_player_late_end_perk()

	await get_tree().create_timer(perkCalculationTime).timeout

func _apply_in_hand_growth(hand: Array, wonRound: bool, isPlayer: bool) -> void:
	for card in hand:
		if is_instance_valid(card) and card.type == "Support" and card.perk and card.perk.timing == "inHand":
			var gained = card.perk.apply_in_hand_perk(card, wonRound)
			if gained != 0 and isPlayer:
				_log_perk_result(card, [[gained, "self"]], isPlayer)

func _calculate_damage() -> void:
	var playerTotal = playerCharacterCard.value
	var opponentTotal = opponentCharacterCard.value
	
	HoldoutStats.record_played_card(playerCharacterCard.faction, playerCharacterCard.cardKey, playerTotal)
	HoldoutStats.record_played_card(opponentCharacterCard.faction, opponentCharacterCard.cardKey, opponentTotal, true)
	
	_apply_calculation_round_perks(playerTotal, opponentTotal)
	
	var report = battleEngine.process_combat_stats(playerTotal, opponentTotal, playerCharacterCard.cardKey, opponentCharacterCard.cardKey)
	battleEngine.lastRoundWinner = report.winner
	
	var opponentStreakBonus = battleEngine.get_stacked_odds_bonus()
	var stackedOddsBreakBonus = battleEngine.update_stacked_odds(report.winner)
	
	if opponentAI.has_method("record_round_result"):
		opponentAI.record_round_result(report.winner == battleEngine.Winner.OPPONENT)
	
	var opponentName: String = Actor.Avatar.keys()[HoldoutStats.currentOpponent].capitalize()
	if report.winner == battleEngine.Winner.PLAYER:
		battleEngine.log_action("Player. You dealt " + str(report.damage) + " damage to " + opponentName + ".")
	elif report.winner == battleEngine.Winner.OPPONENT:
		battleEngine.log_action("Opponent. " + opponentName + " dealt " + str(report.damage) + " damage to you.")
	else:
		battleEngine.log_action("System. No one took damage.")
	
	if report.overExertionBonus > 0:
		battleEngine.log_action("System. Over-Exertion modifier activated. " + opponentName + " took " + str(report.overExertionBonus) + " additional damage.")
		playerCharacterCard.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Over Exertion.png")
		playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
		await _deal_damage(Actor.Type.OPPONENT, report.overExertionBonus)
	
	if report.winner == battleEngine.Winner.PLAYER:
		await _handle_player_win(report.damage, report.triggerCalculatedRisk, stackedOddsBreakBonus)
	elif report.winner == battleEngine.Winner.OPPONENT:
		await _handle_opponent_win(report.damage, report.triggerDeepWounds, report.triggerCalculatedRiskLoss, opponentStreakBonus)
	
	if battleEngine.has_modifier(Database.Modifier.SLOW_BLEED) and HoldoutStats.roundsPlayed % 2 == 0 and Database.MODIFIERS.has(Database.Modifier.SLOW_BLEED):
		var bleedAmount = Database.MODIFIERS.get(Database.Modifier.SLOW_BLEED)["amount"]
		battleEngine.log_action("System. Slow Bleed modifier activated. You took " + str(bleedAmount) + " damage.")
		await _deal_damage(Actor.Type.PLAYER, Database.MODIFIERS.get(Database.Modifier.SLOW_BLEED)["amount"])
		await _apply_slow_bleed_bonus(playerHand)
	
	if battleEngine.has_modifier(Database.Modifier.CARD_ROT):
		_apply_card_rot_aging()

func _apply_player_support(support: Node2D, opponentCharacter: Node2D, playerCharacter: Node2D) -> void:
	await get_tree().create_timer(1.0).timeout
	
	var opponentName: String = Actor.Avatar.keys()[HoldoutStats.currentOpponent].capitalize()
	if Database.SUPPORTS[support.cardKey].Parity == "Negative":
		battleEngine.log_action("Player. Your " + support.nameText + " weakened " + opponentName + "'s " + opponentCharacterCard.nameText + " by " + str(support.value) + ".")
		var value = support.value
		support.modify_value(-value)
		await opponentCharacter.modify_value(-value)
	else:
		battleEngine.log_action("Player. Your " + support.nameText + " strengthened your " + playerCharacterCard.nameText + " by " + str(support.value) + ".")
		var value = support.value
		support.modify_value(-value)
		await playerCharacter.modify_value(value)

func _apply_opponent_support(support: Node2D, playerCharacter: Node2D, opponentCharacter: Node2D) -> void:
	await get_tree().create_timer(1.0).timeout
	
	var opponentName: String = Actor.Avatar.keys()[HoldoutStats.currentOpponent].capitalize()
	if Database.SUPPORTS[support.cardKey].Parity == "Negative":
		battleEngine.log_action("Opponent. " + opponentName + "'s " + support.nameText + " weakened your " + playerCharacterCard.nameText + " by " + str(support.value) + ".")
		var value = support.value
		support.modify_value(-value)
		await playerCharacter.modify_value(-value)
	else:
		battleEngine.log_action("Opponent. " + opponentName + "'s " + support.nameText + " strengthened their " + opponentCharacterCard.nameText + " by " + str(support.value) + ".")
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
			if card.type == "Character":
				await _place_card_in_discard(card, %playerHand)

func _reset_played_cards_perks() -> void:
	if playerCharacterCard and playerCharacterCard.perk:
		playerCharacterCard.get_node("value").text = str(playerCharacterCard.value)
		playerCharacterCard.perkValueAppliedMidRound = 0
	
	if opponentCharacterCard and opponentCharacterCard.perk:
		opponentCharacterCard.get_node("value").text = str(opponentCharacterCard.value)
		opponentCharacterCard.perkValueAppliedMidRound = 0

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
	
	# Supports
	var isSupportDrawRoundPlayer: bool = HoldoutStats.roundsPlayed % battleEngine.roundsTillSupportDraw == 0
	var isSupportDrawRoundOpponent: bool = HoldoutStats.roundsPlayed % battleEngine.roundsTillSupportDrawOpponent == 0
	
	if who == Actor.Type.PLAYER:
		if isSupportDrawRoundPlayer and supportCount < battleEngine.maxSupportCards and !battleEngine.has_modifier(Database.Modifier.SEVERED_SUPPLY):
			supportDeckReference.draw_card()
			await get_tree().create_timer(cardMoveSpeed).timeout
	else:
		if isSupportDrawRoundOpponent and supportCount < battleEngine.opponentMaxCards:
			supportDeckReference.draw_opponent_card()
			await get_tree().create_timer(cardMoveSpeed).timeout
			
	lockPlayerInput = false


func _repopulate_decks(endGame: bool = false) -> bool:
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
		
		if opponentAI.has_method("reset_elimination"):
			opponentAI.reset_elimination()
		
		return false
	
	if $"../supportDeck".deck.size() < battleEngine.minCardsForReshuffle:
		discardedCards = discardedCharactersReversed + discardedSupportsReversed
		
		for i in range(discardedSupportsReversed.size()):
			discardedSupportsReversed[i].z_index = 100 - i
		
		$"../supportDeck".reshuffle_from_discards(discardedSupportsReversed)
		for card in discardedSupportsReversed:
			discardedCards.erase(card)
		
		return true
	
	if $"../characterDeck".deck.size() < battleEngine.minCardsForReshuffle:
		discardedCards = discardedSupportsReversed + discardedCharactersReversed
		
		for i in range(discardedCharactersReversed.size()):
			discardedCharactersReversed[i].z_index = 100 - i
		
		$"../characterDeck".reshuffle_from_discards(discardedCharactersReversed)
		for card in discardedCharactersReversed:
			discardedCards.erase(card)
		
		if opponentAI.has_method("reset_elimination"):
			opponentAI.reset_elimination()
		
		return true
	
	return false


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

func _return_character_to_hand(card: Node2D) -> void:
	AudioManager.play_random_card_draw()
	card.scale = Vector2(1, 1)
	
	var baseValue = Database.CHARACTERS[card.cardKey][0]
	card.value = baseValue
	card.get_node("value").text = str(baseValue)
	
	card.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Dead Weight.png")
	card.get_node("AnimationPlayer").play("modifierIndicator")
	await card.get_node("AnimationPlayer").animation_finished
	
	var tween = %playerHand.add_card_to_hand(card, cardMoveSpeed)
	if tween:
		await tween.finished
		AudioManager.play_random_card_draw()


func _apply_card_rot_aging() -> void:
	for card in playerHand:
		if not is_instance_valid(card) or card.type != "Character":
			continue
		
		var age = card.get_meta("cardRotAge", 0) + 1
		card.set_meta("cardRotAge", age)
		
		if age >= 3:
			var rotAmount = card.get_meta("cardRotAmount", 0) + 1
			card.set_meta("cardRotAmount", rotAmount)
			
			battleEngine.log_action("System. Card Rot modifier activated. " + card.nameText + " lost 1 value from rotting.")
			card.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Card Rot.png")
			card.get_node("AnimationPlayer").queue("modifierIndicator")
			card.modify_value(-1)


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


func _handle_player_win(damage: int, triggerCalculatedRisk: bool, stackedOddsBreakBonus: int = 0) -> void:
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.HAPPY)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.HURT)
	
	var opponentName: String = Actor.Avatar.keys()[HoldoutStats.currentOpponent].capitalize()
	
	if opponentCharacterCard.cardKey == "Owen":
		battleEngine.log_action("System. Owen's perk activated. " + opponentName + " avoided damage.")
		await get_tree().create_timer(perkCalculationTimeAfterRoundEnd).timeout
		return
	
	# Resilience check — opponent is the one taking damage this round
	var finalDamage = damage
	if opponentSupportCard and opponentSupportCard.perk and opponentSupportCard.perk.timing == "onResolution":
		var result = await opponentSupportCard.perk.apply_on_resolution_perk(opponentCharacterCard, opponentSupportCard, playerCharacterCard, playerSupportCard, false, damage)
		if result.has("modifiedDamage"):
			finalDamage = result["modifiedDamage"]
			_log_perk_result(opponentSupportCard, result.get("log", 0), false)
	
	# Retreat check — either side could be holding it
	if _resolution_has_retreat():
		battleEngine.log_action("System. Retreat activated. No damage was dealt.")
		await get_tree().create_timer(perkCalculationTimeAfterRoundEnd).timeout
	else:
		await _deal_damage(Actor.Type.OPPONENT, finalDamage, false)
		await _handle_shambler_perk(Actor.Type.PLAYER)
		
		if playerCharacterCard.perkValueAtRoundEnd:
			battleEngine.log_action("System. " + playerCharacterCard.nameText + "'s perk dealt " + str(playerCharacterCard.perkValueAtRoundEnd) + " additional damage to " + opponentName + ".")
			await _deal_damage(Actor.Type.OPPONENT, playerCharacterCard.perkValueAtRoundEnd)
		
		if triggerCalculatedRisk:
			playerCharacterCard.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Calculated Risk.png")
			playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
			battleEngine.log_action("System. Calculated Risk modifier activated. " + opponentName + " took 3 additional damage.")
			await _deal_damage(Actor.Type.OPPONENT, 3)
		
		if battleEngine.has_modifier(Database.Modifier.HEAVY_HITTER) and playerCharacterCard.value >= 5:
			playerCharacterCard.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Heavy Hitter.png")
			playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
			battleEngine.log_action("System. Heavy Hitter modifier activated. " + opponentName + " took 2 additional damage.")
			await _deal_damage(Actor.Type.OPPONENT, 2)
		
		if stackedOddsBreakBonus > 0:
			playerCharacterCard.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Stacked Odds.png")
			playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
			await playerCharacterCard.get_node("AnimationPlayer").animation_finished
			playerCharacterCard.modify_value(stackedOddsBreakBonus)
			battleEngine.log_action("System. Stacked Odds modifier activated. " + opponentName + " took " + str(stackedOddsBreakBonus) + " additional damage.")
			await _deal_damage(Actor.Type.OPPONENT, stackedOddsBreakBonus)
		
		var rotAmount = playerCharacterCard.get_meta("cardRotAmount", 0)
		if rotAmount > 0:
			playerCharacterCard.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Card Rot.png")
			playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
			battleEngine.log_action("System. Card Rot modifier activated. " + opponentName + " took " + str(rotAmount) + " additional damage from " + playerCharacterCard.nameText + "'s rot.")
			await _deal_damage(Actor.Type.OPPONENT, rotAmount)
	
	# Reinforced Melee check — player's own support, player won
	if playerSupportCard and playerSupportCard.perk and playerSupportCard.perk.timing == "onResolution":
		var result = await playerSupportCard.perk.apply_on_resolution_perk(playerCharacterCard, playerSupportCard, opponentCharacterCard, opponentSupportCard, true, damage)
		if result.get("drawExtraSupport", false):
			_draw_bonus_support(Actor.Type.PLAYER)


func _handle_opponent_win(damage: int, triggerDeepWounds: bool, triggerCalculatedRiskLoss: bool, stackedOddsOpponentBonus: int = 0) -> void:
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.HURT)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.HAPPY)
	
	if playerCharacterCard.cardKey == "Owen":
		battleEngine.log_action("System. Owen's perk activated. You avoided damage.")
		await get_tree().create_timer(perkCalculationTimeAfterRoundEnd).timeout
		return
	
	# Resilience check — player is the one taking damage this round
	var finalDamage = damage
	if playerSupportCard and playerSupportCard.perk and playerSupportCard.perk.timing == "onResolution":
		var result = await playerSupportCard.perk.apply_on_resolution_perk(playerCharacterCard, playerSupportCard, opponentCharacterCard, opponentSupportCard, false, damage)
		if result.has("modifiedDamage"):
			finalDamage = result["modifiedDamage"]
			_log_perk_result(playerSupportCard, result.get("log", 0), true)
	
	if _resolution_has_retreat():
		battleEngine.log_action("System. Retreat activated. No damage was dealt.")
		await get_tree().create_timer(perkCalculationTimeAfterRoundEnd).timeout
	else:
		await _deal_damage(Actor.Type.PLAYER, finalDamage, false)
		await _handle_shambler_perk(Actor.Type.OPPONENT)
		
		if opponentCharacterCard.perkValueAtRoundEnd:
			battleEngine.log_action("System. " + opponentCharacterCard.nameText + "'s perk dealt " + str(opponentCharacterCard.perkValueAtRoundEnd) + " additional damage to you.")
			await _deal_damage(Actor.Type.PLAYER, opponentCharacterCard.perkValueAtRoundEnd)
		
		if triggerDeepWounds:
			playerCharacterCard.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Deep Wounds.png")
			playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
			battleEngine.log_action("System. Deep Wounds modifier activated. You took 2 additional damage.")
			await _deal_damage(Actor.Type.PLAYER, 2)
			pendingDeepWoundsBonus = true
		
		if triggerCalculatedRiskLoss:
			opponentCharacterCard.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Calculated Risk.png")
			opponentCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
			battleEngine.log_action("System. Calculated Risk modifier activated. You took 3 additional damage.")
			await _deal_damage(Actor.Type.PLAYER, 3)
		
		if battleEngine.has_modifier(Database.Modifier.HEAVY_HITTER) and playerCharacterCard.value >= 5:
			playerCharacterCard.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Heavy Hitter.png")
			playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
			battleEngine.log_action("System. Heavy Hitter modifier activated. You took 2 additional damage.")
			await _deal_damage(Actor.Type.PLAYER, 2)
		
		if battleEngine.has_modifier(Database.Modifier.VAMPIRIC) and damage >= 3:
			var opponentName: String = Actor.Avatar.keys()[HoldoutStats.currentOpponent].capitalize()
			battleEngine.log_action("System. Vampiric modifier activated. " + opponentName + " healed for 3.")
			
			opponentCharacterCard.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Vampiric.png")
			opponentCharacterCard.get_node("AnimationPlayer").queue("modifierIndicator")
			await opponentCharacterCard.get_node("AnimationPlayer").animation_finished
			await _deal_damage(Actor.Type.OPPONENT, -3)
		
		if stackedOddsOpponentBonus > 0:
			var opponentName: String = Actor.Avatar.keys()[HoldoutStats.currentOpponent].capitalize()
			opponentCharacterCard.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Stacked Odds.png")
			opponentCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
			await opponentCharacterCard.get_node("AnimationPlayer").animation_finished
			opponentCharacterCard.modify_value(stackedOddsOpponentBonus)
			battleEngine.log_action("System. Stacked Odds modifier activated. " + opponentName + " dealt " + str(stackedOddsOpponentBonus) + " additional damage from their streak.")
			await _deal_damage(Actor.Type.PLAYER, stackedOddsOpponentBonus)
	
	# Reinforced Melee check — opponent's own support, opponent won
	if opponentSupportCard and opponentSupportCard.perk and opponentSupportCard.perk.timing == "onResolution":
		var result = await opponentSupportCard.perk.apply_on_resolution_perk(opponentCharacterCard, opponentSupportCard, playerCharacterCard, playerSupportCard, true, damage)
		if result.get("drawExtraSupport", false):
			_draw_bonus_support(Actor.Type.OPPONENT)


func _steal_character_to_hand(card: Node2D) -> void:
	var cardKey = card.cardKey
	var spawnPosition = card.position
	
	card.queue_free()
	
	var baseValue = Database.CHARACTERS[cardKey][0]
	var newCard = _spawn_single_card({"cardKey": cardKey, "value": baseValue}, false)
	newCard.position = spawnPosition
	newCard.scale = Vector2(1, 1)
	
	$"../cardManager".add_child(newCard)
	
	newCard.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Baited Defense.png")
	newCard.get_node("AnimationPlayer").play("modifierIndicator")
	await newCard.get_node("AnimationPlayer").animation_finished
	
	AudioManager.play_random_card_draw()
	var tween = %playerHand.add_card_to_hand(newCard, cardMoveSpeed)
	if tween:
		await tween.finished
		AudioManager.play_random_card_draw()


func _resolution_has_retreat() -> bool:
	if playerSupportCard and playerSupportCard.cardKey == "Retreat":
		return true
	if opponentSupportCard and opponentSupportCard.cardKey == "Retreat":
		return true
	return false


func _hand_has_all_different_factions(hand: Array) -> bool:
	var seenFactions: Array = []
	
	for card in hand:
		if is_instance_valid(card) and card.type == "Character":
			if card.faction in seenFactions:
				return false
			seenFactions.append(card.faction)
	
	return seenFactions.size() > 1


func _draw_bonus_support(who: Actor.Type) -> void:
	var supportDeckReference = $"../supportDeck"
	var hand = playerHand if who == Actor.Type.PLAYER else opponentHand
	var cap = battleEngine.maxSupportCards if who == Actor.Type.PLAYER else battleEngine.opponentMaxCards
	
	var supportCount = 0
	for card in hand:
		if is_instance_valid(card) and card.type == "Support":
			supportCount += 1
	
	if supportCount >= cap:
		return
	
	if who == Actor.Type.PLAYER:
		supportDeckReference.draw_card()
	else:
		supportDeckReference.draw_opponent_card()
	
	battleEngine.log_action("System. Reinforced Melee activated. An extra support card was drawn.")

func _apply_psycho_mania_bonus(hand: Array) -> void:
	var eligible = hand.filter(func(c): return is_instance_valid(c))
	if eligible.is_empty():
		return
	
	var target = eligible[randi() % eligible.size()]
	target.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Psycho Mania.png")
	target.get_node("AnimationPlayer").play("modifierIndicator")
	await target.get_node("AnimationPlayer").animation_finished
	target.modify_value(2)
	battleEngine.log_action("System. Psycho-mania modifier activated. " + target.nameText + " gained +2.")

func _apply_slow_bleed_bonus(hand: Array) -> void:
	var eligible = hand.filter(func(c): return is_instance_valid(c) and c.type == "Character")
	if eligible.is_empty():
		return

	var target = eligible[randi() % eligible.size()]
	target.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Slow Bleed.png")
	target.get_node("AnimationPlayer").play("modifierIndicator")
	await target.get_node("AnimationPlayer").animation_finished
	target.modify_value(1)
	battleEngine.log_action("System. Slow Bleed modifier activated. " + target.nameText + " permanently gained +1.")

func _handle_shambler_perk(winner: Actor.Type) -> void:
	if winner == Actor.Type.PLAYER:
		if opponentCharacterCard.cardKey == "Shambler" and opponentCharacterCard.perkValueAtRoundEnd:
			battleEngine.log_action("System. Shambler's perk activated. You took " + str(opponentCharacterCard.perkValueAtRoundEnd) + " damage.")
			await _deal_damage(Actor.Type.PLAYER, opponentCharacterCard.perkValueAtRoundEnd)
	elif winner == Actor.Type.OPPONENT:
		if playerCharacterCard.cardKey == "Shambler" and playerCharacterCard.perkValueAtRoundEnd:
			var opponentName: String = Actor.Avatar.keys()[HoldoutStats.currentOpponent].capitalize()
			battleEngine.log_action("System. Shambler's perk activated. " + opponentName + " took " + str(playerCharacterCard.perkValueAtRoundEnd) + " damage.")
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
	
	if not battleEngine.has_modifier(Database.Modifier.GUERRILLA_TACTICS) or battleEngine.previousRoundFaction == "":
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
		card.get_node("Area2D/CollisionShape2D").disabled = true
		await get_tree().create_timer(0.35).timeout
		AudioManager.play_card_lock()

func _animate_card_unlock(card):
	if card.get_node("lockIcon/top").modulate.a > 0.1:
		card.get_node("AnimationPlayer").play_backwards("lock")
		card.get_node("Area2D/CollisionShape2D").disabled = false
		await get_tree().create_timer(0.35).timeout
		AudioManager.play_card_lock()

func _check_old_wounds_accolade() -> void:
	if HoldoutStats.RIVALRIES.has(playerCharacterCard.cardKey):
		var rivals = HoldoutStats.RIVALRIES[playerCharacterCard.cardKey]
		if opponentCharacterCard.cardKey in rivals:
			HoldoutStats.achievedOldWounds = true

func _play_dust_effect(card: Node2D, isOpponent: bool = false) -> void:
	var dust = card.get_node("dust") 
	
	dust.visible = true
	dust.scale = Vector2(0.2, 0.2)
	dust.self_modulate.a = 0.075
	
	if !isOpponent:
		await get_tree().create_timer(.1).timeout
	
	var dustTween = get_tree().create_tween().set_parallel(true)
	
	dustTween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	dustTween.tween_property(dust, "scale", Vector2(0.35, 0.35), 0.25)
	dustTween.tween_property(dust, "self_modulate:a", 0.0, 0.25)
	
	await dustTween.finished
	dust.visible = false

# --- PERK HELPERS ---
func _execute_player_mid_perk() -> void:
	if playerCharacterCard.perk && playerCharacterCard.perk.timing == "midRound":
		await get_tree().create_timer(perkCalculationTime).timeout
		
		var statChange = await playerCharacterCard.perk.apply_mid_perk(playerCharacterCard, playerHand, opponentCharacterCard)
		playerCharacterCard.perkValueAppliedMidRound = statChange if typeof(statChange) == TYPE_INT else 0
		_log_perk_result(playerCharacterCard, statChange, true)

func _execute_opponent_mid_perk() -> void:
	if opponentCharacterCard.perk && opponentCharacterCard.perk.timing == "midRound":
		var playerRealRole = playerCharacterCard.role
		var playerRealFaction = playerCharacterCard.faction
		
		if battleEngine.has_modifier(Database.Modifier.FORSAKEN_HONOR):
			if opponentCharacterCard.perk.has_method("would_perk_trigger") and opponentCharacterCard.perk.would_perk_trigger(opponentCharacterCard, opponentHand, playerCharacterCard):
				playerCharacterCard.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Forsaken Honor.png")
				playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
				await playerCharacterCard.get_node("AnimationPlayer").animation_finished
			
			playerCharacterCard.role = "Unknown"
			playerCharacterCard.faction = "Unknown"
		
		await get_tree().create_timer(perkCalculationTime).timeout
		
		var statChange = await opponentCharacterCard.perk.apply_mid_perk(opponentCharacterCard, opponentHand, playerCharacterCard)
		opponentCharacterCard.perkValueAppliedMidRound = statChange if typeof(statChange) == TYPE_INT else 0
		_log_perk_result(opponentCharacterCard, statChange, false)
		
		if battleEngine.has_modifier(Database.Modifier.FORSAKEN_HONOR):
			playerCharacterCard.role = playerRealRole
			playerCharacterCard.faction = playerRealFaction
			_update_playable_support_cards()

func _execute_player_char_end_perk() -> void:
	if playerCharacterCard.perk && playerCharacterCard.perk.timing == "endRound":
		var statChange = await playerCharacterCard.perk.apply_end_perk(playerCharacterCard, playerSupportCard, opponentCharacterCard, opponentSupportCard, playerHand)
		_log_perk_result(playerCharacterCard, statChange, true)

func _execute_opponent_char_end_perk() -> void:
	if opponentCharacterCard.perk && opponentCharacterCard.perk.timing == "endRound":
		var playerRealRole = playerCharacterCard.role
		var playerRealFaction = playerCharacterCard.faction
		
		if battleEngine.has_modifier(Database.Modifier.FORSAKEN_HONOR):
			if opponentCharacterCard.perk.has_method("would_perk_trigger") and opponentCharacterCard.perk.would_perk_trigger(opponentCharacterCard, opponentSupportCard, playerCharacterCard, playerSupportCard, opponentHand):
				playerCharacterCard.get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Forsaken Honor.png")
				playerCharacterCard.get_node("AnimationPlayer").play("modifierIndicator")
				await playerCharacterCard.get_node("AnimationPlayer").animation_finished
			
			playerCharacterCard.role = "Unknown"
			playerCharacterCard.faction = "Unknown"
			
		var statChange = await opponentCharacterCard.perk.apply_end_perk(opponentCharacterCard, opponentSupportCard, playerCharacterCard, playerSupportCard, opponentHand)
		_log_perk_result(opponentCharacterCard, statChange, false)
		
		if battleEngine.has_modifier(Database.Modifier.FORSAKEN_HONOR):
			playerCharacterCard.role = playerRealRole
			playerCharacterCard.faction = playerRealFaction
			_update_playable_support_cards()


func _execute_player_late_end_perk() -> void:
	if playerCharacterCard.perk && playerCharacterCard.perk.timing == "lateEndRound":
		await get_tree().create_timer(perkCalculationTime).timeout
		var statChange = await playerCharacterCard.perk.apply_end_perk(playerCharacterCard, playerSupportCard, opponentCharacterCard, opponentSupportCard, playerHand)
		_log_perk_result(playerCharacterCard, statChange, true)

func _execute_opponent_late_end_perk() -> void:
	if opponentCharacterCard.perk && opponentCharacterCard.perk.timing == "lateEndRound":
		var statChange = await opponentCharacterCard.perk.apply_end_perk(opponentCharacterCard, opponentSupportCard, playerCharacterCard, playerSupportCard, opponentHand)
		_log_perk_result(opponentCharacterCard, statChange, false)

func _execute_player_calc_perk(playerTotal: int, opponentTotal: int) -> void:
	if playerCharacterCard.perk && playerCharacterCard.perk.timing == "calculationRound":
		var statChange = await playerCharacterCard.perk.apply_after_calculation_perk(playerCharacterCard, playerHand, playerTotal, opponentTotal)
		_log_perk_result(playerCharacterCard, statChange, true)

func _execute_opponent_calc_perk(playerTotal: int, opponentTotal: int) -> void:
	if opponentCharacterCard.perk && opponentCharacterCard.perk.timing == "calculationRound":
		var statChange = await opponentCharacterCard.perk.apply_after_calculation_perk(opponentCharacterCard, opponentHand, opponentTotal, playerTotal)
		_log_perk_result(opponentCharacterCard, statChange, false)

func _log_perk_result(card: Node2D, result: Variant, isPlayer: bool) -> void:
	if typeof(result) == TYPE_INT:
		if result == 0: return
		result = [[result, "self"]]
		
	elif typeof(result) == TYPE_ARRAY and result.size() > 0 and typeof(result[0]) != TYPE_ARRAY:
		result = [result]

	var ownerName = "Your" if isPlayer else Actor.Avatar.keys()[HoldoutStats.currentOpponent].capitalize() + "'s"

	for effect in result:
		var amount: int = effect[0]
		var target: String = effect[1]

		# Contextually translate the target so it reads correctly for both sides
		if target == "opponent":
			target = opponentCharacterCard.nameText if isPlayer else playerCharacterCard.nameText
		
		if target == "self":
			if amount > 0:
				battleEngine.log_action("System. " + ownerName + " " + card.nameText + " gained " + str(amount) + " from their perk.")
			elif amount < 0:
				battleEngine.log_action("System. " + ownerName + " " + card.nameText + " lost " + str(abs(amount)) + " from their perk.")
		else:
			if amount > 0:
				battleEngine.log_action("System. " + ownerName + " " + card.nameText + "'s perk granted " + str(amount) + " to " + target + ".")
			elif amount < 0:
				battleEngine.log_action("System. " + ownerName + " " + card.nameText + "'s perk weakened " + target + " by " + str(abs(amount)) + ".")

# --- SAVE & LOAD EXTRACTORS ---
func _get_card_array_save_data(cardArray: Array) -> Array:
	var parsedData = []
	for card in cardArray:
		if is_instance_valid(card):
			var entry = {
				"cardKey": card.cardKey, 
				"value": card.value,
				"role": card.role
			}
			
			if card.has_meta("cardRotAge"):
				entry["cardRotAge"] = card.get_meta("cardRotAge")
			if card.has_meta("cardRotAmount"):
				entry["cardRotAmount"] = card.get_meta("cardRotAmount")
			
			parsedData.append(entry)
	return parsedData

func get_arena_save_dict() -> Dictionary:
	var arenaData = battleEngine.get_engine_save_dict()

	arenaData["opponentHealth"] = ui.get_health(Actor.Type.OPPONENT)
	arenaData["characterDeck"] = $"../characterDeck".deck
	arenaData["supportDeck"] = $"../supportDeck".deck
	arenaData["playerHand"] = _get_card_array_save_data(playerHand)
	arenaData["opponentHand"] = _get_card_array_save_data(opponentHand)
	arenaData["discardedCards"] = _get_card_array_save_data(discardedCards)
	arenaData["pendingDeepWoundsBonus"] = pendingDeepWoundsBonus
	
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
	pendingDeepWoundsBonus = bool(arena.get("pendingDeepWoundsBonus", false))
	
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
	
	# Show active allegiance
	$"../arena/background/currentAllegiance/Name".text = HoldoutStats.activeAllegiance.name
	$"../arena/background/currentAllegiance/Icon".texture = load(HoldoutStats.activeAllegiance.icon)
	$"../arena/background/currentAllegiance/Description".text = HoldoutStats.activeAllegiance.description
	$"../arena/background/currentAllegiance/Tier".text = HoldoutStats.activeAllegiance.faction + " Tier " + str(HoldoutStats.activeAllegiance.tier)
	var colors: Array = FACTION_FUNGUS_COLORS.get(HoldoutStats.activeAllegiance.faction, ["ffffff", "ffffff", "ffffff"])
	$"../arena/background/currentAllegiance/2".modulate = Color(colors[1])
	$"../arena/background/currentAllegiance/3".modulate = Color(colors[2])
	
	_apply_guerrilla_tactics_restrictions()
	
	if battleEngine.roundStage != battleEngine.RoundStage.END_CALCULATION and not isTutorialActive:
		%phaseTracker.modulate.a = 1.0
	
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

func _rebuild_cards_from_save(savedCardArray: Array, handNode: Node) -> void:
	var isOpponent = (handNode == %opponentHand)
	
	for savedCard in savedCardArray:
		var newCard = _spawn_single_card(savedCard, isOpponent)
		
		newCard.position = Vector2(handNode.centerScreenX, handNode.HAND_Y_POSITION)
		
		$"../cardManager".add_child(newCard)
		
		handNode.add_card_to_hand(newCard, 0.0)

func _spawn_single_card(cardData: Dictionary, isOpponent: bool = false) -> Node2D:
	var newCard
	if isOpponent:
		newCard = opponentCardScene.instantiate()
	else:
		newCard = playerCardScene.instantiate()
	
	var key = cardData["cardKey"]
	newCard.cardKey = key
	
	if Database.CHARACTERS.has(key):
		var characterData = Database.CHARACTERS[key]
		newCard.type = characterData[1]
		newCard.faction = characterData[2]
		newCard.role = characterData[3]
		newCard.nameText = characterData[4]
		if characterData.size() > 5:
			newCard.perkDescription = characterData[5]
		
		newCard.canBePlayed = true
		
	elif Database.SUPPORTS.has(key):
		var supportData = Database.SUPPORTS[key]
		newCard.type = supportData.Type
		newCard.faction = "Support" 
		newCard.nameText = supportData.CardText
		newCard.perkDescription = supportData.PerkText
		newCard.parity = supportData.Parity
		
		newCard.canBePlayed = false
		
	if Database.HOLDOUT_PERKS.has(key):
		var perkScript = load(Database.HOLDOUT_PERKS[key])
		if perkScript:
			newCard.perk = perkScript.new()
	
	newCard.value = cardData["value"]
	
	if cardData.has("role"):
		newCard.role = cardData["role"]
	
	if cardData.has("cardRotAge"):
		newCard.set_meta("cardRotAge", cardData["cardRotAge"])
	if cardData.has("cardRotAmount"):
		newCard.set_meta("cardRotAmount", cardData["cardRotAmount"])
	
	newCard.update_visuals()
	
	if isOpponent and not showOpponentsCards:
		if newCard.has_node("image"): 
			newCard.get_node("image").visible = false
		if newCard.has_node("imageBack"): 
			newCard.get_node("imageBack").visible = true
	
	return newCard

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
@onready var tutorialAnimationPlayer = $"../arena/tutorialBox/AnimationPlayer"

func start_tutorial() -> void:
	isTutorialRun = true
	isTutorialActive = true
	battleEngine.set_tutorial_step(1)
	
	HoldoutStats.currentOpponent = Actor.Avatar.DUMMY 
	_initialize_opponent(HoldoutStats.currentPlayer, HoldoutStats.currentOpponent)
	
	%pauseIcon.show()
	
	$"../characterDeck".deck = Database.tutorialCharacterDeck.duplicate()
	$"../supportDeck".deck = Database.tutorialSupportDeck.duplicate()
	
	battleEngine.setup_tutorial_state()
	
	ui.set_indicator(Actor.Type.PLAYER)
	ui.change_mood(Actor.Type.PLAYER, Actor.Mood.THINKING)
	ui.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
	
	lockPlayerInput = false
	
	await _draw_cards_at_start(false)
	
	%number.text = "1/6"
	%heading.text = "Character Cards"
	%instruction.text = "A character's value is located in the top-left corner of the card.\n\nClick and drag Marlene to the Character Slot to play her.\n\nAlternatively you can double click to instantly play it."
	%Box.size.y = 450
	
	_update_tutorial_card_locks()
	
	await get_tree().create_timer(0.75).timeout
	
	tutorialAnimationPlayer.play("show_tutorial_box")
	await tutorialAnimationPlayer.animation_finished

func _update_tutorial_card_locks() -> void:
	var currentStep = battleEngine.tutorialStep
	var enforceLocks = battleEngine.is_tutorial_lock_enforced(currentStep)
	var allowedKeys = battleEngine.get_allowed_tutorial_cards(currentStep)
	
	for card in playerHand:
		if not is_instance_valid(card):
			continue
			
		if enforceLocks:
			card.canBePlayed = (card.cardKey in allowedKeys)
		else:
			if card.type == "Character":
				card.canBePlayed = true

func advance_tutorial(trigger: String, card: Node2D = null) -> void:
	if not isTutorialActive:
		return
		
	match battleEngine.tutorialStep:
		1:
			if trigger == "player_played_character" and card.cardKey == "Marlene":
				battleEngine.set_tutorial_step(2)
				
				tutorialAnimationPlayer.play_backwards("show_tutorial_box")
				await tutorialAnimationPlayer.animation_finished
				
				_update_tutorial_ai_moves()
				
				%number.text = "2/6"
				%heading.text = "Dealing Damage"
				%instruction.text = "The damage dealt is the difference between your value and your opponent’s.\n\nClick End Turn to resolve combat."
				%Box.size.y = 330
				
				await get_tree().create_timer(0.75).timeout
				
				tutorialAnimationPlayer.play("show_tutorial_box")
				await tutorialAnimationPlayer.animation_finished
		2:
			if trigger == "support_phase_started":
				_update_tutorial_card_locks()
			elif trigger == "round_started":
				battleEngine.set_tutorial_step(3)
				_update_tutorial_ai_moves()
				
				await get_tree().create_timer(1.5).timeout
				
				%number.text = "3/6"
				%heading.text = "Character Cards"
				%instruction.text = "Play Li."
				%Box.size.y = 180
				
				tutorialAnimationPlayer.play("show_tutorial_box")
				await tutorialAnimationPlayer.animation_finished
				
				_update_tutorial_card_locks()
		3:
			if trigger == "player_played_character":
				battleEngine.set_tutorial_step(4)
				tutorialAnimationPlayer.play_backwards("show_tutorial_box")
				await tutorialAnimationPlayer.animation_finished
		4:
			if trigger == "support_phase_started":
				_update_tutorial_card_locks()
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
				battleEngine.set_tutorial_step(5)
				arePerksActiveInTutorial = true
				
				_update_tutorial_ai_moves()
				
				_update_tutorial_card_locks()
				
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
				battleEngine.set_tutorial_step(6)
				
				_update_tutorial_card_locks()
				
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

func _update_tutorial_ai_moves() -> void:
	if opponentAI is OpponentAITutorialDummy:
		var moves = battleEngine.get_forced_ai_moves(battleEngine.tutorialStep)
		opponentAI.forcedCharacterKey = moves.character
		opponentAI.forcedSupportKey = moves.support
