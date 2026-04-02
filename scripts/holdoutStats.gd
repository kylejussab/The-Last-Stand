class_name HoldoutStats

# Initialization stats
static var currentPlayer: Actor.Avatar
static var currentOpponent: Actor.Avatar
static var currentBattleSeed: int = 0
static var replayedRound: bool = false
static var currentRoundDuration: float = 0.0
static var opponentList: Array = []
static var playerHealthValue: int
static var activeModifiers: Array = []
static var lastOfferedModifierIds: Array = [] # Used for weighted randomness with modifier selection
enum Rank { S, A, B, C, D, F }
const RankRequirements = {Rank.S: 440, Rank.A: 300, Rank.B: 220, Rank.C: 160, Rank.D: 80, Rank.F: 0}
static var currentRank: Rank = Rank.F

static var numberOfWins: int = 0
static var roundsPlayed: int = 1
static var longestStreak: int = 0
static var currentStreak: int = 0
static var highestDominance: int = 0
static var underdogWins: int = 0
static var multiplierTotal: float = 1.0
static var totalRunRations: int = 0
static var currentRunRations: int = 0

static func count_time_played(delta: float):
	currentRoundDuration += delta

static func reset_for_new_run():
	numberOfWins = 0
	longestStreak = 0
	totalRunRations = 0
	
	multiplierTotal = 1.0
	activeModifiers.clear()
	opponentList.clear()
	currentRunRations = 0
	replayedRound = false
	currentRank = Rank.F
	
	start_new_run_log()
	
	reset_for_new_battle()

static func reset_for_new_battle():
	currentRoundDuration = 0.0
	currentRunRations = 0
	underdogWins = 0
	roundsPlayed = 1
	currentStreak = 0
	highestDominance = 0
	
	allPlayedCards.clear()
	allOpponentCards.clear()

# Used for data collection
static var allPlayedCards: Array = []
static var allOpponentCards: Array = []

const LOG_FILE_PATH = "user://game_balance_data.json"
static var currentGameSession: String = ""

static func record_played_card(faction: String, cardKey: String, value: int = 0, opponentCard: bool = false):
	if !opponentCard:
		allPlayedCards.append({"faction": faction, "cardKey": cardKey, "value": value})
	else:
		allOpponentCards.append({"faction": faction, "cardKey": cardKey, "value": value})

static func evaluate_rank(score: int) -> Rank:
	if score >= RankRequirements[Rank.S]: return Rank.S
	elif score >= RankRequirements[Rank.A]: return Rank.A
	elif score >= RankRequirements[Rank.B]: return Rank.B
	elif score >= RankRequirements[Rank.C]: return Rank.C
	elif score >= RankRequirements[Rank.D]: return Rank.D
	else: return Rank.F

static func get_distance_to_next(score: int) -> int:
	match currentRank:
		Rank.F: return RankRequirements[Rank.D] - score
		Rank.D: return RankRequirements[Rank.C] - score
		Rank.C: return RankRequirements[Rank.B] - score
		Rank.B: return RankRequirements[Rank.A] - score
		Rank.A: return RankRequirements[Rank.S] - score
		Rank.S: return 0
	return 0

static func get_current_rank_string() -> String:
	return Rank.keys()[currentRank]

static func get_next_rank_string() -> String:
	if currentRank == Rank.S:
		return ""
	
	return Rank.keys()[currentRank - 1]

# Data Logging
static func start_new_run_log():
	currentGameSession = str(Time.get_unix_time_from_system())

static func log_battle_results(outcome: String):
	if not OS.is_debug_build():
		return
	
	var battleData = {
		"roundsPlayed": roundsPlayed,
		"outcome": outcome,
		"durationInSeconds": currentRoundDuration,
		"underdogWins": underdogWins,
		"multiplier": multiplierTotal,
		"activeModifiers": _get_readable_modifiers(),
		"cardsPlayed": allPlayedCards.duplicate(),
		"opponentCards": allOpponentCards.duplicate()
	}

	_append_to_log_file(battleData)

static func _get_readable_modifiers() -> Array:
	var readable_list = []
	for mod in activeModifiers:
		if typeof(mod) == TYPE_DICTIONARY and mod.has("name"):
			readable_list.append(mod["name"])
		else:
			readable_list.append(mod)
	return readable_list

static func _append_to_log_file(new_battle_data: Dictionary):
	var all_data = {}
	
	if FileAccess.file_exists(LOG_FILE_PATH):
		var file = FileAccess.open(LOG_FILE_PATH, FileAccess.READ)
		var text = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(text)
		if parse_result == OK:
			all_data = json.data
		file.close()
	
	if not all_data.has(currentGameSession):
		all_data[currentGameSession] = []
	
	all_data[currentGameSession].append(new_battle_data)
	
	var save_file = FileAccess.open(LOG_FILE_PATH, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(all_data, "\t"))
	save_file.close()
