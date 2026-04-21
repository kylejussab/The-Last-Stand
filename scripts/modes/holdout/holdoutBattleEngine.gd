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
var previousRoundFaction: String = ""
var previousRoundRoles: Array = []
enum Winner { TIE, PLAYER, OPPONENT }
var isPlayerThinking: bool = false
var currentThinkTime: float = 0.0

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
var minCardsForReshuffle: int = 5

func _recalculate_limits() -> void:
	maxCharacterCards = 4
	maxSupportCards = 4
	minCardsForReshuffle = 5
	
	var hasReducedHand = has_modifier(Database.Modifier.REDUCED_HAND)
	var hasVolatileHand = has_modifier(Database.Modifier.VOLATILE_HAND)
	var hasLoneWolf = has_modifier(Database.Modifier.LONE_WOLF)
	var hasSupplyLine = has_modifier(Database.Modifier.SUPPLY_LINE)
	
	if hasVolatileHand:
		minCardsForReshuffle = 6
		
	if hasReducedHand:
		maxCharacterCards = 3
		maxSupportCards = 3
		
	if hasLoneWolf:
		if hasVolatileHand: minCardsForReshuffle = 10
		maxCharacterCards = 6 if hasReducedHand else 8
		maxSupportCards = 0
		
	if hasSupplyLine:
		if hasVolatileHand: minCardsForReshuffle = 10
		maxSupportCards = 6 if hasReducedHand else 8
		maxCharacterCards = 0

# --- MODIFIER SYSTEM ---
var activeModifierIds: Array[int] = []

func has_modifier(modifierId: int) -> bool:
	return activeModifierIds.has(modifierId)

func add_modifier(modifierId: int) -> void:
	if not activeModifierIds.has(modifierId):
		activeModifierIds.append(modifierId)
		modifier_toggled.emit(modifierId, true)

func remove_modifier(modifierId: int) -> void:
	activeModifierIds.erase(modifierId)
	modifier_toggled.emit(modifierId, false)

# --- VALIDATION MATH ---
func check_support_match(characterRoles: String, supportRoles: String) -> bool:
	var cRoles = characterRoles.split("/")
	var sRoles = supportRoles.split("/")
	
	for role in cRoles:
		if role in sRoles:
			return true
			
	return false

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
	if playerTotal > opponentTotal:
		combatWinner = Winner.PLAYER
		HoldoutStats.currentStreak += 1
		if HoldoutStats.longestStreak < HoldoutStats.currentStreak:
			HoldoutStats.longestStreak = HoldoutStats.currentStreak
			
		# Underdog Check
		var playerBase = Database.CHARACTERS[playerKey][0]
		var opponentBase = Database.CHARACTERS[opponentKey][0]
		if playerBase <= 3 or playerBase < opponentBase:
			HoldoutStats.underdogWins += 1
			
	elif opponentTotal > playerTotal:
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
	var triggerDeepWounds = (has_modifier(Database.Modifier.DEEP_WOUNDS) and combatWinner == Winner.OPPONENT and damage >= 5)
	var triggerOverExertion = (has_modifier(Database.Modifier.OVER_EXERTION) and playerTotal >= 10)
	
	return {
		"winner": combatWinner,
		"damage": damage,
		"triggerCalculatedRisk": triggerCalculatedRisk,
		"triggerDeepWounds": triggerDeepWounds,
		"triggerOverExertion": triggerOverExertion
	}

# --- STATE MACHINE CONTROLS ---
func start_new_round(isAlwaysFirst: bool, roundsPlayed: int) -> void:
	if roundsPlayed % 2 == 0 and not isAlwaysFirst:
		whoStartedRound = Actor.Type.OPPONENT
		set_phase(RoundStage.OPPONENT_CHARACTER)
	else:
		whoStartedRound = Actor.Type.PLAYER
		set_phase(RoundStage.PLAYER_CHARACTER)
		
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
	if whoStartedRound == Actor.Type.PLAYER:
		set_phase(RoundStage.OPPONENT_SUPPORT)
	else:
		set_phase(RoundStage.END_CALCULATION)

func opponent_played_support() -> void:
	if whoStartedRound == Actor.Type.OPPONENT:
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
		"activeModifierIds": activeModifierIds.duplicate()
	}

func load_engine_save_dict(data: Dictionary) -> void:
	whoStartedRound = int(data.get("whoStartedRound", 0))
	roundStage = int(data.get("roundStage", 0)) as RoundStage
	
	activeModifierIds.clear()
	var saved_mods = data.get("activeModifierIds", [])
	for mod_id in saved_mods:
		add_modifier(int(mod_id))
