class_name HoldoutBattleEngine
extends Node

# --- SIGNALS ---
signal phase_changed(newPhase: int)
signal modifier_toggled(modifierId: int, isActive: bool)

# --- CORE STATE ---
enum RoundStage { PLAYER_CHARACTER, OPPONENT_CHARACTER, PLAYER_SUPPORT, OPPONENT_SUPPORT, END_CALCULATION }
var whoStartedRound: int
var roundStage: RoundStage
var isRoundActive: bool = false
var opponentMaxCards: int = 4
var opponentStartingSupportCards: int = 2
var previousRoundFaction: String = ""
var previousRoundRoles: Array = []
enum Winner { TIE, PLAYER, OPPONENT }
var lastRoundWinner: int = Winner.TIE
var isPlayerThinking: bool = false
var currentThinkTime: float = 0.0
var cachedSupportStarter: int = Actor.Type.PLAYER

func _process(delta: float) -> void:
	if isRoundActive:
		HoldoutStats.count_time_played(delta)
		
		# Analysis Paralysis Accolade tracker
		if isPlayerThinking:
			currentThinkTime += delta
			if currentThinkTime > HoldoutStats.longestThinkTime:
				HoldoutStats.longestThinkTime = currentThinkTime

func set_player_thinking(isThinking: bool) -> void:
	isPlayerThinking = isThinking
	if not isThinking:
		currentThinkTime = 0.0

func end_round_cleanup(faction: String, roles: String) -> void:
	previousRoundFaction = faction
	previousRoundRoles = Array(roles.split("/"))
	HoldoutStats.roundsPlayed += 1

# --- GAME RULES ---
var maxCharacterCards: int = 4
var maxSupportCards: int = 4
var startingSupportCards: int = 2
var minCardsForReshuffle: int = 5
var roundsTillSupportDraw: int = 3
var roundsTillSupportDrawOpponent: int = 3

func _recalculate_limits() -> void:
	maxCharacterCards = 4
	startingSupportCards = 2
	maxSupportCards = 4
	minCardsForReshuffle = 5
	startingSupportCards = 2
	roundsTillSupportDraw = 3
	roundsTillSupportDrawOpponent = 3
	
	var hasReducedHand = has_modifier(Database.Modifier.REDUCED_HAND)
	var hasVolatileHand = has_modifier(Database.Modifier.VOLATILE_HAND)
	var hasLoneWolf = has_modifier(Database.Modifier.LONE_WOLF)
	var hasSupplyLine = has_modifier(Database.Modifier.SUPPLY_LINE)
	var hasBlackMarket = has_modifier(Database.Modifier.BLACK_MARKET)
	var hasSeveredSupply = has_modifier(Database.Modifier.SEVERED_SUPPLY)
	
	if hasVolatileHand:
		minCardsForReshuffle = 6
		
	if hasReducedHand:
		maxCharacterCards = 3
		maxSupportCards = 3
	
	if hasBlackMarket:
		startingSupportCards = 4
		roundsTillSupportDraw = 4
	
	if hasSeveredSupply:
		startingSupportCards = 4
	
	if hasLoneWolf:
		if hasVolatileHand: minCardsForReshuffle = 10
		maxCharacterCards = 6 if hasReducedHand else 8
		maxSupportCards = 0
		startingSupportCards = 0
	
	if hasSupplyLine:
		if hasVolatileHand: minCardsForReshuffle = 10
		maxSupportCards = 6 if hasReducedHand else 8
		maxCharacterCards = 0
		startingSupportCards = 6
		roundsTillSupportDraw = 2
	
	# Black Market's slower replenish takes priority over Supply Line's faster one
	if hasBlackMarket and hasSupplyLine:
		roundsTillSupportDraw = 4

# --- SUPPORT BLOCKING ---
var _blockedSupportSide: int = Actor.Type.NONE

func block_support(who: int) -> void:
	_blockedSupportSide = who

