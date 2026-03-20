extends Control

var isViewDeckActive: bool = false

const CARD_SCENE_PATH = "res://scenes/card.tscn"
const CARD_SCALE = Vector2(0.8, 0.8)
const CARD_GRID_SPACE = Vector2(140, 180) 

const HEADER_FONT_PATH = "res://assets/fonts/SF-Pro-Display-Black.otf"
const SUBHEADER_FONT_PATH = "res://assets/fonts/SF-Pro-Display-Semibold.otf"

@onready var contentContainer = $viewPanel/ScrollContainer/VBoxContainer
@onready var cardDatabase = preload("res://scripts/database.gd")

@onready var soundPlayer = $AudioStreamPlayer2D

var drawSounds = [
	preload("res://assets/sounds/cards/deal_1.wav"),
	preload("res://assets/sounds/cards/deal_2.wav"),
	preload("res://assets/sounds/cards/deal_3.wav"),
	preload("res://assets/sounds/cards/deal_4.wav"),
	preload("res://assets/sounds/cards/deal_5.wav"),
	preload("res://assets/sounds/cards/deal_6.wav"),
	preload("res://assets/sounds/cards/deal_7.wav")
]

var activeDeckReference: Node2D = null

var stickyHeader: Control = null 

func _ready() -> void:
	hide()
	$overlay.modulate.a = 0.0
	$viewPanel/ScrollContainer.modulate.a = 0.0
	$viewPanel/background.modulate.a = 1.0
	$viewPanel/background.scale.x = 0.0
	
	$viewPanel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	$viewPanel/background.mouse_filter = Control.MOUSE_FILTER_STOP
	
	contentContainer.mouse_filter = Control.MOUSE_FILTER_PASS

func open_deck_view(deckCaller = null):
	_play_draw_sound()
	
	activeDeckReference = deckCaller
	
	if stickyHeader:
		stickyHeader.queue_free()
		stickyHeader = null
	
	for child in contentContainer.get_children():
		child.queue_free()
	
	var style = $viewPanel/background.get_theme_stylebox("panel").duplicate()
	
	if deckCaller: 
		var deckData = []
		if deckCaller.name == "characterDeck":
			style.bg_color = Color(0.0, 0.0, 0.0, 1.0)
			$viewPanel/background.add_theme_stylebox_override("panel", style)
			
			if %battleManager.infectedDeckActive:
				deckData = cardDatabase.infectedHeavyCharacterDeck.duplicate()
			elif %battleManager.humanityRestoredActive:
				deckData = cardDatabase.humanityRestoredCharacterDeck.duplicate()
			else:
				deckData = cardDatabase.standardCharacterDeck.duplicate()
			_populate_character_deck(deckData)
		
		elif deckCaller.name == "supportDeck":
			style.bg_color = Color(0.07, 0.07, 0.07, 1.0)
			$viewPanel/background.add_theme_stylebox_override("panel", style)
			
			if %battleManager.infectedDeckActive:
				deckData = cardDatabase.infectedHeavySupportDeck.duplicate()
			else:
				deckData = cardDatabase.standardSupportDeck.duplicate()
			_populate_support_deck(deckData)
	
	show()
	$overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	%pause.currentNavigation = "View Deck"
	$"../pauseIcon/text".text = "BACK"
	
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property($viewPanel/background, "scale:x", 1.0, 0.5)
	
	tween.parallel().tween_property($viewPanel/ScrollContainer, "modulate:a", 1.0, 0.4).set_delay(0.1).set_trans(Tween.TRANS_LINEAR)
	tween.parallel().tween_property($overlay, "modulate:a", 0.6, 0.4).set_trans(Tween.TRANS_LINEAR)
	
	stickyHeader.modulate.a = 0.0
	tween.parallel().tween_property(stickyHeader, "modulate:a", 1.0, 0.4).set_delay(0.1).set_trans(Tween.TRANS_LINEAR)
	
	isViewDeckActive = true

