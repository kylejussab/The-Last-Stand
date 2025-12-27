extends Node2D

@onready var playerName = $player/name
@onready var playerHealth = $player/value
@onready var playerHead = $player/head

@onready var opponentName = $opponent/name
@onready var opponentHealth = $opponent/value
@onready var opponentHead = $opponent/head

@onready var endTurnButton = $"../EndTurnButton"

@onready var battleManager = %battleManager

var ARENAHEADS_DATABASE = {
	"June": {
		"name": "June Ravel",
		"description": "Former Firefly",
		"health": "35",
		"headPath": "res://assets/arenaHeads/"
	},
	"Ethan": {
		"name": "Ethan Hark",
		"description": "Patrol Leader",
		"health": "1",
		"headPath": "res://assets/arenaHeads/",
		"arenaPath": "res://assets/arenas/"
	},
	"Silas": {
		"name": "Silas Vane",
		"description": "Scavenger King",
		"health": "1", # 50 is too high, possibly for a final boss, but not a character in this mode
		"headPath": "res://assets/arenaHeads/",
		"arenaPath": "res://assets/arenas/"
	},
	"Mira": {
		"name": "Mira Thorne",
		"description": "Ex-Medic",
		"health": "1", #25
		"headPath": "res://assets/arenaHeads/",
		"arenaPath": "res://assets/arenas/"
	},
	"Kael": {
		"name": "Kaelen Voss",
		"description": "Shield Brother",
		"health": "1", #45
		"headPath": "res://assets/arenaHeads/",
		"arenaPath": "res://assets/arenas/"
	}}

func _ready() -> void:
	for button in $"../arena/gameOver".get_children():
		if button is Button:
			button.mouse_entered.connect(_play_hover_sound)
			button.pressed.connect(_play_click_sound)

func set_health(who: String, value: int):
	if not is_node_ready():
		await ready
		
	if who == "player":
		playerHealth.text = str(value)
		ARENAHEADS_DATABASE[GameStats.currentPlayer].health = str(value)
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
	get_node(side + "/name").text = ARENAHEADS_DATABASE[firstName].name
	get_node(side + "/description").text = ARENAHEADS_DATABASE[firstName].description
	get_node(side + "/value").text = ARENAHEADS_DATABASE[firstName].health
	
	var path = ARENAHEADS_DATABASE[firstName].headPath
	var head = $player/head if isPlayer else $opponent/head
	
	head.get_node("neutral").texture = load(path + firstName + "Neutral.png")
	head.get_node("hurt").texture = load(path + firstName + "Hurt.png")
	head.get_node("thinking").texture = load(path + firstName + "Thinking.png")
	head.get_node("happy").texture = load(path + firstName + "Happy.png")
	
	if !isPlayer:
		$image.texture = load(ARENAHEADS_DATABASE[firstName].arenaPath + firstName + "Arena.png")

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
	
	$"../arena/damageSound".play()
	
	damageLabel.text = "-" + str(amount)
	animationPlayer.queue("showDamage")
	
	return animationPlayer.animation_finished

func show_end_turn_button(visibility: bool = true):
	if endTurnButton:
		endTurnButton.visible = visibility
		endTurnButton.disabled = !visibility

func _on_replay_button_pressed() -> void:
	GameStats.replayedRound = true
	fade_with_round_reset()

func _on_continue_button_pressed() -> void:
	GameStats.currentOpponent = get_next_opponent()
	GameStats.playerHealthValue = int(playerHealth.text)
	GameStats.replayedRound = false
	GameStats.lastStandTotalScore += GameStats.lastStandCurrentRoundScore
	fade_with_round_reset()

func _on_main_menu_button_pressed() -> void:
	GameStats.gameMode = "Main Menu"
	Curtain.change_scene("res://scenes/mainMenu.tscn")

func fade_with_round_reset():
	await Curtain.fade_in()
	
	change_expression("player", "neutral")
	change_expression("opponent", "neutral")
	
	# Reset the round
	battleManager.lockPlayerInput = true
	battleManager.ui.show_end_turn_button(false)
	GameStats.reset_round_stats()
	$"../playerHand".playerHand = []
	$"../opponentHand".opponentHand = []
	
	$"../arena/gameOver/overlay".visible = false
	$"../arena/gameOver/title".visible = false
	$"../arena/gameOver/line".visible = false
	$"../arena/gameOver/performance".visible = false
	$"../arena/gameOver/game".visible = false
	$"../arena/gameOver/score".visible = false
	$"../arena/gameOver/ReplayButton".visible = false
	$"../arena/gameOver/ReplayButton".disabled = true
	$"../arena/gameOver/MainMenuButton".visible = false
	$"../arena/gameOver/MainMenuButton".disabled = true
	$"../arena/gameOver/ContinueButton".visible = false
	$"../arena/gameOver/ContinueButton".disabled = true
	
	set_health("player", GameStats.playerHealthValue)
	battleManager.setupArena(GameStats.currentPlayer, GameStats.currentOpponent)
	await get_tree().create_timer(1).timeout
	
	Curtain.fade_out()
	
	battleManager.resetArena()

func get_next_opponent() -> String:
	var list = ARENAHEADS_DATABASE.keys()
	list.erase(GameStats.currentPlayer)
	list.erase(GameStats.currentOpponent)
	
	return list.pick_random()

func _play_hover_sound():
	$"../arena/ButtonHoverSound".play()

func _play_click_sound():
	$"../arena/ButtonClickSound".play()