func is_support_blocked(who: int) -> bool:
	return _blockedSupportSide == who

func clear_support_block() -> void:
	_blockedSupportSide = Actor.Type.NONE

# --- MODIFIER SYSTEM ---
var activeModifierIds: Array[int] = []
var blindEyeChance: float = 0.40
var isBlindEyeActiveThisRound: bool = false
var gamblerChance: float = 0.30
var stackedOddsStreak: int = 0

func has_modifier(modifierId: int) -> bool:
	return activeModifierIds.has(modifierId)

func add_modifier(modifierId: int) -> void:
	if not activeModifierIds.has(modifierId):
		activeModifierIds.append(modifierId)
		_recalculate_limits()
		modifier_toggled.emit(modifierId, true)

func remove_modifier(modifierId: int) -> void:
	activeModifierIds.erase(modifierId)
	_recalculate_limits()
	modifier_toggled.emit(modifierId, false)

func get_support_starter() -> int:
	return cachedSupportStarter

func get_stacked_odds_bonus() -> int:
	if not has_modifier(Database.Modifier.STACKED_ODDS):
		return 0
	return stackedOddsStreak


func update_stacked_odds(winner: int) -> int:
	if not has_modifier(Database.Modifier.STACKED_ODDS):
		return 0
	
	if winner == Winner.OPPONENT:
		stackedOddsStreak += 1
		return 0
		
	elif winner == Winner.PLAYER:
		var brokenStreak = stackedOddsStreak
		
		stackedOddsStreak = 0
		
		return brokenStreak if brokenStreak >= 3 else 0
	
	return 0

# --- VALIDATION MATH ---
func check_guerrilla_restriction(cardFaction: String, cardRoles: String) -> bool:
	if not has_modifier(Database.Modifier.GUERRILLA_TACTICS) or previousRoundFaction == "":
		return false
		
	if cardFaction == previousRoundFaction:
		return true
		
	var cRoles = cardRoles.split("/")
	for role in cRoles:
		if role in previousRoundRoles:
			return true
			
	return false

# --- COMBAT MATH & STATS ---
func process_combat_stats(playerTotal: int, opponentTotal: int, playerKey: String, opponentKey: String) -> Dictionary:
	var damage = abs(playerTotal - opponentTotal)
	var combatWinner = Winner.TIE
	
	# Update Dominance
	if (playerTotal - opponentTotal) > HoldoutStats.highestDominance:
		HoldoutStats.highestDominance = (playerTotal - opponentTotal)
		
	# Determine Winner & Update Streaks
	var playerWins = playerTotal > opponentTotal
	var opponentWins = opponentTotal > playerTotal
	
	if playerWins:
		combatWinner = Winner.PLAYER
		HoldoutStats.currentStreak += 1
		if HoldoutStats.longestStreak < HoldoutStats.currentStreak:
			HoldoutStats.longestStreak = HoldoutStats.currentStreak
			
		# Underdog Check
		var playerBase = Database.CHARACTERS[playerKey][0]
		var opponentBase = Database.CHARACTERS[opponentKey][0]
		if playerBase <= 3 or playerBase < opponentBase:
			HoldoutStats.underdogWins += 1
			
	elif opponentWins:
		combatWinner = Winner.OPPONENT
		HoldoutStats.currentStreak = 0
	else:
		combatWinner = Winner.TIE
		HoldoutStats.currentStreak = 0

	# Check Old Wounds Accolade
	if HoldoutStats.RIVALRIES.has(playerKey):
		var rivals = HoldoutStats.RIVALRIES[playerKey]
		if opponentKey in rivals:
			HoldoutStats.achievedOldWounds = true

	# Check Complex Modifiers
	var triggerCalculatedRisk = (has_modifier(Database.Modifier.CALCULATED_RISK) and combatWinner == Winner.PLAYER and damage == 1)
	var triggerCalculatedRiskLoss = (has_modifier(Database.Modifier.CALCULATED_RISK) and combatWinner == Winner.OPPONENT and damage == 1)
	var triggerDeepWounds = (has_modifier(Database.Modifier.DEEP_WOUNDS) and combatWinner == Winner.OPPONENT and damage >= 5)
	
	var overExertionBonus = 0
	if has_modifier(Database.Modifier.OVER_EXERTION) and playerTotal > 10:
		overExertionBonus = playerTotal - 10
	
	return {
		"winner": combatWinner,
		"damage": damage,
		"triggerCalculatedRisk": triggerCalculatedRisk,
		"triggerCalculatedRiskLoss": triggerCalculatedRiskLoss,
		"triggerDeepWounds": triggerDeepWounds,
		"overExertionBonus": overExertionBonus
	}

