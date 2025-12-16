extends Node2D

signal hoverEntered(card)
signal hoverExited(card)

var cardSlot
var cardKey: String
var type
var value: int
var role: String
var faction: String
var perk
var perkValueAtRoundEnd
var canBePlayed: bool

var handPosition: Vector2

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

func _ready() -> void:
	get_parent().connect_card_signals(self)

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hoverEntered", self)

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hoverExited", self)

func play_draw_sound():
	var randomSound = drawSounds.pick_random()
	soundPlayer.stream = randomSound
	soundPlayer.play()
