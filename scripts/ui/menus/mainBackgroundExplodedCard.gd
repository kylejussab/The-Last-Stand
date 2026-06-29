extends Control

@onready var explodedCards = {
	"Firefly": {
		"Sprites": [$"Firefly/Marlene 1", $"Firefly/Marlene 2", $"Firefly/Marlene 3", $"Firefly/Marlene 4", $"Firefly/Marlene 5", $"Firefly/Background 1", $"Firefly/Background 2", $"Firefly/Background 3", $"Firefly/Background 4", $"Firefly/Background 5"],
		"DefaultPositions": [380, 405, 430, 455, 480, 630, 655, 680, 705, 730],
		"CharacterExplodedPositions": [300, 420, 540, 660, 780, 930, 940, 960, 970, 980],
		"BackgroundExplodedPositions": [150, 160, 170, 180, 190, 380, 480, 580, 680, 780]
	},
	"Infected": {
		"Sprites": [$"Infected/Clicker 1", $"Infected/Clicker 2", $"Infected/Clicker 3", $"Infected/Clicker 4", $"Infected/Clicker 5", $"Infected/Clicker 6", $"Infected/Clicker 7", $"Infected/Background 1", $"Infected/Background 2", $"Infected/Background 3", $"Infected/Background 4", $"Infected/Background 5"],
		"DefaultPositions": [355, 380, 405, 430, 455, 480, 505, 655, 680, 680, 705, 730],
		"CharacterExplodedPositions": [180, 300, 420, 540, 660, 780, 900, 1050, 1060, 1060, 1070, 1080],
		"BackgroundExplodedPositions": [30, 40, 50, 60, 70, 80, 90, 480, 580, 580, 680, 780]
	},
	"Jackson": {
		"Sprites": [$"Jackson/Tommy 1", $"Jackson/Tommy 2", $"Jackson/Tommy 3", $"Jackson/Tommy 4", $"Jackson/Tommy 5", $"Jackson/Background 1", $"Jackson/Background 2", $"Jackson/Background 3", $"Jackson/Background 4", $"Jackson/Background 5"],
		"DefaultPositions": [380, 405, 430, 455, 480, 630, 655, 680, 705, 730],
		"CharacterExplodedPositions": [300, 420, 540, 660, 780, 930, 940, 960, 970, 980],
		"BackgroundExplodedPositions": [150, 160, 170, 180, 190, 380, 480, 580, 680, 780]
	},
	"Seraphite": {
		"Sprites": [$"Seraphite/Foreground 1", $"Seraphite/Yara 1", $"Seraphite/Yara 2", $"Seraphite/Yara 3", $"Seraphite/Yara 4", $"Seraphite/Yara 5", $"Seraphite/Background 1", $"Seraphite/Background 2", $"Seraphite/Background 3", $"Seraphite/Background 4", $"Seraphite/Background 5"],
		"DefaultPositions": [230, 380, 405, 430, 455, 480, 630, 655, 680, 705, 730],
		"CharacterExplodedPositions": [50, 300, 420, 540, 660, 780, 930, 940, 960, 970, 980],
		"BackgroundExplodedPositions": [140, 150, 160, 170, 180, 190, 380, 480, 580, 680, 780]
	},
	"WLF": {
		"Sprites": [$"WLF/Abby 1", $"WLF/Abby 2", $"WLF/Abby 3", $"WLF/Abby 4", $"WLF/Abby 5", $"WLF/Background 1", $"WLF/Background 2", $"WLF/Background 3", $"WLF/Background 4", $"WLF/Background 5"],
		"DefaultPositions": [380, 405, 430, 455, 480, 630, 655, 680, 705, 730],
		"CharacterExplodedPositions": [300, 420, 540, 660, 780, 930, 940, 960, 970, 980],
		"BackgroundExplodedPositions": [150, 160, 170, 180, 190, 380, 480, 580, 680, 780]
	},
}

@onready var characterHitbox: Control = $CharacterHitbox
@onready var backgroundHitbox: Control = $BackgroundHitbox

var selectedFaction: String

var activeTween: Tween
var currentState: String = "default"

const MICRO_NEAR := 80.0
const MICRO_FAR := 35.0
const MICRO_SPEED := 10.0

func _ready() -> void:
	var factions = explodedCards.keys() 
	selectedFaction = factions.pick_random()
	
	for factionName in factions:
		var factionNode = get_node_or_null(factionName)
		if factionNode:
			factionNode.hide()
			
	var selectedNode = get_node_or_null(selectedFaction)
	if selectedNode:
		selectedNode.show()
	
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
			for i in range(explodedCards[selectedFaction]["Sprites"].size()):
				activeTween.tween_property(explodedCards[selectedFaction]["Sprites"][i], "position:y", explodedCards[selectedFaction]["DefaultPositions"][i], 0.25)
		
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
			explodedPositions = explodedCards[selectedFaction]["CharacterExplodedPositions"]
			activeHitbox = characterHitbox
			indexMinimum = 1
			indexMaximum = 7
			focusMinimum = 1.0
			focusMaximum = 7.0
		"background":
			explodedPositions = explodedCards[selectedFaction]["BackgroundExplodedPositions"]
			activeHitbox = backgroundHitbox
			indexMinimum = 8
			indexMaximum = 12
			focusMinimum = 8.0
			focusMaximum = 12.0
		_:
			return
	
	var verticalRatio = clamp((mouseGlobalY - activeHitbox.global_position.y) / activeHitbox.size.y, 0.0, 1.0)
	var dynamicFocus := lerpf(focusMinimum, focusMaximum, verticalRatio)
	
	for i in range(explodedCards[selectedFaction]["Sprites"].size()):
		var targetPositionY := float(explodedPositions[i])
		if i >= indexMinimum and i <= indexMaximum:
			var signedDistance := float(i) - dynamicFocus
			targetPositionY += sign(signedDistance) * _micro_push(abs(signedDistance))
		explodedCards[selectedFaction]["Sprites"][i].position.y = lerpf(explodedCards[selectedFaction]["Sprites"][i].position.y, targetPositionY, MICRO_SPEED * deltaTime)
