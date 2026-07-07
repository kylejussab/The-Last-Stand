extends Control
class_name OptionsMenu

signal options_exited
signal card_accessibility_closed

@onready var mainContainer = $container/mainContainer
@onready var displayMenuContainer = $container/displayMenuContainer
@onready var audioMenuContainer = $container/audioMenuContainer
@onready var accessibilityMenuContainer = $container/accessibilityMenuContainer
@onready var accessibilitySubMainContainer = $container/accessibilityMenuContainer/mainContainer
@onready var accessibilityCardsContainer = $container/accessibilityMenuContainer/cardsContainer

@onready var deleteDataButton = mainContainer.get_node("DeleteDataButton")

var currentNavigation: String = "Options"
var previewCard: Node2D = null

func _ready() -> void:
	setup_button_sounds.call_deferred(mainContainer)
	
	# Display options are not for web builds
	if OS.has_feature("web"):
		$container/mainContainer/DisplayLock.show()
	else:
		$container/mainContainer/DisplayLock.hide()
	
	if accessibilitySubMainContainer:
		setup_button_sounds.call_deferred(accessibilitySubMainContainer)
	
	hide_all()

func open(showDeleteButton: bool = true):
	show()
	currentNavigation = "Options"
	mainContainer.show()
	mainContainer.process_mode = Node.PROCESS_MODE_INHERIT
	
	var saveExists = SaveManager.has_main_save()
	var shouldShow = showDeleteButton and saveExists
	
	deleteDataButton.visible = shouldShow

func hide_all():
	hide()
	mainContainer.hide()
	mainContainer.process_mode = Node.PROCESS_MODE_DISABLED
	accessibilityMenuContainer.hide()
	accessibilityMenuContainer.process_mode = Node.PROCESS_MODE_DISABLED

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		get_viewport().set_input_as_handled()
		
		if currentNavigation == "Options":
			AudioManager.play_button_back()
			hide_all()
			AccessibilityData.save_to_file()
			SettingsData.save_to_file()
			options_exited.emit()
			
		elif currentNavigation == "Display":
			AudioManager.play_button_back()
			currentNavigation = "Options"
			displayMenuContainer.hide()
			displayMenuContainer.process_mode = Node.PROCESS_MODE_DISABLED
			
			mainContainer.show()
			mainContainer.process_mode = Node.PROCESS_MODE_INHERIT
			
		elif currentNavigation == "Audio":
			AudioManager.play_button_back()
			currentNavigation = "Options"
			audioMenuContainer.hide()
			audioMenuContainer.process_mode = Node.PROCESS_MODE_DISABLED
			
			mainContainer.show()
			mainContainer.process_mode = Node.PROCESS_MODE_INHERIT
			
		elif currentNavigation == "Accessibility":
			AudioManager.play_button_back()
			currentNavigation = "Options"
			accessibilityMenuContainer.hide()
			accessibilityMenuContainer.process_mode = Node.PROCESS_MODE_DISABLED
			
			mainContainer.show()
			mainContainer.process_mode = Node.PROCESS_MODE_INHERIT
			
		elif currentNavigation == "Accessibility/Cards":
			AudioManager.play_button_back()
			currentNavigation = "Accessibility"
			
			accessibilityMenuContainer.get_node("Heading").text = "OPTIONS   >   ACCESSIBILITY"
			accessibilityCardsContainer.hide()
			accessibilityCardsContainer.process_mode = Node.PROCESS_MODE_DISABLED
			
			accessibilitySubMainContainer.show()
			accessibilitySubMainContainer.process_mode = Node.PROCESS_MODE_INHERIT
			
			_clear_preview_card()
			
			card_accessibility_closed.emit() 

func setup_button_sounds(container: Node):
	for child in container.get_children():
		if child is Button:
			if not child.mouse_entered.is_connected(AudioManager.play_button_hover):
				child.mouse_entered.connect(AudioManager.play_button_hover)
				
			if not child.pressed.is_connected(AudioManager.play_button_click):
				child.pressed.connect(AudioManager.play_button_click)
				
			child.focus_mode = Control.FOCUS_NONE

# --- SIGNALS ---
func _on_display_button_pressed() -> void:
	if OS.has_feature("web"):
		_play_denied_animation($container/mainContainer/DisplayButton)
	else:
		currentNavigation = "Display"
		
		mainContainer.hide()
		mainContainer.process_mode = Node.PROCESS_MODE_DISABLED
		
		displayMenuContainer.show()
		displayMenuContainer.process_mode = Node.PROCESS_MODE_INHERIT

