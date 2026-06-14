extends Control

@onready var characterPhaseIcon: TextureRect = %characterPhaseIcon
@onready var supportPhaseIcon: TextureRect = %supportPhaseIcon
@onready var resolutionPhaseIcon: TextureRect = %resolutionPhaseIcon

@onready var characterPhaseText: Control = %characterPhaseText
@onready var supportPhaseText: Control = %supportPhaseText
@onready var resolutionPhaseText: Control = %resolutionPhaseText

@onready var battleManager: Node = %battleManager

var activeTexture = preload("res://assets/ui/currentPhaseIcon.png") 
var inactiveTexture = preload("res://assets/ui/otherPhaseIcon.png")

var tweenDuration: float = 0.5
var defaultOffset: float = 180.0

var characterPhaseIconPosition: Vector2
var supportPhaseIconPosition: Vector2
var resolutionPhaseIconPosition: Vector2

var hoverTween: Tween

func _ready() -> void:
	characterPhaseIconPosition = characterPhaseIcon.position
	supportPhaseIconPosition = supportPhaseIcon.position
	resolutionPhaseIconPosition = resolutionPhaseIcon.position
	
	characterPhaseText.modulate.a = 0.0
	supportPhaseText.modulate.a = 0.0
	resolutionPhaseText.modulate.a = 0.0
	
	characterPhaseIcon.mouse_filter = Control.MOUSE_FILTER_PASS
	supportPhaseIcon.mouse_filter = Control.MOUSE_FILTER_PASS
	resolutionPhaseIcon.mouse_filter = Control.MOUSE_FILTER_PASS
	
	characterPhaseIcon.mouse_entered.connect(_on_character_entered)
	supportPhaseIcon.mouse_entered.connect(_on_support_entered)
	resolutionPhaseIcon.mouse_entered.connect(_on_resolution_entered)
	
	mouse_exited.connect(_on_parent_mouse_exited)
	
	battleManager.battleEngine.phase_changed.connect(_on_phase_changed)
	_on_phase_changed(battleManager.battleEngine.roundStage)

func _on_phase_changed(newPhase: int) -> void:
	characterPhaseIcon.texture = inactiveTexture
	supportPhaseIcon.texture = inactiveTexture
	resolutionPhaseIcon.texture = inactiveTexture
	
	match newPhase:
		battleManager.battleEngine.RoundStage.PLAYER_CHARACTER, battleManager.battleEngine.RoundStage.OPPONENT_CHARACTER:
			characterPhaseIcon.texture = activeTexture
		battleManager.battleEngine.RoundStage.PLAYER_SUPPORT, battleManager.battleEngine.RoundStage.OPPONENT_SUPPORT:
			supportPhaseIcon.texture = activeTexture
		battleManager.battleEngine.RoundStage.END_CALCULATION:
			resolutionPhaseIcon.texture = activeTexture

func _on_character_entered() -> void:
	_play_hover_tween(
		characterPhaseIconPosition.x - defaultOffset,
		supportPhaseIconPosition.x + (defaultOffset * 0.25),
		resolutionPhaseIconPosition.x + (defaultOffset * 0.125),
		1.0, 0.0, 0.0
	)

func _on_support_entered() -> void:
	_play_hover_tween(
		characterPhaseIconPosition.x - defaultOffset,
		supportPhaseIconPosition.x, 
		resolutionPhaseIconPosition.x + defaultOffset,
		0.0, 1.0, 0.0
	)

func _on_resolution_entered() -> void:
	_play_hover_tween(
		characterPhaseIconPosition.x - (defaultOffset * 0.125),
		supportPhaseIconPosition.x - (defaultOffset * 0.25),
		resolutionPhaseIconPosition.x + defaultOffset,
		0.0, 0.0, 1.0
	)

func _play_hover_tween(leftTargetX: float, centerTargetX: float, rightTargetX: float, leftAlpha: float, centerAlpha: float, rightAlpha: float) -> void:
	if hoverTween and hoverTween.is_valid():
		hoverTween.kill()
	
	hoverTween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	hoverTween.tween_property(characterPhaseIcon, "position:x", leftTargetX, tweenDuration)
	hoverTween.tween_property(supportPhaseIcon, "position:x", centerTargetX, tweenDuration)
	hoverTween.tween_property(resolutionPhaseIcon, "position:x", rightTargetX, tweenDuration)
	
	hoverTween.tween_property(characterPhaseText, "modulate:a", leftAlpha, tweenDuration)
	hoverTween.tween_property(supportPhaseText, "modulate:a", centerAlpha, tweenDuration)
	hoverTween.tween_property(resolutionPhaseText, "modulate:a", rightAlpha, tweenDuration)

func _on_parent_mouse_exited() -> void:
	if hoverTween and hoverTween.is_valid():
		hoverTween.kill()
	
	hoverTween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	hoverTween.tween_property(characterPhaseIcon, "position:x", characterPhaseIconPosition.x, tweenDuration)
	hoverTween.tween_property(supportPhaseIcon, "position:x", supportPhaseIconPosition.x, tweenDuration)
	hoverTween.tween_property(resolutionPhaseIcon, "position:x", resolutionPhaseIconPosition.x, tweenDuration)
	
	hoverTween.tween_property(characterPhaseText, "modulate:a", 0.0, tweenDuration)
	hoverTween.tween_property(supportPhaseText, "modulate:a", 0.0, tweenDuration)
	hoverTween.tween_property(resolutionPhaseText, "modulate:a", 0.0, tweenDuration)
