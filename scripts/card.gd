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

func disable_interaction() -> void:
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
	
	scale = Vector2(1, 1)
	
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("hideDescription")
		var end_time = $AnimationPlayer.current_animation_length
		$AnimationPlayer.seek(end_time, true)

func modify_value(amount: int) -> void:
	value += amount
	
	if not get_node("AnimationPlayer").animation_started.is_connected(_when_animation_starts):
		get_node("AnimationPlayer").animation_started.connect(_when_animation_starts)
	
	var stringSign = "+" if amount >= 0 else "" 
	
	get_node("perk").text = stringSign + str(amount)
	get_node("AnimationPlayer").queue("showPerk")

func _when_animation_starts(animationName: String):
	if animationName == "showPerk":
		_updateCardValue()

func _updateCardValue():
	var label = get_node("value")
	var startValue = int(label.text)
	
	var tween = create_tween()
	
	tween.tween_method(
		func(val: int): label.text = str(val),
		startValue,
		value,
		0.5
	)