func close_deck_view():
	_play_draw_sound()
	%pause.currentNavigation = "Main"
	$"../pauseIcon/text".text = "PAUSE"
	
	var tween = create_tween()
	tween.tween_property($viewPanel/background, "scale:x", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property($viewPanel/ScrollContainer, "modulate:a", 0.0, 0.1).set_trans(Tween.TRANS_LINEAR)
	tween.parallel().tween_property($overlay, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_LINEAR)
	
	tween.parallel().tween_property(stickyHeader, "modulate:a", 0.0, 0.1).set_trans(Tween.TRANS_LINEAR)
	
	tween.finished.connect(hide)
	await tween.finished
	
	if activeDeckReference:
		if activeDeckReference.has_method("force_reset_visuals"):
			activeDeckReference.force_reset_visuals()
	
	activeDeckReference = null
	isViewDeckActive = false
	$overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _populate_character_deck(deckArray: Array):
	_add_deck_header("Character Deck", deckArray.size())
	
	var groups = {}
	for cardKey in deckArray:
		var data = cardDatabase.CHARACTERS[cardKey]
		var faction = data[2] 
		if not groups.has(faction): groups[faction] = []
		groups[faction].append(cardKey)
	
	var finalSortedList = []
	var sortedFactions = groups.keys()
	sortedFactions.sort()
	
	for faction in sortedFactions:
		groups[faction].sort()
		finalSortedList.append_array(groups[faction])
	
	var grid = _create_new_grid()
	
	for key in finalSortedList:
		_add_visual_card(key, grid, true)

func _populate_support_deck(deckArray: Array):
	_add_deck_header("Support Deck", deckArray.size())
	
	var grid = _create_new_grid()
	for key in deckArray:
		_add_visual_card(key, grid, false)

func _add_visual_card(key, grid, isCharacter):
	var wrapper = Control.new()
	wrapper.custom_minimum_size = CARD_GRID_SPACE
	wrapper.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var card = load(CARD_SCENE_PATH).instantiate()
	card.cardKey = key
	
	if isCharacter and cardDatabase.CHARACTERS.has(key):
		var data = cardDatabase.CHARACTERS[key]
		card.value = data[0]
		card.type = data[1]
		card.faction = data[2]
		card.role = data[3]
		card.nameText = data[4]
		if data.size() > 5: card.perkDescription = data[5]
	
	elif not isCharacter and cardDatabase.SUPPORTS.has(key):
		var data = cardDatabase.SUPPORTS[key]
		card.value = data[0]
		card.type = data[1]
		card.role = data[2]
		card.nameText = data[4]
		if data.size() > 5: card.perkDescription = data[5]
		card.faction = "Support" 
	
	card.process_mode = Node.PROCESS_MODE_DISABLED
	card.scale = CARD_SCALE
	card.position = wrapper.custom_minimum_size / 2
	
	if card.has_node("Area2D"): card.get_node("Area2D").queue_free()
	if card.has_method("update_visuals"): card.update_visuals()
	
	if card is Control: card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	wrapper.add_child(card)
	grid.add_child(wrapper)

func _create_new_grid() -> HFlowContainer:
	var flow = HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 15)
	flow.add_theme_constant_override("v_separation", 25)
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var marginWrapper = MarginContainer.new()
	marginWrapper.add_theme_constant_override("margin_left", 20)
	marginWrapper.add_theme_constant_override("margin_right", 20)
	marginWrapper.add_theme_constant_override("margin_bottom", 20)
	marginWrapper.add_theme_constant_override("margin_top", -10)
	marginWrapper.mouse_filter = Control.MOUSE_FILTER_PASS
	
	marginWrapper.add_child(flow)
	contentContainer.add_child(marginWrapper)
	return flow

func _input(event: InputEvent) -> void:
	if not visible: return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			get_viewport().set_input_as_handled()
			close_deck_view()
		elif event.button_index == MOUSE_BUTTON_LEFT and not $viewPanel/background.get_global_rect().has_point(event.position):
			get_viewport().set_input_as_handled()
			close_deck_view()

func _add_deck_header(titleText: String, count: int):
	var headerPanel = PanelContainer.new()
	headerPanel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var currentStyle = $viewPanel/background.get_theme_stylebox("panel")
	if currentStyle:
		var headerStyle = currentStyle.duplicate()
		headerPanel.add_theme_stylebox_override("panel", headerStyle)
	
	headerPanel.anchor_left = 0.0
	headerPanel.anchor_right = 1.0
	headerPanel.offset_left = 0.0
	headerPanel.offset_right = 0.0
	
	var headerMargin = MarginContainer.new()
	headerMargin.add_theme_constant_override("margin_left", 30)
	headerMargin.add_theme_constant_override("margin_top", 20)
	headerMargin.add_theme_constant_override("margin_right", 30)
	headerMargin.add_theme_constant_override("margin_bottom", 20)
	headerMargin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", -5)
	
	var headerRow = HBoxContainer.new()
	headerRow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var baseFont = load(HEADER_FONT_PATH)
	var fontVariation = FontVariation.new()
	fontVariation.base_font = baseFont
	fontVariation.spacing_glyph = 1
	
	var heading = Label.new()
	heading.text = titleText
	heading.add_theme_font_size_override("font_size", 22)
	heading.add_theme_font_override("font", fontVariation)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var countLabel = Label.new()
	countLabel.text = str(count)
	countLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	countLabel.add_theme_font_size_override("font_size", 32)
	countLabel.add_theme_font_override("font", fontVariation)
	countLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	headerRow.add_child(heading)
	headerRow.add_child(spacer)
	headerRow.add_child(countLabel)
	
	var subHeader = Label.new()
	subHeader.text = "Note: This is the full deck list, not the current draw pile"
	subHeader.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	subHeader.add_theme_font_size_override("font_size", 12)
	subHeader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var secondFont = load(SUBHEADER_FONT_PATH)
	var fontVariationSecond = FontVariation.new()
	fontVariationSecond.base_font = secondFont
	subHeader.add_theme_font_override("font", fontVariationSecond)
	
	vbox.add_child(headerRow)
	vbox.add_child(subHeader)
	headerMargin.add_child(vbox)
	
	headerPanel.add_child(headerMargin)
	
	$viewPanel.add_child(headerPanel)
	
	headerPanel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	
	stickyHeader = headerPanel
	
	var scrollSpacer = Control.new()
	scrollSpacer.custom_minimum_size.y = 90
	scrollSpacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contentContainer.add_child(scrollSpacer)

func _play_draw_sound():
	var randomSound = drawSounds.pick_random()
	soundPlayer.stream = randomSound
	soundPlayer.play()
