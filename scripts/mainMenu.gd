extends Node2D

@onready var backgroundImage = $image
@onready var mainButtonContainer = $mainButtonContainer
@onready var storyButtonContainer = $storyButtonContainer
@onready var lastStandButtonContainer = $lastStandButtonContainer
@onready var optionsButtonContainer = $optionsButtonContainer
@onready var accessibilityMenuContainer = $accessibilityMenuContainer
@onready var accessibilityMainContainer = $accessibilityMenuContainer/mainContainer
@onready var accessibilityCardsContainer = $accessibilityMenuContainer/cardsContainer

@onready var supplementText = $supplementText

var currentNavigation: String = "Main"

const BACKGROUNDS = {
	"Main": preload("res://assets/mainMenu/main.png"),
	"June": preload("res://assets/mainMenu/june.png"),
}

const SUPPLEMENTTEXT = {
	"Story": "Play through a choice of three different survivor stories.",
	"Last Stand": "Survive as many waves as possible with boosted health and no healing.",
	"June": "What is the cost of doing what you believe is right?"
}

# Card for Accessibility Card Graphics
var previewCard: Node2D = null

func _ready() -> void:
	setup_button_sounds(mainButtonContainer)
	setup_button_sounds(storyButtonContainer)
	setup_button_sounds(lastStandButtonContainer)
	setup_button_sounds(optionsButtonContainer)
	setup_button_sounds(accessibilityMenuContainer.get_node("mainContainer"))
	
	if GameStats.invitationAccepted:
		$pressAnywhere.hide()
		mainButtonContainer.show()
		mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		$pressAnywhere.show()
		mainButtonContainer.hide()
		mainButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
		pulse_text()