# --- ACTION HISTORY ---
var actionHistory: Array[String] = []

func log_action(message: String) -> void:
	actionHistory.append(message)

func clear_history() -> void:
	actionHistory.clear()

# --- STATE MACHINE CONTROLS ---
func start_new_round(isAlwaysFirst: bool, roundsPlayed: int) -> void:
	clear_support_block()
	
	if has_modifier(Database.Modifier.BLIND_EYE):
		isBlindEyeActiveThisRound = randf() <= blindEyeChance
	else:
		isBlindEyeActiveThisRound = false
	
	if roundsPlayed % 2 == 0 and not isAlwaysFirst:
		whoStartedRound = Actor.Type.OPPONENT
		set_phase(RoundStage.OPPONENT_CHARACTER)
	else:
		whoStartedRound = Actor.Type.PLAYER
		set_phase(RoundStage.PLAYER_CHARACTER)
	
	cachedSupportStarter = Actor.Type.OPPONENT if has_modifier(Database.Modifier.FRONT_RUNNER) else whoStartedRound
	
	isRoundActive = true

func player_played_character() -> void:
	if whoStartedRound == Actor.Type.PLAYER:
		set_phase(RoundStage.OPPONENT_CHARACTER)
	else:
		set_phase(RoundStage.PLAYER_SUPPORT if whoStartedRound == Actor.Type.PLAYER else RoundStage.OPPONENT_SUPPORT)

func opponent_played_character() -> void:
	if whoStartedRound == Actor.Type.OPPONENT:
		set_phase(RoundStage.PLAYER_CHARACTER)
	else:
		set_phase(RoundStage.PLAYER_SUPPORT)

func player_played_support() -> void:
	if get_support_starter() == Actor.Type.PLAYER:
		set_phase(RoundStage.OPPONENT_SUPPORT)
	else:
		set_phase(RoundStage.END_CALCULATION)


func opponent_played_support() -> void:
	if get_support_starter() == Actor.Type.OPPONENT:
		set_phase(RoundStage.PLAYER_SUPPORT)
	else:
		set_phase(RoundStage.END_CALCULATION)


func set_phase(newPhase: RoundStage) -> void:
	roundStage = newPhase
	phase_changed.emit(newPhase)

# --- SAVE & LOAD ---
func get_engine_save_dict() -> Dictionary:
	return {
		"whoStartedRound": whoStartedRound,
		"roundStage": roundStage,
		"activeModifierIds": activeModifierIds.duplicate(),
		"actionHistory": actionHistory.duplicate(),
		"stackedOddsStreak": stackedOddsStreak,
	}

func load_engine_save_dict(data: Dictionary) -> void:
	whoStartedRound = int(data.get("whoStartedRound", 0))
	roundStage = int(data.get("roundStage", 0)) as RoundStage
	actionHistory.assign(data.get("actionHistory", []))
	stackedOddsStreak = int(data.get("stackedOddsStreak", 0))
	
	activeModifierIds.clear()
	var saved_mods = data.get("activeModifierIds", [])
	for mod_id in saved_mods:
		add_modifier(int(mod_id))
