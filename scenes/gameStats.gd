extends Node

var invitationAccepted: bool = false
var gameMode: String = "Main Menu"

var playerHealthValue: int

# Per round stats
var currentPlayer: String
var currentOpponent: String

var roundNumber: int = 1
var totalForceExerted: int = 0
var opponentForceExerted: int = 0
var highestDamageDealt: int = 0
var roundWinsUnderdog: int = 0
var allPlayedCards: Array = []

var startTime: float = 0.0
var endTime: float = 0.0

var lastStandTotalScore: int = 0
var lastStandCurrentRoundScore: int = 0
var replayedRound: bool = false

func set_start_time():
	startTime = Time.get_ticks_msec()

func set_end_time():
	endTime = Time.get_ticks_msec()

func reset_round_stats():
	roundNumber = 1
	totalForceExerted = 0
	opponentForceExerted = 0
	highestDamageDealt = 0
	roundWinsUnderdog = 0
	allPlayedCards = []

func record_played_card(faction: String, cardKey: String):
	allPlayedCards.append({"faction": faction, "cardKey": cardKey})
