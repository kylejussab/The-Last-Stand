extends Node

# Per round stats
var roundNumber: int = 1
var totalForceExerted: int = 0
var opponentForceExerted: int = 0
var highestDamageDealt: int = 0
var roundWinsUnderdog: int = 0
var allPlayedCards: Array = []

var startTime: float = 0.0
var endTime: float = 0.0

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
