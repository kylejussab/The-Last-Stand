extends Control

@onready var layers: Array = [
	$UI,
	$"Clicker 1", $"Clicker 2", $"Clicker 3", $"Clicker 4", $"Clicker 5", $"Clicker 6", $"Clicker 7",
	$"Background 1", $"Background 2", $"Background 3", $"Background 4", $"Background 5",
]

@onready var characterHitbox: Control = $CharacterHitbox
@onready var backgroundHitbox: Control = $BackgroundHitbox

var defaultYPositions: Array = [205, 355, 380, 405, 430, 455, 480, 505, 655, 680, 680, 705, 730]
var characterExplodedYPositions: Array = [30, 180, 300, 420, 540, 660, 780, 900, 1050, 1060, 1060, 1070, 1080]
var backgroundExplodedYPositions: Array = [5, 30, 40, 50, 60, 70, 80, 90, 480, 580, 580, 680, 780]

var activeTween: Tween
var currentState: String = "default"

const MICRO_NEAR := 80.0
const MICRO_FAR := 35.0
const MICRO_SPEED := 10.0

func _ready() -> void:
	$Darkener.modulate.a = 0.5
	set_process(false)

func _on_character_hitbox_mouse_entered() -> void:
	_tween_to_state("character")

func _on_character_hitbox_mouse_exited() -> void:
	_tween_to_state("default")

func _on_background_hitbox_mouse_entered() -> void:
	_tween_to_state("background")

func _on_background_hitbox_mouse_exited() -> void:
	_tween_to_state("default")

func _tween_to_state(state: String) -> void:
	currentState = state
	
	if activeTween and activeTween.is_running():
		activeTween.kill()
	
	match state:
		"default":
			set_process(false)
			activeTween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			activeTween.tween_property($Darkener, "modulate:a", 0.5, 0.25)
			for i in range(layers.size()):
				activeTween.tween_property(layers[i], "position:y", defaultYPositions[i], 0.25)
		
		"character", "background":
			set_process(true)
			activeTween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			activeTween.tween_property($Darkener, "modulate:a", 0.1, 0.75)

func _micro_push(distance: float) -> float:
	if distance >= 3.0:
		return 0.0
	elif distance >= 2.0:
		return lerpf(MICRO_FAR, 0.0, distance - 2.0)
	elif distance >= 1.0:
		return lerpf(MICRO_NEAR, MICRO_FAR, distance - 1.0)
	else:
		return lerpf(0.0, MICRO_NEAR, distance)

func _process(deltaTime: float) -> void:
	var mouseGlobalY := get_global_mouse_position().y
	var explodedPositions: Array
	var activeHitbox: Control
	var indexMinimum: int
	var indexMaximum: int
	var focusMinimum: float
	var focusMaximum: float
	
	match currentState:
		"character":
			explodedPositions = characterExplodedYPositions
			activeHitbox = characterHitbox
			indexMinimum = 1
			indexMaximum = 7
			focusMinimum = 1.0
			focusMaximum = 7.0
		"background":
			explodedPositions = backgroundExplodedYPositions
			activeHitbox = backgroundHitbox
			indexMinimum = 8
			indexMaximum = 12
			focusMinimum = 8.0
			focusMaximum = 12.0
		_:
			return
	
	var verticalRatio = clamp((mouseGlobalY - activeHitbox.global_position.y) / activeHitbox.size.y, 0.0, 1.0)
	var dynamicFocus := lerpf(focusMinimum, focusMaximum, verticalRatio)
	
	for i in range(layers.size()):
		var targetPositionY := float(explodedPositions[i])
		if i >= indexMinimum and i <= indexMaximum:
			var signedDistance := float(i) - dynamicFocus
			targetPositionY += sign(signedDistance) * _micro_push(abs(signedDistance))
		layers[i].position.y = lerpf(layers[i].position.y, targetPositionY, MICRO_SPEED * deltaTime)
