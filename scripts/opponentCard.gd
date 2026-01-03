extends Node2D

var cardKey: String
var type
var handPosition: Vector2
var value: int
var role: String
var faction: String
var perk
var perkValueAtRoundEnd
var canBePlayed: bool

@onready var soundPlayer = $AudioStreamPlayer2D

@export var drawSounds = [
	preload("res://assets/sounds/cards/deal_1.wav"),
	preload("res://assets/sounds/cards/deal_2.wav"),
	preload("res://assets/sounds/cards/deal_3.wav"),
	preload("res://assets/sounds/cards/deal_4.wav"),
	preload("res://assets/sounds/cards/deal_5.wav"),
	preload("res://assets/sounds/cards/deal_6.wav"),
	preload("res://assets/sounds/cards/deal_7.wav")
]

func play_draw_sound():
	var randomSound = drawSounds.pick_random()
	soundPlayer.stream = randomSound
	soundPlayer.play()
