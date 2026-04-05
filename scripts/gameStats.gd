extends Node

enum Mode { SPLASH_SCREEN, MAIN_MENU, MODIFIER_SELECTION, CARD_DRAW, JUNE_RAVEL, HOLDOUT, HOLDOUT_ROUND_COMPLETED }

var invitationAccepted: bool = false
var gameMode: Mode = Mode.MAIN_MENU

var totalInGameTimePlayed: float = 0.0

var rations: int = 0


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
	
	for mod in HoldoutStats.activeModifiers:
		var modName = "Unknown Modifier"
		
		if typeof(mod) == TYPE_DICTIONARY and mod.has("name"):
			modName = mod["name"]
		else:
			modName = str(mod) 
			
		holdoutModifierUses[modName] = holdoutModifierUses.get(modName, 0) + 1
	
	save_game()

# --- SAVING & LOADING ---
func get_save_dict() -> Dictionary:
	return {
		"totalInGameTimePlayed": totalInGameTimePlayed,
		"rations": rations,
		
		
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
		
		"holdoutFactionUses": holdoutFactionUses,
		"holdoutCardUses": holdoutCardUses,
		"holdoutNemesisKills": holdoutNemesisKills,
		"holdoutModifierUses": holdoutModifierUses,
		"holdoutAccoladeCounts": holdoutAccoladeCounts
	}

func save_game():
	SaveManager.save_main_state(get_save_dict())
