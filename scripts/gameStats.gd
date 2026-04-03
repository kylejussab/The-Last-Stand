extends Node

enum Mode { SPLASH_SCREEN, MAIN_MENU, MODIFIER_SELECTION, CARD_DRAW, JUNE_RAVEL, HOLDOUT, HOLDOUT_ROUND_COMPLETED }

var invitationAccepted: bool = false
var gameMode: Mode = Mode.MAIN_MENU

var totalInGameTimePlayed: float = 0.0

var rations: int = 0


# Holdout stats
var accoladeCounts: Dictionary = {
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
