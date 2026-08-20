extends Node

enum Mode { SPLASH_SCREEN, MAIN_MENU, MODIFIER_SELECTION, CARD_DRAW, JUNE_RAVEL, HOLDOUT, HOLDOUT_ROUND_COMPLETED, HOLDOUT_TUTORIAL }

var invitationAccepted: bool = false
var gameMode: Mode = Mode.MAIN_MENU

var totalInGameTimePlayed: float = 0.0
var showHoldoutTutorial: bool = true 
var showHoldoutCharacterSupportIndicator: bool = true
var rations: int = 0

func _ready() -> void:
	var saveData = SaveManager.load_main_state()
	
	if not saveData.is_empty():
		totalInGameTimePlayed = saveData.get("totalInGameTimePlayed", 0.0)
		rations = saveData.get("rations", 0)
		showHoldoutTutorial = saveData.get("showHoldoutTutorial", true)
		showHoldoutCharacterSupportIndicator = saveData.get("showHoldoutCharacterSupportIndicator", true)
		
		holdoutRunsAttempted = saveData.get("holdoutRunsAttempted", 0)
		holdoutBattlesWon = saveData.get("holdoutBattlesWon", 0)
		holdoutTimePlayed = saveData.get("holdoutTimePlayed", 0.0)
		holdoutUnderdogWins = saveData.get("holdoutUnderdogWins", 0)
		holdoutCardsPlayed = saveData.get("holdoutCardsPlayed", 0)
		
		holdoutHighestDominance = saveData.get("holdoutHighestDominance", 0)
		holdoutLongestStreak = saveData.get("holdoutLongestStreak", 0)
		holdoutHighestMultiplier = saveData.get("holdoutHighestMultiplier", 1.0)
		holdoutFastestWin = saveData.get("holdoutFastestWin", 99999.0)
		holdoutBestRank = saveData.get("holdoutBestRank", HoldoutStats.Rank.F)
		
		holdoutMvpCounts = saveData.get("holdoutMvpCounts", {})
		holdoutFactionUses = saveData.get("holdoutFactionUses", {})
		holdoutCardUses = saveData.get("holdoutCardUses", {})
		holdoutNemesisKills = saveData.get("holdoutNemesisKills", {})
		holdoutModifierUses = saveData.get("holdoutModifierUses", {})
		
		var savedAccolades = saveData.get("holdoutAccoladeCounts", {})
		for key in savedAccolades:
			holdoutAccoladeCounts[key] = savedAccolades[key]

# Holdout stats
var holdoutRunsAttempted: int = 0
var holdoutBattlesWon: int = 0
var holdoutTimePlayed: float = 0.0
var holdoutUnderdogWins: int = 0
var holdoutCardsPlayed: int = 0

var holdoutHighestDominance: int = 0
var holdoutLongestStreak: int = 0
var holdoutHighestMultiplier: float = 1.0
var holdoutFastestWin: float = 99999.0
var holdoutBestRank: HoldoutStats.Rank = HoldoutStats.Rank.F

var holdoutMvpCounts: Dictionary = {}
var holdoutFactionUses: Dictionary = {}
var holdoutCardUses: Dictionary = {}
var holdoutNemesisKills: Dictionary = {}
var holdoutModifierUses: Dictionary = {}
var holdoutAccoladeCounts: Dictionary = {
	"Untouchable": 0,
	"OldWounds": 0,
	"Executioner": 0,
	"GiantSlayer": 0,
	"Relentless": 0,
	"QuickDraw": 0,
	"ThrillSeeker": 0,
	"Purist": 0,
	"SpeedDemon": 0,
	"Brawler": 0,
	"AnalysisParalysis": 0,
	"RubberDuck": 0
}

