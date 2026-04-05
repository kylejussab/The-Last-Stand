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

const ACCOLADES = {
	"Untouchable": {
		"id": "Untouchable",
		"title": "Untouchable", 
		"description": "Win a battle without taking any damage."
	},
	"OldWounds": {
		"id": "OldWounds",
		"title": "Old Wounds", 
		"description": "Win an encounter against a rival character."
	},
	"Executioner": {
		"id": "Executioner",
		"title": "Executioner", 
		"description": "Achieve a Dominance of 10 or higher in a single round."
	},
	"GiantSlayer": {
		"id": "GiantSlayer",
		"title": "Giant Slayer", 
		"description": "Win a battle with 3 or more Underdog round victories."
	},
	"Relentless": {
		"id": "Relentless",
		"title": "Relentless", 
		"description": "Maintain a win streak of 4 or more rounds."
	},
	"QuickDraw": {
		"id": "QuickDraw",
		"title": "Quick Draw", 
		"description": "Win a battle in 3 rounds or fewer."
	},
	"ThrillSeeker": {
		"id": "ThrillSeeker",
		"title": "Thrill Seeker", 
		"description": "Win a battle with a modifier multiplier of 2.0 or higher."
	},
	"Purist": {
		"id": "Purist",
		"title": "Purist", 
		"description": "Win a battle with no modifiers active."
	},
	"SpeedDemon": {
		"id": "SpeedDemon",
		"title": "Speed Demon", 
		"description": "Win a battle in under 60 seconds."
	},
	"Brawler": {
		"id": "Brawler",
		"title": "Brawler", 
		"description": "Win a battle without playing a Support card."
	},
	"AnalysisParalysis": {
		"id": "AnalysisParalysis",
		"title": "Analysis Paralysis", 
		"description": "Spend over 30 seconds on a single turn without playing a card."
	},
	"RubberDuck": {
		"id": "RubberDuck",
		"title": "Rubber Duck", 
		"description": "Complete a battle without meeting the requirements for any other accolade."
	}
}

const RIVALRIES = {
	"AbbyFirefly": ["JoelSmuggler", "Ellie", "Joel", "RatKing", "Emily"],
	"Abby": ["JoelSmuggler", "Ellie", "Joel", "RatKing", "Emily"],
	"JoelSmuggler": ["AbbyFirefly", "Abby", "Marlene"],
	"Joel": ["AbbyFirefly", "Abby", "Marlene"],
	"Marlene": ["Joel", "JoelSmuggler"],
	"TommyFirefly": ["AbbyFirefly", "Abby"],
	"Tommy": ["AbbyFirefly", "Abby"],
	"Ellie": ["AbbyFirefly", "Abby", "Nora"],
	"Nora": ["Ellie"],
	"Isaac": ["Yara", "Lev", "TheProphet"],
	"IsaacHumanity": ["Yara", "Lev", "TheProphet"],
	"Yara": ["Isaac", "IsaacHumanity"],
	"Lev": ["Isaac", "IsaacHumanity"],
	"Shimmer": ["WLFSoldier", "WLFSoldierHumanity"]
}

const FACTION_COLORS = {"Jackson": Color("7b9e49"), "WLF": Color("80aedd"), "Seraphite": Color("a188bf"), "Firefly": Color("e6c54f"), "Infected": Color("f6d978"), "Smuggler": Color("ffffff")}

const RANK_COLORS = {
	HoldoutStats.Rank.S: Color("fbbf24"),
	HoldoutStats.Rank.A: Color("6ee7b7"),
	HoldoutStats.Rank.B: Color("93c5fd"),
	HoldoutStats.Rank.C: Color("c4b5fd"),
	HoldoutStats.Rank.D: Color("f9a8d4"),
	HoldoutStats.Rank.F: Color("fdba74")
}

