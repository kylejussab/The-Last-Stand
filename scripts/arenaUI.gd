extends Node2D

@onready var playerNameLabel: Label = $player/name
@onready var playerHealthLabel: Label = $player/value
@onready var playerHead: Node2D = $player/head

@onready var opponentNameLabel: Label = $opponent/name
@onready var opponentHealthLabel: Label = $opponent/value
@onready var opponentHead: Node2D = $opponent/head

@onready var battleManager: Node = %battleManager

func _ready() -> void:
	for button in %gameOver.get_children():
		if button is Button:
			button.mouse_entered.connect(func(): %ButtonHoverSound.play())
			button.pressed.connect(func(): %ButtonClickSound.play())

func update_health(who: Actor.Type, value: int, instant: bool = false) -> void:
	if not is_node_ready():
		await ready
		
	var label: Label = playerHealthLabel if who == Actor.Type.PLAYER else opponentHealthLabel
	var startValue: int = int(label.text)
	
	if who == Actor.Type.PLAYER:
		Database.AVATARS[GameStats.currentPlayer].health = value
	
	if Settings.reduceAnimations or instant:
		label.text = "%02d" % value
	else:
		var tween = create_tween()
		tween.tween_method(
			func(val: int): label.text = ("-" if val < 0 else "") + "%02d" % abs(val),
			startValue,
			value,
			1.0
		)

func get_health(who: Actor.Type) -> int:
	match who:
		Actor.Type.PLAYER:
			return int(playerHealthLabel.text)
		Actor.Type.OPPONENT:
			return int(opponentHealthLabel.text)
		_:
			return 0

func setup_avatar(avatar: Actor.Avatar, type: Actor.Type) -> void:
	var data = Database.AVATARS[avatar]
	
	var isPlayer: bool = true if type == Actor.Type.PLAYER else false
	var avatarParent: Node2D = get_node("player") if isPlayer else get_node("opponent")
	
	avatarParent.get_node("name").text = data.name
	avatarParent.get_node("description").text = data.description
	avatarParent.get_node("value").text = str(data.health)
	
	var basePath: String = "%s%s" % [data.headPath, data.name.get_slice(" ", 0)]
	
	var headNode: Node2D = avatarParent.get_node("head")
	headNode.get_node("neutral").texture = load(basePath + "Neutral.png")
	headNode.get_node("hurt").texture = load(basePath + "Hurt.png")
	headNode.get_node("thinking").texture = load(basePath + "Thinking.png")
	headNode.get_node("happy").texture = load(basePath + "Happy.png")
	
	if type == Actor.Type.OPPONENT:
		$image.texture = load("%s%sArena.png" % [data.arenaPath, data.name.get_slice(" ", 0)])

func change_mood(who: Actor.Type, mood: Actor.Mood) -> void:
	var headNode: Node2D = playerHead if who == Actor.Type.PLAYER else opponentHead
	var expressionNodeName: String = ""
	
	match mood:
		Actor.Mood.NEUTRAL: expressionNodeName = "neutral"
		Actor.Mood.THINKING: expressionNodeName = "thinking"
		Actor.Mood.HURT: expressionNodeName = "hurt"
		Actor.Mood.HAPPY: expressionNodeName = "happy"
	
	for child in headNode.get_children():
		if child.name in ["neutral", "thinking", "hurt", "happy"]:
			child.visible = (child.name == expressionNodeName)

func set_indicator(who: Actor.Type) -> void:
	$player/indicator.visible = false
	$opponent/indicator.visible = false
	
	match who:
		Actor.Type.NONE:
			return
		Actor.Type.PLAYER:
			$player/indicator.visible = true
		Actor.Type.OPPONENT:
			$opponent/indicator.visible = true

func play_damage_effect(who: Actor.Type, value: int) -> Signal:
	var animationPlayer: AnimationPlayer
	var damageLabel: Label
	
	match who:
		Actor.Type.PLAYER:
			animationPlayer = $player/AnimationPlayer
			damageLabel = $player/damage
		Actor.Type.OPPONENT:
			animationPlayer = $opponent/AnimationPlayer
			damageLabel = $opponent/damage
	
	%damageSound.play()
	
	damageLabel.text = "-" + str(value)
	animationPlayer.queue("showDamage")
	
	return animationPlayer.animation_finished

func show_end_turn_button(visibility: bool = true) -> void:
	%EndTurnButton.visible = visibility
	%EndTurnButton.disabled = !visibility

# Privates
func _on_replay_button_pressed() -> void:
	GameStats.replayedRound = true
	
	if GameStats.gameMode == GameStats.Mode.LAST_STAND_ROUND_COMPLETED:
		GameStats.gameMode = GameStats.Mode.LAST_STAND
		
	_fade_with_round_reset()

func _on_continue_button_pressed() -> void:
	GameStats.replayedRound = false
	GameStats.lastStandTotalScore += GameStats.lastStandCurrentRoundScore
	
	if GameStats.gameMode == GameStats.Mode.LAST_STAND_ROUND_COMPLETED:
		GameStats.playerHealthValue = int(playerHealthLabel.text)
		GameStats.gameMode = GameStats.Mode.LAST_STAND
	
	_fade_with_round_reset()

func _on_main_menu_button_pressed() -> void:
	GameStats.gameMode = GameStats.Mode.MAIN_MENU
	Curtain.change_scene("res://scenes/mainMenu.tscn")

# Helpers
func _fade_with_round_reset() -> void:
	await Curtain.fade_in()
	
	%pauseIcon/text.text = "PAUSE"
	change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)
	change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
	_reset_game_over_ui()
	_reset_board_state()
	
	update_health(Actor.Type.PLAYER, GameStats.playerHealthValue, true)
	
	await get_tree().create_timer(1).timeout
	Curtain.fade_out()
	
	battleManager.start_new_match()

func _reset_game_over_ui() -> void:
	%gameOver.visible = false
	
	for child in %gameOver.get_children():
		child.visible = false
		if child is Button:
			child.disabled = true

func _reset_board_state() -> void:
	battleManager.lockPlayerInput = true
	show_end_turn_button(false)
	GameStats.reset_round_stats()
	%playerHand.playerHand.clear()
	%opponentHand.opponentHand.clear()
	
	# Clean up older scene children
	for card in %cardManager.get_children():
		card.queue_free()
