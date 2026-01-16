extends Node

enum Mode { MAIN_MENU, MODIFIER_SELECTION, CARD_DRAW, JUNE_RAVEL, LAST_STAND, LAST_STAND_ROUND_COMPLETED }

var invitationAccepted: bool = false
var gameMode: Mode = Mode.MAIN_MENU
var totalInGameTimePlayed: float = 0.0

var playerHealthValue: int
var opponentList: Array = []

# Per round stats
var currentPlayer: Actor.Avatar
var currentOpponent: Actor.Avatar

var numberOfWins: int = 0
var roundNumber: int = 1
var totalForceExerted: int = 0
var opponentForceExerted: int = 0
var highestDamageDealt: int = 0
var roundWinsUnderdog: int = 0
var allPlayedCards: Array = []
var multiplierTotal: float = 1.0
var activeModifiers: Array = []

var allOpponentCards: Array = []

var currentRoundDuration: float = 0.0 
var canCountDuration: bool = false

var lastStandTotalScore: int = 0
var lastStandCurrentRoundScore: int = 0
var replayedRound: bool = false

# Data logging variables
const LOG_FILE_PATH = "user://game_balance_data.json"
var currentGameSession: String = ""

func _process(delta):
	if canCountDuration:
		currentRoundDuration += delta

func set_start_time():
	currentRoundDuration = 0.0
	canCountDuration = true

func set_end_time():
	canCountDuration = false

func reset_round_stats():
	roundNumber = 1
	totalForceExerted = 0
	opponentForceExerted = 0
	highestDamageDealt = 0
	roundWinsUnderdog = 0
	lastStandCurrentRoundScore = 0
	allPlayedCards.clear()
	allOpponentCards.clear()

func reset_all_data():
	reset_round_stats()
	
	numberOfWins = 0
	lastStandTotalScore = 0
	totalInGameTimePlayed = 0.0
	multiplierTotal = 1.0
	activeModifiers.clear()
	opponentList.clear()

func record_played_card(faction: String, cardKey: String, value: int = 0, opponentCard: bool = false):
	if !opponentCard:
		allPlayedCards.append({"faction": faction, "cardKey": cardKey, "value": value})
	else:
		allOpponentCards.append({"faction": faction, "cardKey": cardKey, "value": value})

# Data logging function
func start_new_run_log():
	currentGameSession = str(Time.get_unix_time_from_system())

func log_battle_results(outcome: String):
	if not OS.is_debug_build():
		return
	
	var battleData = {
		"roundCount": roundNumber,
		"outcome": outcome,
		"playerHealthRemaining": playerHealthValue,
		"durationInSeconds": currentRoundDuration,
		"totalForcePlayer": totalForceExerted,
		"totalForceOpponent": opponentForceExerted,
		"highestDamageDealt": highestDamageDealt,
		"underdogRounds": roundWinsUnderdog,
		"multiplier": multiplierTotal,
		"activeModifiers": _get_readable_modifiers(),
		"roundScore": lastStandCurrentRoundScore,
		"totalScore": lastStandTotalScore + lastStandCurrentRoundScore,
		"cardsPlayed": allPlayedCards.duplicate(),
		"opponentCards": allOpponentCards.duplicate()
	}

	_append_to_log_file(battleData)

func _get_readable_modifiers() -> Array:
	var readable_list = []
	for mod in activeModifiers:
		if typeof(mod) == TYPE_DICTIONARY and mod.has("name"):
			readable_list.append(mod["name"])
		else:
			readable_list.append(mod)
	return readable_list

func _append_to_log_file(new_battle_data: Dictionary):
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
