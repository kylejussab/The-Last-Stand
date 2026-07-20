extends Node2D

@onready var playerNameLabel: Label = $player/name
@onready var playerHealthLabel: Label = $player/value
@onready var playerHead: Node2D = $player/head

@onready var opponentNameLabel: Label = $opponent/name
@onready var opponentHealthLabel: Label = $opponent/value
@onready var opponentHead: Node2D = $opponent/head

func update_health(who: Actor.Type, value: int, instant: bool = false) -> void:
	if not is_node_ready():
		await ready
		
	var label: Label = playerHealthLabel if who == Actor.Type.PLAYER else opponentHealthLabel
	var startValue: int = int(label.text)
	
	if who == Actor.Type.PLAYER:
		Database.AVATARS[HoldoutStats.currentPlayer].health = value
		HoldoutStats.playerHealthValue = value
	
	if AccessibilityData.animationsDisabled or instant:
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
	if not is_node_ready():
		await ready
		
	var data = Database.AVATARS[avatar]
	
	var isPlayer: bool = true if type == Actor.Type.PLAYER else false
	var avatarParent: Node2D = get_node("player") if isPlayer else get_node("opponent")
	
	avatarParent.get_node("name").text = data.name
	
	if type == Actor.Type.OPPONENT: # Add playstyle to the opponents description
		avatarParent.get_node("description").text = data.description + "  |  " + data.playstyle
	else:
		avatarParent.get_node("description").text = data.description
	
	var basePath: String = "%s%s" % [data.headPath, data.name.get_slice(" ", 0)]
	
	var headNode: Node2D = avatarParent.get_node("head")
	headNode.get_node("neutral").texture = Database.get_avatar_head_texture(basePath + "Neutral.png")
	headNode.get_node("hurt").texture = Database.get_avatar_head_texture(basePath + "Hurt.png")
	headNode.get_node("thinking").texture = Database.get_avatar_head_texture(basePath + "Thinking.png")
	headNode.get_node("happy").texture = Database.get_avatar_head_texture(basePath + "Happy.png")
	
	if type == Actor.Type.OPPONENT:
		$background/static/image.texture = Database.get_avatar_head_texture("%s%s.png" % [data.backgroundPath, data.name.get_slice(" ", 0)])

func change_mood(who: Actor.Type, mood: Actor.Mood) -> void:
	if not is_node_ready():
		await ready
		
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
	if not is_node_ready():
		await ready
		
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
	
	AudioManager.play_take_damage()
	
	damageLabel.text = "-" + str(value)
	animationPlayer.queue("showDamage")
	
	return animationPlayer.animation_finished

func show_end_turn_button(visibility: bool = true) -> void:
	%EndTurnButton.visible = visibility
	%EndTurnButton.disabled = !visibility
