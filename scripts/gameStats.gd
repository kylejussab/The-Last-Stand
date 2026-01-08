extends Node

enum Mode { MAIN_MENU, CARD_DRAW, JUNE_RAVEL, LAST_STAND, LAST_STAND_ROUND_COMPLETED }

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
var activeMultipliers: Array = []

var currentRoundDuration: float = 0.0 
var canCountDuration: bool = false

var lastStandTotalScore: int = 0
var lastStandCurrentRoundScore: int = 0
var replayedRound: bool = false

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
	allPlayedCards = []

func record_played_card(faction: String, cardKey: String):
	allPlayedCards.append({"faction": faction, "cardKey": cardKey})