static var numberOfWins: int = 0
static var roundsPlayed: int = 1
static var longestStreak: int = 0
static var currentStreak: int = 0
static var highestDominance: int = 0
static var underdogWins: int = 0
static var multiplierTotal: float = 1.0
static var totalRunRations: int = 0
static var currentRunRations: int = 0

static var playerHealthAtRoundStart: int
static var achievedOldWounds: bool = false
static var longestThinkTime: float = 0.0

static func count_time_played(delta: float):
	currentRoundDuration += delta

static func reset_for_new_run():
	numberOfWins = 0
	totalRunRations = 0
	
	GameStats.holdoutRunsAttempted += 1
	
	multiplierTotal = 1.0
	activeModifiers.clear()
	opponentList.clear()
	currentRunRations = 0
	replayedRound = false
	currentRank = Rank.F
	
	start_new_run_log()
	
	reset_for_new_battle()

static func reset_for_new_battle():
	playerHealthAtRoundStart = playerHealthValue
	currentRoundDuration = 0.0
	currentRunRations = 0
	underdogWins = 0
	roundsPlayed = 1
	longestStreak = 0
	currentStreak = 0
	highestDominance = 0
	
	allPlayedCards.clear()
	allOpponentCards.clear()
	
	achievedOldWounds = false
	longestThinkTime = 0.0

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

# Saving and loading
static func get_save_dict() -> Dictionary:
	return {
		"currentPlayer": currentPlayer,
		"currentOpponent": currentOpponent,
		"currentBattleSeed": currentBattleSeed,
		"currentRoundDuration": currentRoundDuration,
		"opponentList": opponentList,
		"playerHealthValue": playerHealthValue,
		"playerHealthAtRoundStart": playerHealthAtRoundStart,
		"activeModifiers": activeModifiers,
		"currentRank": currentRank,
		"numberOfWins": numberOfWins,
		"roundsPlayed": roundsPlayed,
		"longestStreak": longestStreak,
		"currentStreak": currentStreak,
		"highestDominance": highestDominance,
		"underdogWins": underdogWins,
		"multiplierTotal": multiplierTotal,
		"totalRunRations": totalRunRations,
		"currentRunRations": currentRunRations,
		"achievedOldWounds": achievedOldWounds,
		"longestThinkTime": longestThinkTime,
		"allPlayedCards": allPlayedCards,
		"allOpponentCards": allOpponentCards
	}

static func load_save_dict(data: Dictionary) -> void:
	currentPlayer = int(data["currentPlayer"]) as Actor.Avatar
	currentOpponent = int(data["currentOpponent"]) as Actor.Avatar
	currentRank = int(data["currentRank"]) as Rank
	
	currentBattleSeed = data["currentBattleSeed"]
	currentRoundDuration = data["currentRoundDuration"]
	opponentList = data["opponentList"]
	playerHealthValue = int(data["playerHealthValue"])
	playerHealthAtRoundStart = int(data["playerHealthAtRoundStart"])
	
	activeModifiers.clear()
	for mod in data["activeModifiers"]:
		mod["id"] = int(mod["id"])
		mod["duration"] = int(mod["duration"])
		
		if mod.has("currentDuration"):
			mod["currentDuration"] = int(mod["currentDuration"])
			
		if mod.has("amount"):
			mod["amount"] = int(mod["amount"])
			
		activeModifiers.append(mod)
	
	numberOfWins = int(data["numberOfWins"])
	roundsPlayed = int(data["roundsPlayed"])
	longestStreak = int(data["longestStreak"])
	currentStreak = int(data["currentStreak"])
	highestDominance = int(data["highestDominance"])
	underdogWins = int(data["underdogWins"])
	multiplierTotal = data["multiplierTotal"]
	totalRunRations = int(data["totalRunRations"])
	currentRunRations = int(data["currentRunRations"])
	achievedOldWounds = data["achievedOldWounds"]
	longestThinkTime = data["longestThinkTime"]
	allPlayedCards = data["allPlayedCards"]
	allOpponentCards = data["allOpponentCards"]