func _on_audio_button_pressed() -> void:
	currentNavigation = "Audio"
	
	mainContainer.hide()
	mainContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	audioMenuContainer.show()
	audioMenuContainer.process_mode = Node.PROCESS_MODE_INHERIT

func _on_accessibility_button_pressed() -> void:
	currentNavigation = "Accessibility"
	
	mainContainer.hide()
	mainContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	accessibilityMenuContainer.show()
	accessibilityMenuContainer.process_mode = Node.PROCESS_MODE_INHERIT

func _on_cards_button_pressed() -> void:
	currentNavigation = "Accessibility/Cards"
	accessibilityMenuContainer.get_node("Heading").text = "OPTIONS   >   ACCESSIBILITY   >   CARDS"
	
	accessibilitySubMainContainer.hide()
	accessibilitySubMainContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	accessibilityCardsContainer.show()
	accessibilityCardsContainer.process_mode = Node.PROCESS_MODE_INHERIT
	
	update_preview_card()

func _on_subtitles_button_pressed() -> void:
	_play_denied_animation(accessibilitySubMainContainer.get_node("SubtitlesButton"))

func _on_delete_data_button_mouse_entered() -> void:
	$holdIcon.visible = true

func _on_delete_data_button_mouse_exited() -> void:
	$holdIcon.visible = false

func _on_delete_data_button_hold_complete() -> void:
	AudioManager.play_button_click()
	
	SaveManager.clear_main_save()
	SaveManager.clear_holdout_save()
	
	GameStats.reset_all_data()
	
	deleteDataButton.visible = false

# --- PREVIEW CARD LOGIC ---
func update_preview_card():
	if previewCard != null:
		previewCard.queue_free()
	
	var card_scene = load("res://core/cards/card.tscn")
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
	previewCard.get_node("imageBack").texture = load("res://core/cards/art/CardBackBlank.png")
	
	previewCard.get_node("icons/faction").texture = load("res://core/cards/icons/Infected.png")
	
	accessibilityCardsContainer.add_child(previewCard)
	
	var adapter = Control.new()
	adapter.name = "UI_Input_Adapter"
	previewCard.add_child(adapter)
	
	var cardSize = load("res://core/cards/art/CardBackBlank.png").get_size() * 0.2
	adapter.size = cardSize
	adapter.position = -(cardSize / 2)
	
	adapter.mouse_entered.connect(_on_preview_hover_entered.bind(previewCard))
	adapter.mouse_exited.connect(_on_preview_hover_exited.bind(previewCard))
	previewCard.update_visuals()

func _clear_preview_card():
	if previewCard != null:
		previewCard.queue_free()
		previewCard = null

func _on_preview_hover_entered(card_node):
	AudioManager.play_card_hover()
	
	if !AccessibilityData.animationsDisabled:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(card_node, "scale", Vector2(2.35, 2.35), 0.1)
	
	if card_node.has_node("AnimationPlayer"):
		if card_node.get_node("AnimationPlayer").has_animation("showPerkDescription"):
			card_node.get_node("AnimationPlayer").play("showPerkDescription")
			
			if AccessibilityData.animationsDisabled:
				var endTime = card_node.get_node("AnimationPlayer").current_animation_length
				card_node.get_node("AnimationPlayer").seek(endTime, true)
			
	card_node.z_index = 10

func _on_preview_hover_exited(card_node):
	AudioManager.play_card_hover()
	
	if !AccessibilityData.animationsDisabled:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(card_node, "scale", Vector2(2, 2), 0.1)
	
	if card_node.has_node("AnimationPlayer"):
		if card_node.get_node("AnimationPlayer").has_animation("showPerkDescription"):
			card_node.get_node("AnimationPlayer").play_backwards("showPerkDescription")
			
			if AccessibilityData.animationsDisabled:
				card_node.get_node("AnimationPlayer").seek(0, true)
			
	card_node.z_index = 0

func _play_denied_animation(currentButton: Button):
	var originalPos = currentButton.position.x
	var shake_offset = 5.0
	var duration = 0.05
	
	var tween = create_tween()
	tween.tween_property(currentButton, "position:x", originalPos + shake_offset, duration)
	tween.tween_property(currentButton, "position:x", originalPos - shake_offset, duration)
	tween.tween_property(currentButton, "position:x", originalPos, duration)