func push_holdout_battle_stats(isVictory: bool):
	if isVictory:
		holdoutBattlesWon += 1
		
		if HoldoutStats.currentRoundDuration > 0:
			holdoutFastestWin = min(holdoutFastestWin, HoldoutStats.currentRoundDuration)
	else:
		var nemesisName = "Unknown"
		
		if Database.AVATARS.has(HoldoutStats.currentOpponent):
			nemesisName = Database.AVATARS[HoldoutStats.currentOpponent]["name"]
			
		holdoutNemesisKills[nemesisName] = holdoutNemesisKills.get(nemesisName, 0) + 1
	
	holdoutUnderdogWins += HoldoutStats.underdogWins
	holdoutCardsPlayed += HoldoutStats.allPlayedCards.size()
	
	holdoutHighestDominance = max(holdoutHighestDominance, HoldoutStats.highestDominance)
	holdoutLongestStreak = max(holdoutLongestStreak, HoldoutStats.longestStreak)
	holdoutHighestMultiplier = max(holdoutHighestMultiplier, HoldoutStats.multiplierTotal)
	
	if HoldoutStats.currentRank < holdoutBestRank:
		holdoutBestRank = HoldoutStats.currentRank
	
	holdoutTimePlayed += HoldoutStats.currentRoundDuration
	
	for card in HoldoutStats.allPlayedCards:
		var faction = card["faction"]
		var key = card["cardKey"]
		
		if faction != "Support":
			holdoutFactionUses[faction] = holdoutFactionUses.get(faction, 0) + 1
			
		holdoutCardUses[key] = holdoutCardUses.get(key, 0) + 1
	
	save_game()

# --- SAVING & LOADING ---
func get_save_dict() -> Dictionary:
	return {
		"totalInGameTimePlayed": totalInGameTimePlayed,
		"rations": rations,
		"showHoldoutTutorial": showHoldoutTutorial,
		"showHoldoutCharacterSupportIndicator": showHoldoutCharacterSupportIndicator,
		
		"holdoutRunsAttempted": holdoutRunsAttempted,
		"holdoutBattlesWon": holdoutBattlesWon,
		"holdoutTimePlayed": holdoutTimePlayed,
		"holdoutUnderdogWins": holdoutUnderdogWins,
		"holdoutCardsPlayed": holdoutCardsPlayed,
		
		"holdoutHighestDominance": holdoutHighestDominance,
		"holdoutLongestStreak": holdoutLongestStreak,
		"holdoutHighestMultiplier": holdoutHighestMultiplier,
		"holdoutFastestWin": holdoutFastestWin,
		"holdoutBestRank": holdoutBestRank,
		
		"holdoutMvpCounts": holdoutMvpCounts,
		"holdoutFactionUses": holdoutFactionUses,
		"holdoutCardUses": holdoutCardUses,
		"holdoutNemesisKills": holdoutNemesisKills,
		"holdoutModifierUses": holdoutModifierUses,
		"holdoutAccoladeCounts": holdoutAccoladeCounts
	}

func save_game():
	var saveData = SaveManager.load_main_state()
	saveData.merge(get_save_dict(), true) 
	
	SaveManager.save_main_state(saveData)

func record_modifier_selection(modName: String) -> void:
	holdoutModifierUses[modName] = holdoutModifierUses.get(modName, 0) + 1
	save_game()

func reset_all_data() -> void:
	totalInGameTimePlayed = 0.0
	showHoldoutTutorial = true
	showHoldoutCharacterSupportIndicator = true
	rations = 0
	
	holdoutRunsAttempted = 0
	holdoutBattlesWon = 0
	holdoutTimePlayed = 0.0
	holdoutUnderdogWins = 0
	holdoutCardsPlayed = 0
	
	holdoutHighestDominance = 0
	holdoutLongestStreak = 0
	holdoutHighestMultiplier = 1.0
	holdoutFastestWin = 99999.0
	holdoutBestRank = HoldoutStats.Rank.F
	
	holdoutMvpCounts.clear()
	holdoutFactionUses.clear()
	holdoutCardUses.clear()
	holdoutNemesisKills.clear()
	holdoutModifierUses.clear()
	
	for key in holdoutAccoladeCounts:
		holdoutAccoladeCounts[key] = 0
