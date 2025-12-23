extends Node2D

@onready var playerName = $player/name
@onready var playerHealth = $player/value
@onready var playerHead = $player/head

@onready var opponentName = $opponent/name
@onready var opponentHealth = $opponent/value
@onready var opponentHead = $opponent/head

@onready var endTurnButton = $"../EndTurnButton"

const CHARACTER_DATABASE = {
	"June": {
		"name": "June Ravel",
		"description": "Former Firefly",
		"health": "10",
		"headPath": "res://assets/arenaHeads/"
	},
	"Ethan": {
		"name": "Ethan Hark",
		"description": "Patrol Leader",
		"health": "10",
		"headPath": "res://assets/arenaHeads/",
		"arenaPath": "res://assets/arenas/"
	}}

func set_health(who: String, value: int):
	if who == "player":
		playerHealth.text = str(value)
	elif who == "opponent":
		opponentHealth.text = str(value)

func get_health(who: String) -> int:
	if who == "player":
		return int(playerHealth.text)
	elif who == "opponent":
		return int(opponentHealth.text)
	else:
		return 0

func setup_character(firstName: String, isPlayer: bool):
	var side = "player" if isPlayer else "opponent"
	get_node(side + "/name").text = CHARACTER_DATABASE[firstName].name
	get_node(side + "/description").text = CHARACTER_DATABASE[firstName].description
	get_node(side + "/value").text = CHARACTER_DATABASE[firstName].health
	
	var path = CHARACTER_DATABASE[firstName].headPath
	var head = $player/head if isPlayer else $opponent/head
	
	head.get_node("neutral").texture = load(path + firstName + "Neutral.png")
	head.get_node("hurt").texture = load(path + firstName + "Hurt.png")
	head.get_node("thinking").texture = load(path + firstName + "Thinking.png")
	head.get_node("happy").texture = load(path + firstName + "Happy.png")
	
	if !isPlayer:
		$image.texture = load(CHARACTER_DATABASE[firstName].arenaPath + firstName + "Arena.png")

func change_expression(who: String, expression: String):
	var states = ["neutral", "thinking", "hurt", "happy"]

	if who == "player":
		for state in states:
			playerHead.get_node(state).visible = (state == expression)
	elif who == "opponent":
		for state in states:
			opponentHead.get_node(state).visible = (state == expression)

func set_indicator(who: String):
	$player/indicator.visible = false
	$opponent/indicator.visible = false
	
	if who == "none":
		return
	
	if who == "player":
		$player/indicator.visible = true
	elif who == "opponent":
		$opponent/indicator.visible = true

func show_damage(who: String, amount: int):
	var animationPlayer
	var damageLabel
	
	if who == "player":
		animationPlayer = $player/AnimationPlayer
		damageLabel = $player/damage
	elif who == "opponent":
		animationPlayer = $opponent/AnimationPlayer
		damageLabel = $opponent/damage
	
	damageLabel.text = "-" + str(amount)
	animationPlayer.queue("showDamage")
	
	return animationPlayer.animation_finished

func show_end_turn_button(visibility: bool = true):
	if endTurnButton:
		endTurnButton.visible = visibility
		endTurnButton.disabled = !visibility