func pulse_text():
	var pulse = create_tween().set_loops()
	
	pulse.tween_property($pressAnywhere/text, "modulate:a", 0.3, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property($pressAnywhere/text, "modulate:a", 1.0, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _input(event: InputEvent) -> void:
	if !GameStats.invitationAccepted and (event is InputEventMouseButton and event.pressed):
		GameStats.invitationAccepted = true
		_play_click()
		
		mainButtonContainer.modulate.a = 0.0
		mainButtonContainer.show()
		
		var outTween = create_tween()
		outTween.tween_property($pressAnywhere, "modulate:a", 0.0, 0.3)
		await outTween.finished
		$pressAnywhere.hide()
		
		var inTween = create_tween()
		inTween.tween_property(mainButtonContainer, "modulate:a", 1.0, 0.3)
		await inTween.finished
		
		mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and currentNavigation != "Main":
		_play_back()
		
		if currentNavigation == "Story":
			$pauseIcon.hide()
			currentNavigation = "Main"
			storyButtonContainer.hide()
			storyButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
			
			backgroundImage.texture = BACKGROUNDS["Main"]
			
			mainButtonContainer.show()
			mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
		elif currentNavigation == "Last Stand":
			$pauseIcon.hide()
			currentNavigation = "Main"
			lastStandButtonContainer.hide()
			lastStandButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
			
			backgroundImage.texture = BACKGROUNDS["Main"]
			
			mainButtonContainer.show()
			mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
		elif currentNavigation == "Options":
			$pauseIcon.hide()
			currentNavigation = "Main"
			optionsButtonContainer.hide()
			optionsButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
			
			backgroundImage.texture = BACKGROUNDS["Main"]
			
			mainButtonContainer.show()
			mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
		elif currentNavigation == "Accessibility":
			currentNavigation = "Options"
			accessibilityMenuContainer.hide()
			accessibilityMenuContainer.process_mode = Node.PROCESS_MODE_DISABLED
			
			optionsButtonContainer.show()
			optionsButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
		elif currentNavigation == "Accessibility/Cards":
			currentNavigation = "Accessibility"
			
			accessibilityMenuContainer.get_node("Heading").text = "OPTIONS   >   ACCESSIBILITY"
			
			accessibilityCardsContainer.hide()
			accessibilityCardsContainer.process_mode = Node.PROCESS_MODE_DISABLED
			
			accessibilityMainContainer.show()
			accessibilityMainContainer.process_mode = Node.PROCESS_MODE_INHERIT
			_clear_preview_card()

func setup_button_sounds(container: Node):
	for child in container.get_children():
		if child is Button:
			child.mouse_entered.connect(_play_hover)
			child.pressed.connect(_play_click)
			
			child.focus_mode = Control.FOCUS_NONE

func _on_story_button_mouse_entered() -> void:
	supplementText.text = SUPPLEMENTTEXT["Story"]

func _on_story_button_mouse_exited() -> void:
	supplementText.text = ""

func _on_story_button_pressed() -> void:
	$pauseIcon.show()
	currentNavigation = "Story"
	
	mainButtonContainer.hide()
	mainButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	storyButtonContainer.show()
	storyButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT

func _on_june_button_mouse_entered() -> void:
	backgroundImage.texture = BACKGROUNDS["June"]
	supplementText.text = SUPPLEMENTTEXT["June"]

func _on_june_button_mouse_exited() -> void:
	backgroundImage.texture = BACKGROUNDS["Main"]
	supplementText.text = ""

func _on_june_button_pressed() -> void:
	#GameStats.gameMode = GameStats.Mode.JUNE_RAVEL
	#Curtain.change_scene("res://scenes/main.tscn")
	pass

func _on_last_stand_button_mouse_entered() -> void:
	supplementText.text = SUPPLEMENTTEXT["Last Stand"]

func _on_last_stand_button_mouse_exited() -> void:
	supplementText.text = ""

func _on_last_stand_button_pressed() -> void:
	$pauseIcon.show()
	currentNavigation = "Last Stand"
	
	mainButtonContainer.hide()
	mainButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	lastStandButtonContainer.show()
	lastStandButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT

func _on_new_button_hold_complete() -> void:
	GameStats.gameMode = GameStats.Mode.LAST_STAND
	GameStats.reset_all_data()
	
	GameStats.start_new_run_log()
	
	Curtain.change_scene("res://scenes/main.tscn")

func _on_options_button_pressed() -> void:
	$pauseIcon.show()
	currentNavigation = "Options"
	
	backgroundImage.texture = null
	
	mainButtonContainer.hide()
	mainButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	optionsButtonContainer.show()
	optionsButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT

func _on_accessibility_button_pressed() -> void:
	currentNavigation = "Accessibility"
	
	optionsButtonContainer.hide()
	optionsButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	accessibilityMenuContainer.show()
	accessibilityMenuContainer.process_mode = Node.PROCESS_MODE_INHERIT

func _on_cards_button_pressed() -> void:
	currentNavigation = "Accessibility/Cards"
	
	accessibilityMenuContainer.get_node("Heading").text = "OPTIONS   >   ACCESSIBILITY   >   CARDS"
	
	accessibilityMainContainer.hide()
	accessibilityMainContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	accessibilityCardsContainer.show()
	accessibilityCardsContainer.process_mode = Node.PROCESS_MODE_INHERIT
	
	update_preview_card()

func _on_quit_button_pressed() -> void:
	if OS.has_feature("web"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		get_tree().quit()

# Privates
func update_preview_card():
	if previewCard != null:
		previewCard.queue_free()
	
	var card_scene = load("res://scenes/card.tscn")
	previewCard = card_scene.instantiate()
	
	previewCard.scale = Vector2(2, 2)
	previewCard.position = Vector2(1450, 540)
	
	previewCard.cardKey = "Clicker"
	previewCard.value = 5
	previewCard.type = "Character"
	previewCard.faction = "Infected"
	previewCard.role = "Aggressive"
	previewCard.nameText = "CLICKER"
	previewCard.perkDescription = "-2 to opponent health on round win"
	
	previewCard.get_node("value").text = str(previewCard.value)
	previewCard.get_node("name").text = previewCard.nameText
	previewCard.get_node("imageBack").texture = load("res://assets/cards/CardBackBlank.png")
	
	previewCard.get_node("icons/faction").texture = load("res://assets/cardIcons/Infected.png")
	
	accessibilityCardsContainer.add_child(previewCard)
	
	var adapter = Control.new()
	adapter.name = "UI_Input_Adapter"
	previewCard.add_child(adapter)
	
	var size = load("res://assets/cards/CardBackBlank.png").get_size() * 0.2
	adapter.size = size
	adapter.position = -(size / 2)
	
	adapter.mouse_entered.connect(_on_preview_hover_entered.bind(previewCard))
	adapter.mouse_exited.connect(_on_preview_hover_exited.bind(previewCard))
	previewCard.update_visuals()

func _clear_preview_card():
	if previewCard != null:
		previewCard.queue_free()
		previewCard = null

func _on_preview_hover_entered(card_node):
	%CardHoverSound.play()
	
	if !AccessibilityData.animationsDisabled:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(card_node, "scale", Vector2(2.35, 2.35), 0.1)
	
	if card_node.has_node("AnimationPlayer"):
		if card_node.get_node("AnimationPlayer").has_animation("showDescription"):
			card_node.get_node("AnimationPlayer").play("showDescription")
			
			if AccessibilityData.animationsDisabled:
				var endTime = card_node.get_node("AnimationPlayer").current_animation_length
				card_node.get_node("AnimationPlayer").seek(endTime, true)
			
	card_node.z_index = 10

func _on_preview_hover_exited(card_node):
	%CardHoverSound.play()
	
	if !AccessibilityData.animationsDisabled:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(card_node, "scale", Vector2(2, 2), 0.1)
	
	if card_node.has_node("AnimationPlayer"):
		if card_node.get_node("AnimationPlayer").has_animation("hideDescription"):
			card_node.get_node("AnimationPlayer").play("hideDescription")
			
			if AccessibilityData.animationsDisabled:
				var endTime = card_node.get_node("AnimationPlayer").current_animation_length
				card_node.get_node("AnimationPlayer").seek(endTime, true)
			
	card_node.z_index = 0

# Helpers
func _play_hover():
	$ButtonHoverSound.play()

func _play_click():
	$ButtonClickSound.play()

func _play_back():
	$ButtonBackSound.play()
