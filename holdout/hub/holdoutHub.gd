extends Control

# For Opponent UI Component
@onready var opponentBox: Panel = $OpponentBox
@onready var opponentLine: ColorRect = $OpponentBox/Line
@onready var opponentAvatar: Sprite2D = $OpponentBox/OpponentHead
@onready var opponentNameLabel: RichTextLabel = $OpponentBox/OpponentName
@onready var opponentPlayStyleLabel: RichTextLabel = $OpponentBox/OpponentPlayStyle
@onready var opponentModifierNameLabel: RichTextLabel = $OpponentBox/ModifierName
@onready var opponentModifierDescriptionLabel: RichTextLabel = $OpponentBox/ModifierDescription
@onready var opponentModifierSlot: Control = $OpponentBox/Modifier

var selectedOpponentModifier: Dictionary
var cardHeadingFont = preload("res://core/fonts/Black.tres")
var cardBodyFont = preload("res://core/fonts/Semibold.tres")

# For Modifier UI Component
@onready var modifierContainer: Control = $ModifierContainer
@onready var modifierSlotOne: Panel = $"ModifierContainer/Modifier 1"
@onready var modifierSlotTwo: Panel = $"ModifierContainer/Modifier 2"
@onready var modifierSlotThree: Panel = $"ModifierContainer/Modifier 3"

# For Allegiance UI Component
@onready var allegianceContainer: Control = $AllegianceContainer
@onready var allegianceSlotOne: Panel = $"AllegianceContainer/Allegiance 1"
@onready var allegianceSlotTwo: Panel = $"AllegianceContainer/Allegiance 2"
@onready var allegianceSlotThree: Panel = $"AllegianceContainer/Allegiance 3"

var tierOneModifier
var tierTwoModifier
var tierThreeModifier

var modifierSlotsActive: Array

var modifierSelected: bool = false

var allegianceOptionOne: Dictionary
var allegianceOptionTwo: Dictionary
var allegianceOptionThree: Dictionary

var allegianceSlotsActive: Array
var selectedAllegianceIndex: int = -1
var allowAllegianceSelections: bool = false

const ALLEGIANCE_FACTIONS = ["Firefly", "Infected", "Jackson", "Seraphite", "WLF"]

@onready var fungusSlotOne: Control = $"AllegianceContainer/Fungus A1"
@onready var fungusSlotTwo: Control = $"AllegianceContainer/Fungus A2"
@onready var fungusSlotThree: Control = $"AllegianceContainer/Fungus A3"
var fungusFadeTween: Tween

const FACTION_FUNGUS_COLORS = {
	"Firefly": ["C2A23E", "9D7F2E", "4F4119"],
	"Infected": ["CD6429", "96371F", "6F2214"],
	"Jackson": ["546E32", "3D4F23", "29331B"],
	"Seraphite": ["8657A3", "724099", "4B2B74"],
	"WLF": ["81B0DE", "4A89C8", "185799"],
}

# For Card Removal UI Component
@onready var removalContainer: Control = $RemovalContainer
@onready var removalSlotOne: Panel = $"RemovalContainer/Removal 1"
@onready var removalSlotTwo: Panel = $"RemovalContainer/Removal 2"
@onready var removalSlotThree: Panel = $"RemovalContainer/Removal 3"

var removalOptionOne: Dictionary
var removalOptionTwo: Dictionary
var removalOptionThree: Dictionary

var removalCardVisuals: Array = []

const REROLL_HEALTH_COST: int = 4
const REROLL_MIN_HEALTH: int = 4

var removalDisplayedHealth: int = 0

const CARD_DECK_FLOOR: int = 12 # The maximum supports that can be in hand by both player and opponent
const MAX_REMOVALS_PER_ROUND: int = 3
const REMOVAL_OFFER_THRESHOLD: int = CARD_DECK_FLOOR + MAX_REMOVALS_PER_ROUND

const REMOVAL_VIEW_CARD_SCENE_PATH = "res://core/cards/card.tscn"
const REMOVAL_VIEW_CARD_SCALE = Vector2(0.8, 0.8)
const REMOVAL_VIEW_CARD_GRID_SPACE = Vector2(140, 180)
@onready var removalDeckViewGrid: Control = %DeckViewGrid
var isShowingRemovalDeck: bool = false
var isAnimatingRemovalDeck: bool = false

var removalSlotsActive: Array
var selectedRemovalIndex: int = -1
var allowRemovalSelections: bool = false
var isRerollingRemoval: bool = false

const FACTION_REMOVAL_ICONS = {
	"Firefly": "res://holdout/removal/Firefly.png",
	"Infected": "res://holdout/removal/Infected.png",
	"Jackson": "res://holdout/removal/Jackson.png",
	"Seraphite": "res://holdout/removal/Seraphite.png",
	"WLF": "res://holdout/removal/WLF.png",
	"Support": "res://holdout/removal/Support.png",
}

# Flags
var isModifierRound: bool = false
var isCardRemovalRound: bool = false
var isAllegianceRound: bool = false

signal hub_data_ready

enum DataState { NOT_STARTED, PREPARING, READY }
var dataState: DataState = DataState.NOT_STARTED

# Hub
func _prepare_hub_data() -> void:
	if dataState != DataState.NOT_STARTED:
		return
	dataState = DataState.PREPARING
	
	_reset_internal_data()
	_setup_round_flags()
	
	$Overlay.modulate.a = 1
	$Heading.modulate.a = 0
	$Subheading.modulate.a = 0
	$NumberSelected.modulate.a = 0
	$NumberSelected.text = "0/3 Selected"
	$NumberSelected.position = Vector2(1590, 780)
	$ConfirmButton.text = "START BATTLE"
	$ConfirmButton.hide()
	$ConfirmButton.modulate.a = 0
	
	_setup_opponent_container()
	_setup_modifier_container()
	_setup_allegiance_container()
	await _setup_removal_container()
	
	modifierContainer.hide()
	allegianceContainer.hide()
	
	if isAllegianceRound:
		%currentAllegiance.modulate.a = 0
	else:
		%currentAllegiance.modulate.a = 1
	
	dataState = DataState.READY
	hub_data_ready.emit()


func _ensure_hub_data_ready() -> void:
	if dataState == DataState.READY:
		return
	if dataState == DataState.NOT_STARTED:
		_prepare_hub_data() # nobody preloaded it, kick it off now
	if dataState != DataState.READY:
		await hub_data_ready


func _setup_hub() -> void:
	await _ensure_hub_data_ready()
	dataState = DataState.NOT_STARTED # so the next round preps fresh data
	self.show()


func _setup_round_flags() -> void:
	if (HoldoutStats.numberOfWins + 1) % 2 == 0: # Even round
		isModifierRound = true
	
	isAllegianceRound = _is_allegiance_round(HoldoutStats.numberOfWins + 1)
	isCardRemovalRound = _is_card_removal_round(HoldoutStats.numberOfWins + 1)

func _is_allegiance_round(roundNumber: int) -> bool:
	if roundNumber == 1:
		return true
	
	if (roundNumber + 6) % 5 == 0:
		@warning_ignore("integer_division")
		return int((roundNumber + 6) / 5) >= 2
	
	return false


func _is_card_removal_round(roundNumber: int) -> bool:
	if roundNumber < 3:
		return false
		
	if roundNumber % 2 == 0:
		return false
	
	if _is_allegiance_round(roundNumber):
		return false
	
	# Only if the decks arent at a game breaking position
	var characterDeckCount = _get_remaining_deck_count(Database.standardCharacterDeck)
	
	if characterDeckCount <= REMOVAL_OFFER_THRESHOLD:
		return false
	
	return true


func show_hub() -> void:
	if HoldoutStats.replayedRound:
		GameStats.gameMode = GameStats.Mode.HOLDOUT
		%battleManager.initialize_game()
		return
	
	await _setup_hub()
	
	# Temporary delay at start
	if HoldoutStats.numberOfWins == 0:
		await get_tree().create_timer(0.2).timeout
	else:
		await get_tree().create_timer(0.5).timeout
	
	await _animate_opponent_container_one()
	
	await get_tree().create_timer(1).timeout
	
	# Check if this is a modifier round
	if isModifierRound:
		await _animate_opponent_container_two()
		
		await get_tree().create_timer(0.5).timeout
		
		await _animate_modifier_container_one()
		
		await get_tree().create_timer(1).timeout
		
		_animate_opponent_container_three()
		
		await _animate_modifier_container_two()
		
		$Heading.text = "PICK A MODIFIER"
		$Subheading.text = "Choose at least one. Multiple selections allowed."
		var headingTween = create_tween()
		headingTween.tween_property($Heading, "modulate:a", 1, 1)
		headingTween.parallel().tween_property($Subheading, "modulate:a", 1, 1)
		headingTween.parallel().tween_property($NumberSelected, "modulate:a", 1, 1)
		
		$ConfirmButton.text = "CONFIRM"
	elif isAllegianceRound:
		await _animate_opponent_container_two()
		
		await get_tree().create_timer(0.5).timeout
		
		await _animate_allegiance_container_one()
		
		await get_tree().create_timer(1).timeout
		
		_animate_opponent_container_three(HoldoutStats.numberOfWins == 0) # Change to false when testing
		
		_animate_allegiance_container_two()
		
		await get_tree().create_timer(0.75).timeout
		
		$Heading.text = "PICK AN ALLEGIANCE"
		$Subheading.text = "You must select only one."
		$NumberSelected.text = "0/1 Selected"
		var headingTween = create_tween()
		headingTween.tween_property($Heading, "modulate:a", 1, 1)
		headingTween.parallel().tween_property($Subheading, "modulate:a", 1, 1)
		headingTween.parallel().tween_property($NumberSelected, "modulate:a", 1, 1)
		
		$ConfirmButton.text = "CONFIRM"
	elif isCardRemovalRound:
		await _animate_opponent_container_two()
		
		await get_tree().create_timer(0.5).timeout
		
		await _animate_removal_container_one()
		
		await get_tree().create_timer(1).timeout
		
		_animate_opponent_container_three()
		
		await _animate_removal_container_two()
		
		_animate_removal_container_three()
		
		$Heading.text = "REMOVE A CARD?"
		$Subheading.text = "Select any number of cards."
		$NumberSelected.position = Vector2(1375, 750)
		$NumberSelected.text = "0/3 Selected"
		var headingTween = create_tween()
		headingTween.tween_property($Heading, "modulate:a", 1, 1)
		headingTween.parallel().tween_property($Subheading, "modulate:a", 1, 1)
		headingTween.parallel().tween_property($NumberSelected, "modulate:a", 1, 1)
		
		$ConfirmButton.text = "CONFIRM"
	
	# Show continue button
	$ConfirmButton.position = Vector2((get_viewport_rect().size.x - $ConfirmButton.size.x) / 2, 850)
	$ConfirmButton.show()
	var confirmButtonTween = create_tween()
	confirmButtonTween.tween_property($ConfirmButton, "modulate:a", 1, 1)
	
	# Use this fade whenever we reach an end of an animation, always at the end when the confirm button shows
	var endTween = create_tween()
	endTween.tween_property($Overlay, "modulate:a", 0.92, 1)

func hide_hub() -> void:
	_set_arena_data()
	$ConfirmButton.hide()
	
	if isShowingRemovalDeck:
		_hide_removal_deck(true)
	else:
		_hide_opponent_container()
	
	if isModifierRound:
		_hide_modifier_container()
	
	if isAllegianceRound:
		_hide_allegiance_container()
	
	if isCardRemovalRound:
		_hide_removal_buttons()
		_hide_removal_container()
	
	var hideTween = create_tween()
	hideTween.tween_property($Overlay, "modulate:a", 0, 1)
	hideTween.parallel().tween_property($Heading, "modulate:a", 0, 0.3)
	hideTween.parallel().tween_property($Subheading, "modulate:a", 0, 0.3)
	hideTween.parallel().tween_property($NumberSelected, "modulate:a", 0, 0.3)
	
	# Start the game
	GameStats.gameMode = GameStats.Mode.HOLDOUT
	%battleManager.initialize_game()
	
	await hideTween.finished

func _set_arena_data() -> void:
	# Opponent's modifier always goes in first
	%battleManager.add_modifier(selectedOpponentModifier.id, true)
	
	if isModifierRound:
		if modifierSlotsActive[0] == 1:
			%battleManager.add_modifier(tierOneModifier.id)
			GameStats.record_modifier_selection(tierOneModifier.name)
		if modifierSlotsActive[1] == 1:
			%battleManager.add_modifier(tierTwoModifier.id)
			GameStats.record_modifier_selection(tierTwoModifier.name)
		if modifierSlotsActive[2] == 1:
			%battleManager.add_modifier(tierThreeModifier.id)
			GameStats.record_modifier_selection(tierThreeModifier.name)
	
	if isAllegianceRound and selectedAllegianceIndex != -1:
		HoldoutStats.activeAllegiance = _get_selected_allegiance()
		_set_arena_allegiance_ui()

func _get_selected_allegiance() -> Dictionary:
	match selectedAllegianceIndex:
		0: return allegianceOptionOne
		1: return allegianceOptionTwo
		2: return allegianceOptionThree
		_: return {}

func _set_arena_allegiance_ui() -> void:
	$"../background/currentAllegiance/Name".text = HoldoutStats.activeAllegiance.name
	$"../background/currentAllegiance/Icon".texture = load(HoldoutStats.activeAllegiance.icon)
	$"../background/currentAllegiance/Description".text = HoldoutStats.activeAllegiance.description
	$"../background/currentAllegiance/Tier".text = HoldoutStats.activeAllegiance.faction + " Tier " + str(HoldoutStats.activeAllegiance.tier)
	
	var colors: Array = FACTION_FUNGUS_COLORS.get(HoldoutStats.activeAllegiance.faction, ["ffffff", "ffffff", "ffffff"])
	$"../background/currentAllegiance/2".modulate = Color(colors[1])
	$"../background/currentAllegiance/3".modulate = Color(colors[2])
	
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(%currentAllegiance, "modulate:a", 1.0, 0.3)
	
	await tween.finished

func _reset_internal_data() -> void:
	isModifierRound = false
	isCardRemovalRound = false
	isAllegianceRound = false
	modifierSlotsActive = [0, 0, 0]
	removalSlotsActive = [0, 0, 0]
	
	tierOneModifier = null
	tierTwoModifier = null
	tierThreeModifier = null

# Opponent 
func _setup_opponent_container() -> void:
	opponentModifierSlot.hide()
	opponentModifierSlot.scale = Vector2(1, 1)
	opponentModifierSlot.modulate.a = 1
	opponentModifierSlot.position = Vector2(300, 50)
	opponentModifierNameLabel.position = Vector2(375, 160)
	opponentModifierNameLabel.add_theme_font_override("normal_font", cardHeadingFont)
	opponentModifierDescriptionLabel.position = Vector2(430, 220)
	opponentModifierDescriptionLabel.size = Vector2(270, 100)
	opponentModifierNameLabel.modulate.a = 0
	opponentModifierDescriptionLabel.modulate.a = 0
	_select_opponent_modifier()
	
	opponentAvatar.position = Vector2(98, 96)
	_change_opponent_avatar_expression("Neutral")
	opponentNameLabel.text = Database.AVATARS[HoldoutStats.currentOpponent]["name"]
	opponentPlayStyleLabel.text = Database.AVATARS[HoldoutStats.currentOpponent]["playstyle"] + " PlayStyle"
	
	opponentNameLabel.position = Vector2(0, 215)
	opponentPlayStyleLabel.position = Vector2(0, 245)
	opponentPlayStyleLabel.add_theme_font_override("normal_font", cardBodyFont)
	opponentPlayStyleLabel.add_theme_color_override("default_color", Color("#4c4c4c"))
	
	opponentNameLabel.modulate.a = 0
	opponentPlayStyleLabel.modulate.a = 0
	
	opponentBox.size = Vector2(200, 200)
	
	var screenSize = get_viewport_rect().size
	var centerPosition = (screenSize - opponentBox.size) / 2
	
	opponentBox.global_position = Vector2(centerPosition.x, screenSize.y + 250)
	
	opponentLine.position = Vector2(225, 45)
	opponentLine.size = Vector2(1, 110)
	opponentLine.modulate = Color("#ffffff")
	opponentLine.modulate.a = 0
	
	# For selected allegiance
	$CurrentAllegiance.global_position = Vector2(150, screenSize.y + 250)
	
	if HoldoutStats.activeAllegiance:
		$CurrentAllegiance/Box/Icon.texture = load(HoldoutStats.activeAllegiance.icon)
		$CurrentAllegiance/Box/Name.text = HoldoutStats.activeAllegiance.name
		$CurrentAllegiance/Box/Tier.text = HoldoutStats.activeAllegiance.faction + " Tier " + str(HoldoutStats.activeAllegiance.tier)
		var colors: Array = FACTION_FUNGUS_COLORS.get(HoldoutStats.activeAllegiance.faction, ["ffffff", "ffffff", "ffffff"])
		$"CurrentAllegiance/2".modulate = Color(colors[1])
		$"CurrentAllegiance/3".modulate = Color(colors[2])

func _animate_opponent_container_one() -> void:
	if HoldoutStats.numberOfWins != 0:
		# Mute the sound if we have the opening animation playing
		AudioManager.play_move()
	
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(opponentBox, "global_position", Vector2(860, 440), 0.3)
	
	tween.tween_interval(0.3)
	
	tween.tween_callback(func(): 
		_change_opponent_avatar_expression("Thinking")
		AudioManager.play_pop()
	)
	
	tween.chain().set_trans(Tween.TRANS_BACK)
	tween.tween_property(opponentBox, "size:x", 450.0, 0.3)
	tween.parallel().tween_property(opponentBox, "global_position:x", 735, 0.3)
	tween.parallel().tween_property(opponentLine, "modulate:a", 1.0, 0.6)
	
	tween.chain().set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_interval(0.6)
	
	tween.tween_callback(func():
		opponentModifierSlot.show()
		opponentModifierSlot.spin_to_modifier(selectedOpponentModifier)
	)
	
	tween.tween_interval(2.2) # How long the spin takes
	
	tween.tween_interval(0.6) # Additional hold
	
	tween.chain().set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(func(): 
		AudioManager.play_pop()
	)
	
	tween.tween_property(opponentBox, "size", Vector2(750.0, 350.0), 0.3)
	tween.parallel().tween_property(opponentBox, "global_position", Vector2(585.0, 365.0), 0.3)
	
	tween.parallel().tween_property(opponentLine, "size:y", 250.0, 0.3)
	tween.parallel().tween_property(opponentLine, "position", Vector2(375.0, 50.0), 0.3)
	
	tween.parallel().tween_property(opponentAvatar, "position", Vector2(187.5, 129.0), 0.3)
	tween.parallel().tween_property(opponentModifierSlot, "position", Vector2(512.5, 50.0), 0.3)
	
	tween.tween_property(opponentNameLabel, "modulate:a", 1, 1)
	tween.parallel().tween_property(opponentPlayStyleLabel, "modulate:a", 1, 1)
	tween.parallel().tween_property(opponentModifierNameLabel, "modulate:a", 1, 1)
	tween.parallel().tween_property(opponentModifierDescriptionLabel, "modulate:a", 1, 1)
	
	tween.tween_callback(func():
		_change_opponent_avatar_expression("Happy")
	)
	
	var audioTween = create_tween()
	
	audioTween.tween_interval(1.5)
	audioTween.tween_callback(AudioManager.play_slot_spin)
	
	audioTween.tween_interval(1.85) 
	audioTween.tween_callback(AudioManager.play_slot_stop)
	
	await tween.finished

func _animate_opponent_container_two() -> void:
	AudioManager.play_move()
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(opponentBox, "global_position", Vector2(150, 365), 0.5)
	
	await tween.finished

func _animate_opponent_container_three(isFirstAllegiance: bool = false) -> void:
	opponentPlayStyleLabel.add_theme_font_override("normal_font", cardHeadingFont)
	opponentPlayStyleLabel.add_theme_color_override("default_color", Color("#ffffff"))
	
	AudioManager.play_pop()
	
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(opponentBox, "size", Vector2(430, 325), 0.3)
	
	if isFirstAllegiance:
		tween.parallel().tween_property(opponentBox, "global_position:y", 360, 0.3)
	else:
		tween.parallel().tween_property(opponentBox, "global_position:y", 315, 0.3)
	
	tween.parallel().tween_property(opponentAvatar, "position", Vector2(215, 80), 0.3)
	
	tween.parallel().tween_property(opponentNameLabel, "modulate:a", 0, 0.3)
	tween.parallel().tween_property(opponentPlayStyleLabel, "position", Vector2(27.5, 140), 0.3)
	
	tween.parallel().tween_property(opponentModifierSlot, "position", Vector2(20, 190), 0.3)
	tween.parallel().tween_property(opponentModifierSlot, "modulate:a", 0.25, 0.3)
	tween.parallel().tween_property(opponentModifierSlot, "scale", Vector2(0.6, 0.6), 0.3)
	
	tween.parallel().tween_property(opponentLine, "position", Vector2(130, 200), 0.3)
	tween.parallel().tween_property(opponentLine, "size:y", 85, 0.3)
	tween.parallel().tween_property(opponentLine, "modulate", Color("#4c4c4c"), 0.5)
	
	tween.parallel().tween_property(opponentModifierDescriptionLabel, "position", Vector2(150, 205), 0.3)
	tween.parallel().tween_property(opponentModifierDescriptionLabel, "size", Vector2(260, 110), 0.3)
	
	tween.parallel().tween_property(opponentModifierNameLabel, "modulate:a", 0, 0.3)
	
	if !isFirstAllegiance:
		AudioManager.play_move()
		tween.parallel().tween_property($CurrentAllegiance, "position", Vector2(150, 610), 0.3)
	
	await tween.finished

func _animate_opponent_container_four() -> void:
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(opponentBox, "global_position:y", 265, 0.3)
	tween.parallel().tween_property($CurrentAllegiance, "global_position:y", 560, 0.3)
	
	await tween.finished

func _select_opponent_modifier() -> void:
	var availableModifiers = []
	var activeModifierIds = []
	
	for active in HoldoutStats.activeModifiers:
		activeModifierIds.append(active["id"])
	
	for modifier in Database.MODIFIERS.values():
		var isEligibleTier = modifier["tier"] == 9 or (modifier["tier"] == 8 and HoldoutStats.numberOfWins >= 3)
		if isEligibleTier and not modifier["id"] in activeModifierIds:
			availableModifiers.append(modifier)
	
	selectedOpponentModifier = _pick_weighted_opponent_modifier(availableModifiers)
	
	HoldoutStats.lastOfferedOpponentModifierIds.append(selectedOpponentModifier.id)
	
	if HoldoutStats.lastOfferedOpponentModifierIds.size() >= 4:
		HoldoutStats.lastOfferedOpponentModifierIds.clear()
		HoldoutStats.lastOfferedOpponentModifierIds.append(selectedOpponentModifier.id)
	
	opponentModifierNameLabel.text = selectedOpponentModifier.name
	opponentModifierDescriptionLabel.text = selectedOpponentModifier.description
	
	opponentModifierSlot.setup_reel(availableModifiers)

func _pick_weighted_opponent_modifier(pool: Array) -> Dictionary:
	if pool.is_empty():
		return {}
	
	if randf() < 0.8:
		var freshPool = []
		for modifier in pool:
			if not modifier.id in HoldoutStats.lastOfferedOpponentModifierIds:
				freshPool.append(modifier)
		
		if not freshPool.is_empty():
			return freshPool.pick_random()
	
	return pool.pick_random()

func _change_opponent_avatar_expression(expression: String) -> void:
	$OpponentBox/OpponentHead.texture = load("res://core/ai/heads/" + Database.AVATARS[HoldoutStats.currentOpponent]["name"].get_slice(" ", 0) + expression + ".png")

func _hide_opponent_container() -> void:
	AudioManager.play_move()
	
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	if !isModifierRound and !isAllegianceRound and !isCardRemovalRound:
		tween.tween_property(opponentBox, "position:y", -750, 0.3)
	else:
		tween.tween_property(opponentBox, "position:x", -750, 0.3)
		tween.parallel().tween_property($CurrentAllegiance, "position:x", -750, 0.3)
	
	await tween.finished

# Modifier
func _setup_modifier_container() -> void:
	modifierSlotsActive = [0, 0, 0]
	modifierSelected = false
	
	var screenSize = get_viewport_rect().size
	
	var currentStyleBox = modifierSlotOne.get_theme_stylebox("panel").duplicate()
	currentStyleBox.bg_color = Color("151515")
	modifierSlotOne.add_theme_stylebox_override("panel", currentStyleBox)
	modifierSlotTwo.add_theme_stylebox_override("panel", currentStyleBox)
	modifierSlotThree.add_theme_stylebox_override("panel", currentStyleBox)
	
	modifierSlotOne.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modifierSlotTwo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modifierSlotThree.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	modifierSlotOne.position = Vector2(1020, screenSize.y + 250)
	modifierSlotTwo.position = Vector2(1300, screenSize.y + 250)
	modifierSlotThree.position = Vector2(1580, screenSize.y + 250)
	
	modifierSlotOne.size = Vector2(180, 180)
	modifierSlotTwo.size = Vector2(180, 180)
	modifierSlotThree.size = Vector2(180, 180)
	
	for slot in [modifierSlotOne, modifierSlotTwo, modifierSlotThree]:
		slot.get_node("Slot").hide()
		slot.get_node("Slot").scale = Vector2(1, 1)
		slot.get_node("Slot").position = Vector2(40, 40)
		slot.get_node("Name").modulate.a = 0
		slot.get_node("Description").modulate.a = 0
		slot.get_node("Multiplier").modulate.a = 0
		slot.get_node("Line").modulate.a = 0
		slot.get_node("Duration").modulate.a = 0
		slot.get_node("Multiplier").position = Vector2(85, 330)
		slot.get_node("Line").scale.y = 0
		slot.get_node("Duration").position = Vector2(85, 330)
		slot.get_node("Selected").hide()
	
	_select_modifiers()

func _animate_modifier_container_one() -> void:
	modifierContainer.show()
	
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(modifierSlotOne, "position", Vector2(1020, 450), 0.3)
	tween.tween_interval(0.3)
	
	tween.tween_callback(func(): 
		modifierSlotOne.get_node("Slot").show()
		modifierSlotOne.get_node("Slot").spin_to_modifier(tierOneModifier)
		)
	
	tween.tween_property(modifierSlotTwo, "position", Vector2(1300, 450), 0.3)
	tween.tween_interval(0.3)
	
	tween.tween_callback(func(): 
		modifierSlotTwo.get_node("Slot").show()
		modifierSlotTwo.get_node("Slot").spin_to_modifier(tierTwoModifier)
		)
	
	tween.tween_property(modifierSlotThree, "position", Vector2(1580, 450), 0.3)
	tween.tween_interval(0.3)
	
	tween.tween_callback(func(): 
		modifierSlotThree.get_node("Slot").show()
		modifierSlotThree.get_node("Slot").spin_to_modifier(tierThreeModifier)
		)
		
	tween.tween_interval(1.9) # This would be right after the last spin is done
	
	var whooshTween = create_tween()
	whooshTween.tween_interval(0.2)
	whooshTween.tween_callback(AudioManager.play_move)
	whooshTween.tween_interval(0.5)
	whooshTween.tween_callback(AudioManager.play_move)
	whooshTween.tween_interval(0.5)
	whooshTween.tween_callback(AudioManager.play_move)
	
	var audioTween = create_tween()
	
	audioTween.tween_interval(0.6)
	audioTween.tween_callback(AudioManager.play_slot_spin)
	
	audioTween.tween_interval(0.6)
	audioTween.tween_callback(AudioManager.play_slot_spin)
	
	audioTween.tween_interval(0.6)
	audioTween.tween_callback(AudioManager.play_slot_spin)
	
	audioTween.tween_interval(0.65) 
	audioTween.tween_callback(AudioManager.play_slot_stop)
	
	audioTween.tween_interval(0.65)
	audioTween.tween_callback(AudioManager.play_slot_stop)
	
	audioTween.tween_interval(0.65)
	audioTween.tween_callback(AudioManager.play_slot_stop)
	
	await tween.finished

func _animate_modifier_container_two() -> void:
	var audioTween = create_tween()
	audioTween.tween_callback(AudioManager.play_pop)
	audioTween.tween_interval(0.1)
	audioTween.tween_callback(AudioManager.play_pop)
	audioTween.tween_interval(0.1)
	audioTween.tween_callback(AudioManager.play_pop)
	
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(modifierSlotOne, "position", Vector2(650, 330), 0.3)
	tween.parallel().tween_property(modifierSlotOne, "size", Vector2(340, 420), 0.3)
	tween.parallel().tween_property(modifierSlotOne.get_node("Slot"), "position", Vector2(120, 40), 0.3)
	
	tween.parallel().tween_property(modifierSlotTwo, "position", Vector2(1050, 330), 0.3)
	tween.parallel().tween_property(modifierSlotTwo, "size", Vector2(340, 420), 0.3)
	tween.parallel().tween_property(modifierSlotTwo.get_node("Slot"), "position", Vector2(120, 40), 0.3)
	
	tween.parallel().tween_property(modifierSlotThree, "position", Vector2(1450, 330), 0.3)
	tween.parallel().tween_property(modifierSlotThree, "size", Vector2(340, 420), 0.3)
	tween.parallel().tween_property(modifierSlotThree.get_node("Slot"), "position", Vector2(120, 40), 0.3)
	
	tween.tween_property(modifierSlotOne.get_node("Name"), "modulate:a", 1, 1)
	tween.parallel().tween_property(modifierSlotOne.get_node("Description"), "modulate:a", 1, 1)
	tween.parallel().tween_property(modifierSlotTwo.get_node("Name"), "modulate:a", 1, 1)
	tween.parallel().tween_property(modifierSlotTwo.get_node("Description"), "modulate:a", 1, 1)
	tween.parallel().tween_property(modifierSlotThree.get_node("Name"), "modulate:a", 1, 1)
	tween.parallel().tween_property(modifierSlotThree.get_node("Description"), "modulate:a", 1, 1)
	
	tween.parallel().tween_property(modifierSlotOne.get_node("Multiplier"), "modulate:a", 1, .5)
	tween.parallel().tween_property(modifierSlotOne.get_node("Line"), "modulate:a", 1, .5)
	tween.parallel().tween_property(modifierSlotOne.get_node("Duration"), "modulate:a", 1, .5)
	tween.parallel().tween_property(modifierSlotOne.get_node("Multiplier"), "position", Vector2(0, 330), .5)
	tween.parallel().tween_property(modifierSlotOne.get_node("Line"), "scale:y", 1, .5)
	tween.parallel().tween_property(modifierSlotOne.get_node("Duration"), "position", Vector2(170, 330), .5)
	
	tween.parallel().tween_property(modifierSlotTwo.get_node("Multiplier"), "modulate:a", 1, .5)
	tween.parallel().tween_property(modifierSlotTwo.get_node("Line"), "modulate:a", 1, .5)
	tween.parallel().tween_property(modifierSlotTwo.get_node("Duration"), "modulate:a", 1, .5)
	tween.parallel().tween_property(modifierSlotTwo.get_node("Multiplier"), "position", Vector2(0, 330), .5)
	tween.parallel().tween_property(modifierSlotTwo.get_node("Line"), "scale:y", 1, .5)
	tween.parallel().tween_property(modifierSlotTwo.get_node("Duration"), "position", Vector2(170, 330), .5)
	
	tween.parallel().tween_property(modifierSlotThree.get_node("Multiplier"), "modulate:a", 1, .5)
	tween.parallel().tween_property(modifierSlotThree.get_node("Line"), "modulate:a", 1, .5)
	tween.parallel().tween_property(modifierSlotThree.get_node("Duration"), "modulate:a", 1, .5)
	tween.parallel().tween_property(modifierSlotThree.get_node("Multiplier"), "position", Vector2(0, 330), .5)
	tween.parallel().tween_property(modifierSlotThree.get_node("Line"), "scale:y", 1, .5)
	tween.parallel().tween_property(modifierSlotThree.get_node("Duration"), "position", Vector2(170, 330), .5)
	
	await tween.finished
	
	modifierSlotOne.mouse_filter = Control.MOUSE_FILTER_STOP
	modifierSlotTwo.mouse_filter = Control.MOUSE_FILTER_STOP
	modifierSlotThree.mouse_filter = Control.MOUSE_FILTER_STOP

func _animate_modifier_container_three() -> void:
	modifierSlotOne.get_node("Name").modulate.a = 0
	modifierSlotOne.get_node("Description").modulate.a = 0
	modifierSlotOne.get_node("Multiplier").modulate.a = 0
	modifierSlotOne.get_node("Line").modulate.a = 0
	modifierSlotOne.get_node("Duration").modulate.a = 0
	modifierSlotTwo.get_node("Name").modulate.a = 0
	modifierSlotTwo.get_node("Description").modulate.a = 0
	modifierSlotTwo.get_node("Multiplier").modulate.a = 0
	modifierSlotTwo.get_node("Line").modulate.a = 0
	modifierSlotTwo.get_node("Duration").modulate.a = 0
	modifierSlotThree.get_node("Name").modulate.a = 0
	modifierSlotThree.get_node("Description").modulate.a = 0
	modifierSlotThree.get_node("Multiplier").modulate.a = 0
	modifierSlotThree.get_node("Line").modulate.a = 0
	modifierSlotThree.get_node("Duration").modulate.a = 0
	
	AudioManager.play_move()
	
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(modifierSlotOne, "position", Vector2(150, 690), 0.3)
	tween.parallel().tween_property(modifierSlotOne, "size", Vector2(100, 100), 0.3)
	tween.parallel().tween_property(modifierSlotOne.get_node("Slot"), "position", Vector2(0, 0), 0.3)
	tween.parallel().tween_property(modifierSlotOne.get_node("Slot"), "scale", Vector2(.5, .5), 0.3)
	
	tween.parallel().tween_property(modifierSlotTwo, "position", Vector2(315, 690), 0.3)
	tween.parallel().tween_property(modifierSlotTwo, "size", Vector2(100, 100), 0.3)
	tween.parallel().tween_property(modifierSlotTwo.get_node("Slot"), "position", Vector2(0, 0), 0.3)
	tween.parallel().tween_property(modifierSlotTwo.get_node("Slot"), "scale", Vector2(.5, .5), 0.3)
	
	tween.parallel().tween_property(modifierSlotThree, "position", Vector2(480, 690), 0.3)
	tween.parallel().tween_property(modifierSlotThree, "size", Vector2(100, 100), 0.3)
	tween.parallel().tween_property(modifierSlotThree.get_node("Slot"), "position", Vector2(0, 0), 0.3)
	tween.parallel().tween_property(modifierSlotThree.get_node("Slot"), "scale", Vector2(.5, .5), 0.3)
	
	await tween.finished


func _select_modifiers() -> void:
	var availableByTier = { 1: [], 2: [], 3: [] }
	var activeIdModifiers = []
	
	for active in HoldoutStats.activeModifiers:
		activeIdModifiers.append(active["id"])
	
	for modifier in Database.MODIFIERS.values():
		if not modifier["id"] in activeIdModifiers:
			var tier = modifier["tier"]
			
			if modifier.has("healthCost") and HoldoutStats.playerHealthValue <= modifier["healthCost"]:
				continue
			
			if availableByTier.has(tier):
				availableByTier[tier].append(modifier)
	
	tierOneModifier = _pick_weighted_modifier(availableByTier[1])
	tierTwoModifier = _pick_weighted_modifier(availableByTier[2])
	tierThreeModifier = _pick_weighted_modifier(availableByTier[3])
	
	var currentPicks = [tierOneModifier.id, tierTwoModifier.id, tierThreeModifier.id]
	
	HoldoutStats.lastOfferedModifierIds.append_array(currentPicks)
	
	if HoldoutStats.lastOfferedModifierIds.size() >= 12: 
		HoldoutStats.lastOfferedModifierIds.clear()
		HoldoutStats.lastOfferedModifierIds.append_array(currentPicks)
	
	_update_slot_ui(tierOneModifier, modifierSlotOne)
	_update_slot_ui(tierTwoModifier, modifierSlotTwo)
	_update_slot_ui(tierThreeModifier, modifierSlotThree)
	
	modifierSlotOne.get_node("Slot").setup_reel(availableByTier[1])
	modifierSlotTwo.get_node("Slot").setup_reel(availableByTier[2])
	modifierSlotThree.get_node("Slot").setup_reel(availableByTier[3])

func _update_slot_ui(modifier: Dictionary, slot: Control) -> void:
	slot.get_node("Name").text = modifier.name
	slot.get_node("Description").text = modifier.description
	slot.get_node("Multiplier").text = "+ " + str(modifier.multiplier) + "x"
	slot.get_node("Duration").text = str(modifier.duration) + " Game" + ("s" if modifier.duration > 1 else "")
	pass

func _pick_weighted_modifier(tierPool: Array) -> Dictionary:
	if tierPool.is_empty(): 
		return {}
	
	# 80% chance to try and pick something "fresh"
	if randf() < 0.8:
		var freshPool = []
		for modifier in tierPool:
			if not modifier.id in HoldoutStats.lastOfferedModifierIds:
				freshPool.append(modifier)
		
		# Fallback if too many "fresh" picks were chosen
		if not freshPool.is_empty():
			return freshPool.pick_random()

	# 20% fallback for pure randomness
	return tierPool.pick_random()

func _on_modifier_1_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and !modifierSelected:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if modifierSlotsActive[0] == 1:
				modifierSlotsActive[0] = 0
				modifierSlotOne.get_node("Selected").visible = false
				
				var currentStyleBox = modifierSlotOne.get_theme_stylebox("panel").duplicate()
				currentStyleBox.bg_color = Color("151515")
				modifierSlotOne.add_theme_stylebox_override("panel", currentStyleBox)
			else:
				modifierSlotsActive[0] = 1
				modifierSlotOne.get_node("Selected").visible = true
				
				var currentStyleBox = modifierSlotOne.get_theme_stylebox("panel").duplicate()
				currentStyleBox.bg_color = Color("383838")
				modifierSlotOne.add_theme_stylebox_override("panel", currentStyleBox)
				
			var totalSelected = modifierSlotsActive.reduce(func(accumulator, number): return accumulator + number, 0)
			$NumberSelected.text = str(totalSelected) + "/3 Selected"

func _on_modifier_2_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and !modifierSelected:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if modifierSlotsActive[1] == 1:
				modifierSlotsActive[1] = 0
				modifierSlotTwo.get_node("Selected").visible = false
				
				var currentStyleBox = modifierSlotTwo.get_theme_stylebox("panel").duplicate()
				currentStyleBox.bg_color = Color("151515")
				modifierSlotTwo.add_theme_stylebox_override("panel", currentStyleBox)
			else:
				modifierSlotsActive[1] = 1
				modifierSlotTwo.get_node("Selected").visible = true
				
				var currentStyleBox = modifierSlotTwo.get_theme_stylebox("panel").duplicate()
				currentStyleBox.bg_color = Color("383838")
				modifierSlotTwo.add_theme_stylebox_override("panel", currentStyleBox)
				
			var totalSelected = modifierSlotsActive.reduce(func(accumulator, number): return accumulator + number, 0)
			$NumberSelected.text = str(totalSelected) + "/3 Selected"

func _on_modifier_3_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and !modifierSelected:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if modifierSlotsActive[2] == 1:
				modifierSlotsActive[2] = 0
				modifierSlotThree.get_node("Selected").visible = false
				
				var currentStyleBox = modifierSlotThree.get_theme_stylebox("panel").duplicate()
				currentStyleBox.bg_color = Color("151515")
				modifierSlotThree.add_theme_stylebox_override("panel", currentStyleBox)
			else:
				modifierSlotsActive[2] = 1
				modifierSlotThree.get_node("Selected").visible = true
				
				var currentStyleBox = modifierSlotThree.get_theme_stylebox("panel").duplicate()
				currentStyleBox.bg_color = Color("383838")
				modifierSlotThree.add_theme_stylebox_override("panel", currentStyleBox)
				
			var totalSelected = modifierSlotsActive.reduce(func(accumulator, number): return accumulator + number, 0)
			$NumberSelected.text = str(totalSelected) + "/3 Selected"

func _on_modifier_1_mouse_entered() -> void:
	if modifierSelected:
		return
		
	var tween = create_tween()
	tween.tween_property(modifierSlotOne, "scale", Vector2(1.05, 1.05), 0.1)
	AudioManager.play_card_hover()

func _on_modifier_1_mouse_exited() -> void:
	if modifierSelected:
		return
		
	var tween = create_tween()
	tween.tween_property(modifierSlotOne, "scale", Vector2(1, 1), 0.1)
	AudioManager.play_card_hover()

func _on_modifier_2_mouse_entered() -> void:
	if modifierSelected:
		return
		
	var tween = create_tween()
	tween.tween_property(modifierSlotTwo, "scale", Vector2(1.05, 1.05), 0.1)
	AudioManager.play_card_hover()

func _on_modifier_2_mouse_exited() -> void:
	if modifierSelected:
		return
		
	var tween = create_tween()
	tween.tween_property(modifierSlotTwo, "scale", Vector2(1, 1), 0.1)
	AudioManager.play_card_hover()

func _on_modifier_3_mouse_entered() -> void:
	if modifierSelected:
		return
		
	var tween = create_tween()
	tween.tween_property(modifierSlotThree, "scale", Vector2(1.05, 1.05), 0.1)
	AudioManager.play_card_hover()

func _on_modifier_3_mouse_exited() -> void:
	if modifierSelected:
		return
		
	var tween = create_tween()
	tween.tween_property(modifierSlotThree, "scale", Vector2(1, 1), 0.1)
	AudioManager.play_card_hover()

func _hide_modifier_container() -> void:
	#important, if something comes after the modifier we must do something else
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	if isAllegianceRound or isCardRemovalRound:
		# Go left
		tween.parallel().tween_callback(AudioManager.play_move)
		tween.parallel().tween_property(modifierSlotOne, "position:x", -750.0, 0.3)
		
		tween.parallel().tween_callback(AudioManager.play_move).set_delay(0.1)
		tween.parallel().tween_property(modifierSlotTwo, "position:x", -750.0, 0.3).set_delay(0.1)
		
		tween.parallel().tween_callback(AudioManager.play_move).set_delay(0.2)
		tween.parallel().tween_property(modifierSlotThree, "position:x", -750.0, 0.3).set_delay(0.2)
	else:
		# Go up
		tween.parallel().tween_callback(AudioManager.play_move)
		tween.parallel().tween_property(modifierSlotOne, "position:y", -750.0, 0.3)
		
		tween.parallel().tween_callback(AudioManager.play_move).set_delay(0.1)
		tween.parallel().tween_property(modifierSlotTwo, "position:y", -750.0, 0.3).set_delay(0.1)
		
		tween.parallel().tween_callback(AudioManager.play_move).set_delay(0.2)
		tween.parallel().tween_property(modifierSlotThree, "position:y", -750.0, 0.3).set_delay(0.2)
	
	await tween.finished


#Allegiance
func _setup_allegiance_container() -> void:
	allegianceSlotsActive = [0, 0, 0]
	selectedAllegianceIndex = -1
	allowAllegianceSelections = false
	
	var screenSize = get_viewport_rect().size
	
	var currentStyleBox = allegianceSlotOne.get_theme_stylebox("panel").duplicate()
	currentStyleBox.bg_color = Color("151515")
	allegianceSlotOne.add_theme_stylebox_override("panel", currentStyleBox)
	allegianceSlotTwo.add_theme_stylebox_override("panel", currentStyleBox)
	allegianceSlotThree.add_theme_stylebox_override("panel", currentStyleBox)
	
	modifierSlotOne.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modifierSlotTwo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modifierSlotThree.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	allegianceSlotOne.position = Vector2(1020, screenSize.y + 250)
	allegianceSlotTwo.position = Vector2(1300, screenSize.y + 250)
	allegianceSlotThree.position = Vector2(1580, screenSize.y + 250)
	
	allegianceSlotOne.size = Vector2(180, 180)
	allegianceSlotTwo.size = Vector2(180, 180)
	allegianceSlotThree.size = Vector2(180, 180)
	
	for slot in [allegianceSlotOne, allegianceSlotTwo, allegianceSlotThree]:
		slot.get_node("Slot").hide()
		slot.get_node("Slot").scale = Vector2(1, 1)
		slot.get_node("Slot").position = Vector2(40, 40)
		slot.get_node("Name").modulate.a = 0
		slot.get_node("Description").modulate.a = 0
		slot.get_node("Tier").modulate.a = 0
		slot.get_node("Selected").hide()
	
	fungusSlotOne.modulate.a = 0
	fungusSlotTwo.modulate.a = 0
	fungusSlotThree.modulate.a = 0
	
	_select_allegiances()

func _animate_allegiance_container_one() -> void:
	allegianceContainer.show()
	
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(allegianceSlotOne, "position", Vector2(1020, 450), 0.3)
	tween.tween_interval(0.3)
	
	tween.tween_callback(func(): 
		allegianceSlotOne.get_node("Slot").show()
		allegianceSlotOne.get_node("Slot").spin_to_modifier(allegianceOptionOne)
		)
	
	tween.tween_property(allegianceSlotTwo, "position", Vector2(1300, 450), 0.3)
	tween.tween_interval(0.3)
	
	tween.tween_callback(func(): 
		allegianceSlotTwo.get_node("Slot").show()
		allegianceSlotTwo.get_node("Slot").spin_to_modifier(allegianceOptionTwo)
		)
	
	tween.tween_property(allegianceSlotThree, "position", Vector2(1580, 450), 0.3)
	tween.tween_interval(0.3)
	
	tween.tween_callback(func(): 
		allegianceSlotThree.get_node("Slot").show()
		allegianceSlotThree.get_node("Slot").spin_to_modifier(allegianceOptionThree)
		)
		
	tween.tween_interval(1.9) # Right after the last spin is done
	
	var whooshTween = create_tween()
	whooshTween.tween_interval(0.2)
	whooshTween.tween_callback(AudioManager.play_move)
	whooshTween.tween_interval(0.5)
	whooshTween.tween_callback(AudioManager.play_move)
	whooshTween.tween_interval(0.5)
	whooshTween.tween_callback(AudioManager.play_move)
	
	var audioTween = create_tween()
	
	audioTween.tween_interval(0.6)
	audioTween.tween_callback(AudioManager.play_slot_spin)
	
	audioTween.tween_interval(0.6)
	audioTween.tween_callback(AudioManager.play_slot_spin)
	
	audioTween.tween_interval(0.6)
	audioTween.tween_callback(AudioManager.play_slot_spin)
	
	audioTween.tween_interval(0.65) 
	audioTween.tween_callback(AudioManager.play_slot_stop)
	
	audioTween.tween_interval(0.65)
	audioTween.tween_callback(AudioManager.play_slot_stop)
	
	audioTween.tween_interval(0.65)
	audioTween.tween_callback(AudioManager.play_slot_stop)
	
	await tween.finished

func _animate_allegiance_container_one_variant() -> void:
	var screenSize = get_viewport_rect().size
	allegianceSlotOne.position = Vector2(730, screenSize.y + 250)
	allegianceSlotTwo.position = Vector2(1130, screenSize.y + 250)
	allegianceSlotThree.position = Vector2(1530, screenSize.y + 250)
	
	allegianceSlotOne.size = Vector2(180, 180)
	allegianceSlotTwo.size = Vector2(180, 180)
	allegianceSlotThree.size = Vector2(180, 180)
	
	allegianceContainer.show()
	
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(allegianceSlotOne, "position", Vector2(730, 450), 0.3)
	tween.tween_interval(0.3)
	
	tween.tween_callback(func(): 
		allegianceSlotOne.get_node("Slot").show()
		allegianceSlotOne.get_node("Slot").spin_to_modifier(allegianceOptionOne)
		)
	
	tween.tween_property(allegianceSlotTwo, "position", Vector2(1130, 450), 0.3)
	tween.tween_interval(0.3)
	
	tween.tween_callback(func(): 
		allegianceSlotTwo.get_node("Slot").show()
		allegianceSlotTwo.get_node("Slot").spin_to_modifier(allegianceOptionTwo)
		)
	
	tween.tween_property(allegianceSlotThree, "position", Vector2(1530, 450), 0.3)
	tween.tween_interval(0.3)
	
	tween.tween_callback(func(): 
		allegianceSlotThree.get_node("Slot").show()
		allegianceSlotThree.get_node("Slot").spin_to_modifier(allegianceOptionThree)
		)
		
	tween.tween_interval(1.9) # Right after the last spin is done
	
	var whooshTween = create_tween()
	whooshTween.tween_interval(0.2)
	whooshTween.tween_callback(AudioManager.play_move)
	whooshTween.tween_interval(0.5)
	whooshTween.tween_callback(AudioManager.play_move)
	whooshTween.tween_interval(0.5)
	whooshTween.tween_callback(AudioManager.play_move)
	
	var audioTween = create_tween()
	
	audioTween.tween_interval(0.6)
	audioTween.tween_callback(AudioManager.play_slot_spin)
	
	audioTween.tween_interval(0.6)
	audioTween.tween_callback(AudioManager.play_slot_spin)
	
	audioTween.tween_interval(0.6)
	audioTween.tween_callback(AudioManager.play_slot_spin)
	
	audioTween.tween_interval(0.65) 
	audioTween.tween_callback(AudioManager.play_slot_stop)
	
	audioTween.tween_interval(0.65)
	audioTween.tween_callback(AudioManager.play_slot_stop)
	
	audioTween.tween_interval(0.65)
	audioTween.tween_callback(AudioManager.play_slot_stop)
	
	await tween.finished

func _animate_allegiance_container_two() -> void:
	var audioTween = create_tween()
	audioTween.tween_callback(AudioManager.play_pop)
	audioTween.tween_interval(0.1)
	audioTween.tween_callback(AudioManager.play_pop)
	audioTween.tween_interval(0.1)
	audioTween.tween_callback(AudioManager.play_pop)
	
	var tween = create_tween()
	fungusFadeTween = tween
	
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(allegianceSlotOne, "position", Vector2(650, 330), 0.3)
	tween.parallel().tween_property(allegianceSlotOne, "size", Vector2(340, 420), 0.3)
	tween.parallel().tween_property(allegianceSlotOne.get_node("Slot"), "position", Vector2(120, 40), 0.3)
	
	tween.parallel().tween_property(allegianceSlotTwo, "position", Vector2(1050, 330), 0.3)
	tween.parallel().tween_property(allegianceSlotTwo, "size", Vector2(340, 420), 0.3)
	tween.parallel().tween_property(allegianceSlotTwo.get_node("Slot"), "position", Vector2(120, 40), 0.3)
	
	tween.parallel().tween_property(allegianceSlotThree, "position", Vector2(1450, 330), 0.3)
	tween.parallel().tween_property(allegianceSlotThree, "size", Vector2(340, 420), 0.3)
	tween.parallel().tween_property(allegianceSlotThree.get_node("Slot"), "position", Vector2(120, 40), 0.3)
	
	tween.tween_property(allegianceSlotOne.get_node("Name"), "modulate:a", 1, 1)
	tween.parallel().tween_property(allegianceSlotOne.get_node("Description"), "modulate:a", 1, 1)
	tween.parallel().tween_property(allegianceSlotTwo.get_node("Name"), "modulate:a", 1, 1)
	tween.parallel().tween_property(allegianceSlotTwo.get_node("Description"), "modulate:a", 1, 1)
	tween.parallel().tween_property(allegianceSlotThree.get_node("Name"), "modulate:a", 1, 1)
	tween.parallel().tween_property(allegianceSlotThree.get_node("Description"), "modulate:a", 1, 1)
	
	allowAllegianceSelections = true
	
	tween.parallel().tween_property(fungusSlotOne, "modulate:a", 1, 3)
	tween.parallel().tween_property(fungusSlotTwo, "modulate:a", 1, 3)
	tween.parallel().tween_property(fungusSlotThree, "modulate:a", 1, 3)
	
	tween.parallel().tween_property(allegianceSlotOne.get_node("Tier"), "modulate:a", 1, .5)
	tween.parallel().tween_property(allegianceSlotTwo.get_node("Tier"), "modulate:a", 1, .5)
	tween.parallel().tween_property(allegianceSlotThree.get_node("Tier"), "modulate:a", 1, .5)
	
	await tween.finished
	
	allegianceSlotOne.mouse_filter = Control.MOUSE_FILTER_STOP
	allegianceSlotTwo.mouse_filter = Control.MOUSE_FILTER_STOP
	allegianceSlotThree.mouse_filter = Control.MOUSE_FILTER_STOP

func _apply_fungus_colors(fungusNode: Control, faction: String) -> void:
	var colors: Array = FACTION_FUNGUS_COLORS.get(faction, ["ffffff", "ffffff", "ffffff"])
	fungusNode.get_node("1").modulate = Color(colors[0])
	fungusNode.get_node("2").modulate = Color(colors[1])
	fungusNode.get_node("3").modulate = Color(colors[2])

func _select_allegiances() -> void:
	var chosen: Array = []
	
	if HoldoutStats.activeAllegiance.is_empty():
		var shuffledFactions = ALLEGIANCE_FACTIONS.duplicate()
		shuffledFactions.shuffle()
		
		for faction in shuffledFactions.slice(0, 3):
			var pool = _get_allegiance_pool(faction, 1)
			chosen.append(_pick_weighted_allegiance(pool))
	else:
		var activeFaction = HoldoutStats.activeAllegiance["faction"]
		var activeTier = HoldoutStats.activeAllegiance["tier"]
		
		var upgradeTier = min(activeTier + 1, 3)
		var otherTier = upgradeTier - 1
		
		var otherFactions = ALLEGIANCE_FACTIONS.duplicate()
		otherFactions.erase(activeFaction)
		otherFactions.shuffle()
		
		for faction in otherFactions.slice(0, 2):
			var pool = _get_allegiance_pool(faction, otherTier)
			chosen.append(_pick_weighted_allegiance(pool))
		
		var upgradePool = _get_allegiance_pool(activeFaction, upgradeTier)
		var freshUpgradePool = []
		for allegiance in upgradePool:
			if allegiance.id != HoldoutStats.activeAllegiance.get("id", -1):
				freshUpgradePool.append(allegiance)
		
		chosen.append(_pick_weighted_allegiance(freshUpgradePool if not freshUpgradePool.is_empty() else upgradePool))
	
	allegianceOptionOne = chosen[0]
	allegianceOptionTwo = chosen[1]
	allegianceOptionThree = chosen[2]
	
	var currentPicks = [allegianceOptionOne.id, allegianceOptionTwo.id, allegianceOptionThree.id]
	HoldoutStats.lastOfferedAllegianceIds.append_array(currentPicks)
	
	if HoldoutStats.lastOfferedAllegianceIds.size() >= 9:
		HoldoutStats.lastOfferedAllegianceIds.clear()
		HoldoutStats.lastOfferedAllegianceIds.append_array(currentPicks)
	
	_update_allegiance_slot_ui(allegianceOptionOne, allegianceSlotOne)
	_update_allegiance_slot_ui(allegianceOptionTwo, allegianceSlotTwo)
	_update_allegiance_slot_ui(allegianceOptionThree, allegianceSlotThree)
	
	allegianceSlotOne.get_node("Slot").setup_reel(_get_allegiance_pool(allegianceOptionOne.faction, allegianceOptionOne.tier))
	allegianceSlotTwo.get_node("Slot").setup_reel(_get_allegiance_pool(allegianceOptionTwo.faction, allegianceOptionTwo.tier))
	allegianceSlotThree.get_node("Slot").setup_reel(_get_allegiance_pool(allegianceOptionThree.faction, allegianceOptionThree.tier))
	
	_apply_fungus_colors(fungusSlotOne, allegianceOptionOne.faction)
	_apply_fungus_colors(fungusSlotTwo, allegianceOptionTwo.faction)
	_apply_fungus_colors(fungusSlotThree, allegianceOptionThree.faction)

func _get_allegiance_pool(faction: String, tier: int) -> Array:
	var pool = []
	for allegiance in Database.ALLEGIANCES.values():
		if allegiance["faction"] == faction and allegiance["tier"] == tier:
			pool.append(allegiance)
	return pool

func _pick_weighted_allegiance(pool: Array) -> Dictionary:
	if pool.is_empty():
		return {}
	
	if randf() < 0.8:
		var freshPool = []
		for allegiance in pool:
			if not allegiance.id in HoldoutStats.lastOfferedAllegianceIds:
				freshPool.append(allegiance)
		
		if not freshPool.is_empty():
			return freshPool.pick_random()
	
	return pool.pick_random()

func _update_allegiance_slot_ui(allegiance: Dictionary, slot: Control) -> void:
	slot.get_node("Name").text = allegiance.name
	slot.get_node("Description").text = allegiance.description
	slot.get_node("Tier").text = str(allegiance.faction) + " Tier " + str(allegiance.tier)

func _get_allegiance_slots() -> Array:
	return [allegianceSlotOne, allegianceSlotTwo, allegianceSlotThree]

func _set_allegiance_slot_selected(slot: Panel, isSelected: bool) -> void:
	slot.get_node("Selected").visible = isSelected
	
	var currentStyleBox = slot.get_theme_stylebox("panel").duplicate()
	currentStyleBox.bg_color = Color("383838") if isSelected else Color("151515")
	slot.add_theme_stylebox_override("panel", currentStyleBox)
	$NumberSelected.text = "1/1 Selected"

func _select_allegiance_slot(index: int) -> void:
	var slots = _get_allegiance_slots()
	
	if selectedAllegianceIndex == index:
		_set_allegiance_slot_selected(slots[index], false)
		selectedAllegianceIndex = -1
		$NumberSelected.text = "0/1 Selected"
		return
	
	if selectedAllegianceIndex != -1:
		_set_allegiance_slot_selected(slots[selectedAllegianceIndex], false)
	
	_set_allegiance_slot_selected(slots[index], true)
	selectedAllegianceIndex = index

func _on_allegiance_1_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and allowAllegianceSelections:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_select_allegiance_slot(0)

func _on_allegiance_2_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and allowAllegianceSelections:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_select_allegiance_slot(1)

func _on_allegiance_3_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and allowAllegianceSelections:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_select_allegiance_slot(2)

func _on_allegiance_1_mouse_entered() -> void:
	if !allowAllegianceSelections:
		return
	
	var tween = create_tween()
	tween.tween_property(allegianceSlotOne, "scale", Vector2(1.05, 1.05), 0.1)
	tween.parallel().tween_property(fungusSlotOne.get_node("1"), "scale", Vector2(1.05, 1.05), 0.1)
	tween.parallel().tween_property(fungusSlotOne.get_node("2"), "scale", Vector2(1.05, 1.05), 0.1)
	tween.parallel().tween_property(fungusSlotOne.get_node("3"), "scale", Vector2(1.05, 1.05), 0.1)
	AudioManager.play_card_hover()

func _on_allegiance_1_mouse_exited() -> void:
	if !allowAllegianceSelections:
		return
	
	var tween = create_tween()
	tween.tween_property(allegianceSlotOne, "scale", Vector2(1, 1), 0.1)
	tween.parallel().tween_property(fungusSlotOne.get_node("1"), "scale", Vector2(1, 1), 0.1)
	tween.parallel().tween_property(fungusSlotOne.get_node("2"), "scale", Vector2(1, 1), 0.1)
	tween.parallel().tween_property(fungusSlotOne.get_node("3"), "scale", Vector2(1, 1), 0.1)
	AudioManager.play_card_hover()

func _on_allegiance_2_mouse_entered() -> void:
	if !allowAllegianceSelections:
		return
	
	var tween = create_tween()
	tween.tween_property(allegianceSlotTwo, "scale", Vector2(1.05, 1.05), 0.1)
	tween.parallel().tween_property(fungusSlotTwo.get_node("1"), "scale", Vector2(1.05, 1.05), 0.1)
	tween.parallel().tween_property(fungusSlotTwo.get_node("2"), "scale", Vector2(1.05, 1.05), 0.1)
	tween.parallel().tween_property(fungusSlotTwo.get_node("3"), "scale", Vector2(1.05, 1.05), 0.1)
	AudioManager.play_card_hover()

func _on_allegiance_2_mouse_exited() -> void:
	if !allowAllegianceSelections:
		return
	
	var tween = create_tween()
	tween.tween_property(allegianceSlotTwo, "scale", Vector2(1, 1), 0.1)
	tween.parallel().tween_property(fungusSlotTwo.get_node("1"), "scale", Vector2(1, 1), 0.1)
	tween.parallel().tween_property(fungusSlotTwo.get_node("2"), "scale", Vector2(1, 1), 0.1)
	tween.parallel().tween_property(fungusSlotTwo.get_node("3"), "scale", Vector2(1, 1), 0.1)
	AudioManager.play_card_hover()

func _on_allegiance_3_mouse_entered() -> void:
	if !allowAllegianceSelections:
		return
	
	var tween = create_tween()
	tween.tween_property(allegianceSlotThree, "scale", Vector2(1.05, 1.05), 0.1)
	tween.parallel().tween_property(fungusSlotThree.get_node("1"), "scale", Vector2(1.05, 1.05), 0.1)
	tween.parallel().tween_property(fungusSlotThree.get_node("2"), "scale", Vector2(1.05, 1.05), 0.1)
	tween.parallel().tween_property(fungusSlotThree.get_node("3"), "scale", Vector2(1.05, 1.05), 0.1)
	AudioManager.play_card_hover()

func _on_allegiance_3_mouse_exited() -> void:
	if !allowAllegianceSelections:
		return
	
	var tween = create_tween()
	tween.tween_property(allegianceSlotThree, "scale", Vector2(1, 1), 0.1)
	tween.parallel().tween_property(fungusSlotThree.get_node("1"), "scale", Vector2(1, 1), 0.1)
	tween.parallel().tween_property(fungusSlotThree.get_node("2"), "scale", Vector2(1, 1), 0.1)
	tween.parallel().tween_property(fungusSlotThree.get_node("3"), "scale", Vector2(1, 1), 0.1)
	AudioManager.play_card_hover()

func _hide_allegiance_container() -> void:
	if fungusFadeTween and fungusFadeTween.is_valid():
		fungusFadeTween.kill()
		
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.parallel().tween_callback(AudioManager.play_move)
	tween.parallel().tween_property(allegianceSlotOne, "position:y", -750.0, 0.3)
	
	tween.parallel().tween_property(fungusSlotOne, "modulate:a", 0, 0.3)
	tween.parallel().tween_property(fungusSlotTwo, "modulate:a", 0, 0.3)
	tween.parallel().tween_property(fungusSlotThree, "modulate:a", 0, 0.3)
	
	tween.parallel().tween_callback(AudioManager.play_move).set_delay(0.1)
	tween.parallel().tween_property(allegianceSlotTwo, "position:y", -750.0, 0.3).set_delay(0.1)
	
	tween.parallel().tween_callback(AudioManager.play_move).set_delay(0.2)
	tween.parallel().tween_property(allegianceSlotThree, "position:y", -750.0, 0.3).set_delay(0.2)
	
	await tween.finished


# Removal
func _setup_removal_container() -> void:
	removalSlotsActive = [0, 0, 0]
	selectedRemovalIndex = -1
	allowRemovalSelections = false
	isShowingRemovalDeck = false
	isAnimatingRemovalDeck = false
	
	for visual in removalCardVisuals:
		if is_instance_valid(visual):
			visual.queue_free()
	removalCardVisuals.clear()
	
	var screenSize = get_viewport_rect().size
	
	var currentStyleBox = removalSlotOne.get_theme_stylebox("panel").duplicate()
	currentStyleBox.bg_color = Color("151515")
	removalSlotOne.add_theme_stylebox_override("panel", currentStyleBox)
	removalSlotTwo.add_theme_stylebox_override("panel", currentStyleBox)
	removalSlotThree.add_theme_stylebox_override("panel", currentStyleBox)
	
	removalSlotOne.position = Vector2(1020, screenSize.y + 250)
	removalSlotTwo.position = Vector2(1300, screenSize.y + 250)
	removalSlotThree.position = Vector2(1580, screenSize.y + 250)
	
	removalSlotOne.size = Vector2(180, 180)
	removalSlotTwo.size = Vector2(180, 180)
	removalSlotThree.size = Vector2(180, 180)
	
	$"RemovalContainer/Player Box".position = Vector2(2200, 315)
	$"RemovalContainer/Reroll Button".position = Vector2(2200, 501)
	$"RemovalContainer/View Deck Button".position = Vector2(2200, 644)
	
	for slot in [removalSlotOne, removalSlotTwo, removalSlotThree]:
		slot.get_node("Slot").hide()
		slot.get_node("Slot").scale = Vector2(1, 1)
		slot.get_node("Slot").position = Vector2(40, 40)
		slot.get_node("Slot").modulate.a = 1
		slot.get_node("Selected").hide()
	
	_select_removal_cards()
	
	await _populate_removal_deck_view()
	
	removalDisplayedHealth = HoldoutStats.playerHealthValue
	$"RemovalContainer/Player Box/PlayerHead".texture = Database.get_avatar_head_texture(_get_removal_head_base_path() + "Neutral.png")
	$"RemovalContainer/Player Box/Health".text = _format_removal_health_text(removalDisplayedHealth)
	
	$"RemovalContainer/View Deck Button/Text".text = "View Decks"


func _animate_removal_container_one() -> void:
	removalContainer.show()
	
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(removalSlotOne, "position", Vector2(1020, 450), 0.3)
	tween.tween_interval(0.3)
	
	tween.tween_callback(func(): 
		removalSlotOne.get_node("Slot").show()
		removalSlotOne.get_node("Slot").spin_to_modifier(removalOptionOne)
		)
	
	tween.tween_property(removalSlotTwo, "position", Vector2(1300, 450), 0.3)
	tween.tween_interval(0.3)
	
	tween.tween_callback(func(): 
		removalSlotTwo.get_node("Slot").show()
		removalSlotTwo.get_node("Slot").spin_to_modifier(removalOptionTwo)
		)
	
	tween.tween_property(removalSlotThree, "position", Vector2(1580, 450), 0.3)
	tween.tween_interval(0.3)
	
	tween.tween_callback(func(): 
		removalSlotThree.get_node("Slot").show()
		removalSlotThree.get_node("Slot").spin_to_modifier(removalOptionThree)
		)
		
	tween.tween_interval(1.9) # Right after the last spin is done
	
	var whooshTween = create_tween()
	whooshTween.tween_interval(0.2)
	whooshTween.tween_callback(AudioManager.play_move)
	whooshTween.tween_interval(0.5)
	whooshTween.tween_callback(AudioManager.play_move)
	whooshTween.tween_interval(0.5)
	whooshTween.tween_callback(AudioManager.play_move)
	
	var audioTween = create_tween()
	
	audioTween.tween_interval(0.6)
	audioTween.tween_callback(AudioManager.play_slot_spin)
	
	audioTween.tween_interval(0.6)
	audioTween.tween_callback(AudioManager.play_slot_spin)
	
	audioTween.tween_interval(0.6)
	audioTween.tween_callback(AudioManager.play_slot_spin)
	
	audioTween.tween_interval(0.65) 
	audioTween.tween_callback(AudioManager.play_slot_stop)
	
	audioTween.tween_interval(0.65)
	audioTween.tween_callback(AudioManager.play_slot_stop)
	
	audioTween.tween_interval(0.65)
	audioTween.tween_callback(AudioManager.play_slot_stop)
	
	await tween.finished


func _animate_removal_container_one_variant(isReroll: bool = false) -> void:
	var screenSize = get_viewport_rect().size
	
	if !isReroll:
		removalSlotOne.position = Vector2(730, screenSize.y + 250)
		removalSlotTwo.position = Vector2(1130, screenSize.y + 250)
		removalSlotThree.position = Vector2(1530, screenSize.y + 250)
	
	removalSlotOne.size = Vector2(180, 180)
	removalSlotTwo.size = Vector2(180, 180)
	removalSlotThree.size = Vector2(180, 180)
	
	removalContainer.show()
	
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	if isReroll:
		tween.tween_interval(0.6)
	else:
		tween.tween_property(removalSlotOne, "position", Vector2(730, 450), 0.3)
		tween.tween_interval(0.3)
		
	
	tween.tween_callback(func(): 
		removalSlotOne.get_node("Slot").show()
		removalSlotOne.get_node("Slot").spin_to_modifier(removalOptionOne)
		)
	
	if isReroll:
		tween.tween_interval(0.6)
	else:
		tween.tween_property(removalSlotTwo, "position", Vector2(1130, 450), 0.3)
		tween.tween_interval(0.3)
	
	tween.tween_callback(func(): 
		removalSlotTwo.get_node("Slot").show()
		removalSlotTwo.get_node("Slot").spin_to_modifier(removalOptionTwo)
		)
	
	if isReroll:
		tween.tween_interval(0.6)
	else:
		tween.tween_property(removalSlotThree, "position", Vector2(1530, 450), 0.3)
		tween.tween_interval(0.3)
	
	tween.tween_callback(func(): 
		removalSlotThree.get_node("Slot").show()
		removalSlotThree.get_node("Slot").spin_to_modifier(removalOptionThree)
		)
		
	tween.tween_interval(1.9) # Right after the last spin is done
	
	if !isReroll:
		var whooshTween = create_tween()
		whooshTween.tween_interval(0.2)
		whooshTween.tween_callback(AudioManager.play_move)
		whooshTween.tween_interval(0.5)
		whooshTween.tween_callback(AudioManager.play_move)
		whooshTween.tween_interval(0.5)
		whooshTween.tween_callback(AudioManager.play_move)
	
	var audioTween = create_tween()
	
	audioTween.tween_interval(0.6)
	audioTween.tween_callback(AudioManager.play_slot_spin)
	
	audioTween.tween_interval(0.6)
	audioTween.tween_callback(AudioManager.play_slot_spin)
	
	audioTween.tween_interval(0.6)
	audioTween.tween_callback(AudioManager.play_slot_spin)
	
	audioTween.tween_interval(0.65) 
	audioTween.tween_callback(AudioManager.play_slot_stop)
	
	audioTween.tween_interval(0.65)
	audioTween.tween_callback(AudioManager.play_slot_stop)
	
	audioTween.tween_interval(0.65)
	audioTween.tween_callback(AudioManager.play_slot_stop)
	
	await tween.finished


func _animate_removal_container_two() -> void:
	var audioTween = create_tween()
	audioTween.tween_callback(AudioManager.play_pop)
	audioTween.tween_interval(0.1)
	audioTween.tween_callback(AudioManager.play_pop)
	audioTween.tween_interval(0.1)
	audioTween.tween_callback(AudioManager.play_pop)
	
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(removalSlotOne, "position", Vector2(620, 315), 0.3)
	tween.parallel().tween_property(removalSlotOne, "size", Vector2(295, 414), 0.3)
	tween.parallel().tween_property(removalSlotOne.get_node("Slot"), "position", Vector2(120, 40), 0.3)
	
	_reveal_removal_card(removalSlotOne, removalOptionOne)
	
	tween.parallel().tween_property(removalSlotTwo, "position", Vector2(950, 315), 0.3)
	tween.parallel().tween_property(removalSlotTwo, "size", Vector2(295, 414), 0.3)
	tween.parallel().tween_property(removalSlotTwo.get_node("Slot"), "position", Vector2(120, 40), 0.3)
	
	_reveal_removal_card(removalSlotTwo, removalOptionTwo)
	
	tween.parallel().tween_property(removalSlotThree, "position", Vector2(1280, 315), 0.3)
	tween.parallel().tween_property(removalSlotThree, "size", Vector2(295, 414), 0.3)
	tween.parallel().tween_property(removalSlotThree.get_node("Slot"), "position", Vector2(120, 40), 0.3)
	
	_reveal_removal_card(removalSlotThree, removalOptionThree)
	
	await tween.finished
	
	removalSlotOne.mouse_filter = Control.MOUSE_FILTER_STOP
	removalSlotTwo.mouse_filter = Control.MOUSE_FILTER_STOP
	removalSlotThree.mouse_filter = Control.MOUSE_FILTER_STOP
	allowRemovalSelections = true


func _animate_removal_container_three() -> void:
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	AudioManager.play_move()
	
	tween.tween_property($"RemovalContainer/Player Box", "position", Vector2(1611, 315), 0.3)
	tween.parallel().tween_property($"RemovalContainer/Reroll Button", "position", Vector2(1611, 501), 0.3).set_delay(0.1)
	tween.parallel().tween_property($"RemovalContainer/View Deck Button", "position", Vector2(1611, 644), 0.3).set_delay(0.1)
	
	
	await tween.finished


func _get_remaining_deck_count(baseDeck: Array) -> int:
	return Database.build_run_deck(baseDeck).size()

func _get_removal_pool() -> Array:
	var seen := {}
	var pool: Array = []
	
	for cardName in Database.standardCharacterDeck:
		if seen.has(cardName):
			continue
		seen[cardName] = true
		
		var data = Database.CHARACTERS[cardName]
		pool.append({
			"id": cardName,
			"cardType": "Character",
			"name": data[4],
			"faction": data[2],
			"description": data[5],
			"icon": FACTION_REMOVAL_ICONS.get(data[2], FACTION_REMOVAL_ICONS["Support"]),
		})
	
	var remainingSupportCount = _get_remaining_deck_count(Database.standardSupportDeck)
	if remainingSupportCount >= REMOVAL_OFFER_THRESHOLD:
		for cardName in Database.standardSupportDeck:
			if seen.has(cardName):
				continue
			seen[cardName] = true
			
			var data = Database.SUPPORTS[cardName]
			pool.append({
				"id": cardName,
				"cardType": "Support",
				"name": data["CardText"],
				"faction": "Support",
				"description": data["PerkText"],
				"icon": FACTION_REMOVAL_ICONS["Support"],
			})
	
	return pool

func _pick_weighted_removal_card(pool: Array) -> Dictionary:
	if pool.is_empty():
		return {}
	
	var charPool = pool.filter(func(c): return c.cardType == "Character")
	var suppPool = pool.filter(func(c): return c.cardType == "Support")
	var targetPool = pool
	
	if not charPool.is_empty() and not suppPool.is_empty():
		if randf() < 0.80:
			targetPool = charPool
		else:
			targetPool = suppPool
	
	if randf() < 0.8:
		var freshPool = targetPool.filter(func(c): return not c.id in HoldoutStats.lastOfferedRemovalIds)
		
		if not freshPool.is_empty():
			return freshPool.pick_random()
	
	return targetPool.pick_random()

func _select_removal_cards() -> void:
	var fullPool = _get_removal_pool()
	var workingPool = fullPool.duplicate()
	var chosen: Array = []
	
	for i in range(3):
		if workingPool.is_empty():
			break
		var picked = _pick_weighted_removal_card(workingPool)
		chosen.append(picked)
		workingPool.erase(picked) # don't offer the same card twice in one round
	
	removalOptionOne = chosen[0]
	removalOptionTwo = chosen[1]
	removalOptionThree = chosen[2]
	
	var currentPicks = [removalOptionOne.id, removalOptionTwo.id, removalOptionThree.id]
	HoldoutStats.lastOfferedRemovalIds.append_array(currentPicks)
	
	if HoldoutStats.lastOfferedRemovalIds.size() >= 9:
		HoldoutStats.lastOfferedRemovalIds.clear()
		HoldoutStats.lastOfferedRemovalIds.append_array(currentPicks)
	
	removalSlotOne.get_node("Slot").setup_reel(fullPool)
	removalSlotTwo.get_node("Slot").setup_reel(fullPool)
	removalSlotThree.get_node("Slot").setup_reel(fullPool)

func _apply_selected_removals() -> void:
	var selectedOptions = []
	if removalSlotsActive[0] == 1: selectedOptions.append(removalOptionOne)
	if removalSlotsActive[1] == 1: selectedOptions.append(removalOptionTwo)
	if removalSlotsActive[2] == 1: selectedOptions.append(removalOptionThree)
	
	for card in selectedOptions:
		var cardKey: String = card.id
		HoldoutStats.deckAdjustments[cardKey] = HoldoutStats.deckAdjustments.get(cardKey, 0) - 1

func _populate_removal_deck_view() -> void:
	for child in removalDeckViewGrid.get_children():
		child.queue_free()
	
	var characterDeck = Database.build_run_deck(Database.standardCharacterDeck)
	var supportDeck = Database.build_run_deck(Database.standardSupportDeck)
	
	var groups := {}
	for cardKey in characterDeck:
		var faction = Database.CHARACTERS[cardKey][2]
		if not groups.has(faction):
			groups[faction] = []
		groups[faction].append(cardKey)
	
	var sortedFactions = groups.keys()
	sortedFactions.sort()
	
	const CARDS_PER_FRAME := 3
	var processedThisFrame := 0
	
	for faction in sortedFactions:
		groups[faction].sort()
		for key in groups[faction]:
			_add_removal_deck_view_card(key, true)
			processedThisFrame += 1
			if processedThisFrame >= CARDS_PER_FRAME:
				processedThisFrame = 0
				await get_tree().process_frame
	
	for key in supportDeck:
		_add_removal_deck_view_card(key, false)
		processedThisFrame += 1
		if processedThisFrame >= CARDS_PER_FRAME:
			processedThisFrame = 0
			await get_tree().process_frame


func _add_removal_deck_view_card(key: String, isCharacter: bool) -> void:
	var wrapper = Control.new()
	wrapper.custom_minimum_size = REMOVAL_VIEW_CARD_GRID_SPACE
	wrapper.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var card = load(REMOVAL_VIEW_CARD_SCENE_PATH).instantiate()
	card.cardKey = key
	
	if isCharacter and Database.CHARACTERS.has(key):
		var data = Database.CHARACTERS[key]
		card.value = data[0]
		card.type = data[1]
		card.faction = data[2]
		card.role = data[3]
		card.nameText = data[4]
		if data.size() > 5:
			card.perkDescription = data[5]
	elif not isCharacter and Database.SUPPORTS.has(key):
		var data = Database.SUPPORTS[key]
		card.value = data["Value"]
		card.type = data["Type"]
		card.nameText = data["CardText"]
		card.perkDescription = data["PerkText"]
		card.faction = "Support"
		if card.has_node("icons/faction"):
			card.get_node("icons/faction").hide()
	
	card.process_mode = Node.PROCESS_MODE_DISABLED
	card.scale = REMOVAL_VIEW_CARD_SCALE
	card.position = wrapper.custom_minimum_size / 2
	
	if card.has_node("Area2D"):
		card.get_node("Area2D").queue_free()
	if card.has_method("update_visuals"):
		card.update_visuals()
	
	if card is Control:
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	wrapper.add_child(card)
	removalDeckViewGrid.add_child(wrapper)

func _spawn_removal_card_visual(card: Dictionary) -> Node2D:
	var cardScene = load("res://core/cards/card.tscn")
	var newCard = cardScene.instantiate()
	
	newCard.cardKey = card.id
	newCard.canBePlayed = false
	
	if card.cardType == "Character":
		var data = Database.CHARACTERS[card.id]
		newCard.value = data[0]
		newCard.type = data[1]
		newCard.faction = data[2]
		newCard.role = data[3]
		newCard.nameText = data[4]
		if data.size() > 5:
			newCard.perkDescription = data[5]
	else:
		var data = Database.SUPPORTS[card.id]
		newCard.value = data["Value"]
		newCard.type = data["Type"]
		newCard.faction = "Support"
		newCard.role = ""
		newCard.nameText = data["CardText"]
		newCard.perkDescription = data["PerkText"]
	
	newCard.get_node("value").text = str(newCard.value)
	newCard.get_node("name").text = newCard.nameText
	newCard.get_node("imageBack").texture = load("res://core/cards/art/CardBackBlank.png")
	
	var iconsNode = newCard.get_node("icons")
	if newCard.faction != "Support":
		iconsNode.get_node("faction").texture = load("res://core/cards/icons/" + newCard.faction + ".png")
	
	var perkList = newCard.role.split("/") if newCard.role else []
	var activePerks = []
	for perk in perkList:
		if perk != "": activePerks.append(perk)
	
	var perkSprites = [iconsNode.get_node("perk1"), iconsNode.get_node("perk2")]
	
	if activePerks.is_empty():
		for sprite in perkSprites: sprite.visible = false
	else:
		for i in range(perkSprites.size()):
			if i < activePerks.size():
				perkSprites[i].visible = true
				perkSprites[i].texture = load("res://core/cards/icons/" + activePerks[i] + ".png")
			else:
				perkSprites[i].visible = false
	
	# Disable interaction before this ever gets a chance to hover/respond
	newCard.get_node("Area2D/CollisionShape2D").set_deferred("disabled", true)
	
	newCard.update_visuals()
	newCard.modulate.a = 0
	
	return newCard

func _reveal_removal_card(slot: Panel, card: Dictionary) -> void:
	var iconNode = slot.get_node("Slot")
	
	var cardVisual = _spawn_removal_card_visual(card)
	cardVisual.name = "CardVisual"
	cardVisual.position = Vector2(147.5, 200)
	cardVisual.scale = Vector2.ZERO
	
	slot.add_child(cardVisual)
	removalCardVisuals.append(cardVisual)
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(iconNode, "position", Vector2(97.5, 157), 0.3)
	tween.parallel().tween_property(iconNode, "modulate:a", 0, 0.6)
	tween.parallel().tween_property(cardVisual, "modulate:a", 1, 1)
	tween.parallel().tween_property(cardVisual, "scale", Vector2(1.6, 1.6), 1)
	
	await tween.finished
	
	iconNode.hide()

func _show_removal_deck() -> void:
	isAnimatingRemovalDeck = true
	AudioManager.play_move()
	
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property($RemovalContainer/DeckViewScroll, "position:x", 80, 0.3)
	tween.parallel().tween_property(opponentBox, "position:x", -750, 0.3)
	tween.parallel().tween_property($CurrentAllegiance, "position:x", -750, 0.3)
	
	if isModifierRound:
		tween.parallel().tween_property(modifierSlotOne, "position", Vector2(-750, 690), 0.3)
		tween.parallel().tween_property(modifierSlotTwo, "position", Vector2(-750, 690), 0.3)
		tween.parallel().tween_property(modifierSlotThree, "position", Vector2(-750, 690), 0.3)
	
	await tween.finished
	
	isShowingRemovalDeck = true
	isAnimatingRemovalDeck = false


func _hide_removal_deck(viewDeckOnly: bool = false) -> void:
	isAnimatingRemovalDeck = true
	AudioManager.play_move()
	
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property($RemovalContainer/DeckViewScroll, "position:x", -750, 0.3)
	if !viewDeckOnly:
		tween.parallel().tween_property(opponentBox, "position:x", 150, 0.3)
		tween.parallel().tween_property($CurrentAllegiance, "position:x", 150, 0.3)
		
		if isModifierRound:
			tween.parallel().tween_property(modifierSlotOne, "position", Vector2(150, 690), 0.3)
			tween.parallel().tween_property(modifierSlotTwo, "position", Vector2(315, 690), 0.3)
			tween.parallel().tween_property(modifierSlotThree, "position", Vector2(480, 690), 0.3)
	
	await tween.finished
	
	isShowingRemovalDeck = false
	isAnimatingRemovalDeck = false


func _hide_removal_buttons() -> void:
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	AudioManager.play_move()
	
	tween.tween_property($"RemovalContainer/Player Box", "position", Vector2(2200, 315), 0.3)
	tween.parallel().tween_property($"RemovalContainer/Reroll Button", "position", Vector2(2200, 501), 0.3)
	tween.parallel().tween_property($"RemovalContainer/View Deck Button", "position", Vector2(2200, 644), 0.3)
	
	
	await tween.finished

func _format_removal_health_text(value: int) -> String:
	return str(value) + " [img=20 color=#4c4c4c]res://holdout/arena/ui/HeartIcon.png[/img]"

func _get_removal_head_base_path() -> String:
	var data = Database.AVATARS[HoldoutStats.currentPlayer]
	return data["headPath"] + data["name"].get_slice(" ", 0)

func _update_removal_player_health(newValue: int, instant: bool = false) -> void:
	var healthLabel: RichTextLabel = $"RemovalContainer/Player Box/Health"
	var headSprite = $"RemovalContainer/Player Box/PlayerHead"
	var basePath = _get_removal_head_base_path()
	
	if instant or AccessibilityData.animationsDisabled:
		removalDisplayedHealth = newValue
		healthLabel.text = _format_removal_health_text(newValue)
		return
	
	var startValue = removalDisplayedHealth
	
	headSprite.texture = Database.get_avatar_head_texture(basePath + "Hurt.png")
	AudioManager.play_take_damage()
	
	var tween = create_tween()
	tween.tween_method(
		func(val: int): healthLabel.text = _format_removal_health_text(val),
		startValue,
		newValue,
		1.0
	)
	
	await tween.finished
	
	removalDisplayedHealth = newValue
	headSprite.texture = Database.get_avatar_head_texture(basePath + "Neutral.png")

func _get_removal_card_visual(slot: Panel) -> Node:
	if slot.has_node("CardVisual"):
		return slot.get_node("CardVisual")
	return null

func _show_removal_card_description(slot: Panel) -> void:
	var cardVisual = _get_removal_card_visual(slot)
	if cardVisual == null:
		return
	
	var animationPlayer = cardVisual.get_node("AnimationPlayer")
	if animationPlayer == null or not animationPlayer.has_animation("showPerkDescription"):
		return
	
	animationPlayer.play("showPerkDescription")

func _hide_removal_card_description(slot: Panel) -> void:
	var cardVisual = _get_removal_card_visual(slot)
	if cardVisual == null:
		return
	
	var animationPlayer = cardVisual.get_node("AnimationPlayer")
	if animationPlayer == null or not animationPlayer.has_animation("showPerkDescription"):
		return
	
	animationPlayer.play_backwards("showPerkDescription")

func _on_removal_1_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and allowRemovalSelections:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_toggle_removal_slot(0, removalSlotOne)

func _on_removal_1_mouse_entered() -> void:
	if !allowRemovalSelections:
		return
	var tween = create_tween()
	tween.tween_property(removalSlotOne, "scale", Vector2(1.05, 1.05), 0.1)
	AudioManager.play_card_hover()
	_show_removal_card_description(removalSlotOne)

func _on_removal_1_mouse_exited() -> void:
	if !allowRemovalSelections:
		return
	var tween = create_tween()
	tween.tween_property(removalSlotOne, "scale", Vector2(1, 1), 0.1)
	AudioManager.play_card_hover()
	_hide_removal_card_description(removalSlotOne)

func _on_removal_2_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and allowRemovalSelections:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_toggle_removal_slot(1, removalSlotTwo)

func _on_removal_2_mouse_entered() -> void:
	if !allowRemovalSelections:
		return
	var tween = create_tween()
	tween.tween_property(removalSlotTwo, "scale", Vector2(1.05, 1.05), 0.1)
	AudioManager.play_card_hover()
	_show_removal_card_description(removalSlotTwo)

func _on_removal_2_mouse_exited() -> void:
	if !allowRemovalSelections:
		return
	var tween = create_tween()
	tween.tween_property(removalSlotTwo, "scale", Vector2(1, 1), 0.1)
	AudioManager.play_card_hover()
	_hide_removal_card_description(removalSlotTwo)

func _on_removal_3_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and allowRemovalSelections:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_toggle_removal_slot(2, removalSlotThree)

func _on_removal_3_mouse_entered() -> void:
	if !allowRemovalSelections:
		return
	var tween = create_tween()
	tween.tween_property(removalSlotThree, "scale", Vector2(1.05, 1.05), 0.1)
	AudioManager.play_card_hover()
	_show_removal_card_description(removalSlotThree)

func _on_removal_3_mouse_exited() -> void:
	if !allowRemovalSelections:
		return
	var tween = create_tween()
	tween.tween_property(removalSlotThree, "scale", Vector2(1, 1), 0.1)
	AudioManager.play_card_hover()
	_hide_removal_card_description(removalSlotThree)

func _toggle_removal_slot(index: int, slot: Panel) -> void:
	if removalSlotsActive[index] == 1:
		removalSlotsActive[index] = 0
		slot.get_node("Selected").visible = false
		
		var currentStyleBox = slot.get_theme_stylebox("panel").duplicate()
		currentStyleBox.bg_color = Color("151515")
		slot.add_theme_stylebox_override("panel", currentStyleBox)
	else:
		removalSlotsActive[index] = 1
		slot.get_node("Selected").visible = true
		
		var currentStyleBox = slot.get_theme_stylebox("panel").duplicate()
		currentStyleBox.bg_color = Color("383838")
		slot.add_theme_stylebox_override("panel", currentStyleBox)
	
	var totalSelected = removalSlotsActive.reduce(func(accumulator, number): return accumulator + number, 0)
	$NumberSelected.text = str(totalSelected) + "/3 Selected"

func _hide_removal_container() -> void:
	AudioManager.play_move()
	
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.parallel().tween_property(removalSlotOne, "position:y", -750.0, 0.3)
	
	tween.parallel().tween_callback(AudioManager.play_move).set_delay(0.1)
	tween.parallel().tween_property(removalSlotTwo, "position:y", -750.0, 0.3).set_delay(0.1)
	
	tween.parallel().tween_callback(AudioManager.play_move).set_delay(0.2)
	tween.parallel().tween_property(removalSlotThree, "position:y", -750.0, 0.3).set_delay(0.2)
	
	await tween.finished


func _on_reroll_button_pressed() -> void:
	if isRerollingRemoval:
		$"RemovalContainer/Reroll Button".release_focus()
		$"RemovalContainer/Reroll Button".button_pressed = false
		return
		
	if HoldoutStats.playerHealthValue <= REROLL_MIN_HEALTH:
		$"RemovalContainer/Reroll Button".release_focus()
		$"RemovalContainer/Reroll Button".button_pressed = false
		_play_denied_animation($"RemovalContainer/Reroll Button")
		return
	
	allowRemovalSelections = false
	isRerollingRemoval = true
	$"RemovalContainer/Reroll Button".release_focus()
	$"RemovalContainer/Reroll Button".button_pressed = false
	
	
	%arena.update_health(Actor.Type.PLAYER, %arena.get_health(Actor.Type.PLAYER) - REROLL_HEALTH_COST)
	#HoldoutStats.playerHealthValue -= REROLL_HEALTH_COST
	await _update_removal_player_health(HoldoutStats.playerHealthValue)
	
	
	$"RemovalContainer/Reroll Button".mouse_filter = Control.MOUSE_FILTER_IGNORE
	removalSlotOne.mouse_filter = Control.MOUSE_FILTER_IGNORE
	removalSlotTwo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	removalSlotThree.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	$Heading.modulate.a = 0
	$Subheading.modulate.a = 0
	$NumberSelected.modulate.a = 0
	$ConfirmButton.hide()
	$ConfirmButton.modulate.a = 0
	
	_hide_removal_buttons()
	await _reset_removal_slots_for_reroll()
	
	_select_removal_cards()
	
	await _animate_removal_container_one_variant(true)
	
	await get_tree().create_timer(0.5).timeout
	
	await _animate_removal_container_two()
	
	_animate_removal_container_three()
	
	$"RemovalContainer/Reroll Button".mouse_filter = Control.MOUSE_FILTER_STOP
	
	isRerollingRemoval = false
	allowRemovalSelections = true
	
	$Heading.text = "REMOVE A CARD?"
	$Subheading.text = "Select any number of cards."
	$NumberSelected.text = "0/3 Selected"
	$NumberSelected.position = Vector2(1375, 750)
	var headingTween = create_tween()
	headingTween.tween_property($Heading, "modulate:a", 1, 1)
	headingTween.parallel().tween_property($Subheading, "modulate:a", 1, 1)
	headingTween.parallel().tween_property($NumberSelected, "modulate:a", 1, 1)
	
	$ConfirmButton.text = "CONFIRM"
	$ConfirmButton.position = Vector2((get_viewport_rect().size.x - $ConfirmButton.size.x) / 2, 850)
	$ConfirmButton.show()
	var confirmButtonTween = create_tween()
	confirmButtonTween.tween_property($ConfirmButton, "modulate:a", 1, 1)

func _on_reroll_button_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property($"RemovalContainer/Reroll Button", "scale", Vector2(1.05, 1.05), 0.1)
	AudioManager.play_card_hover()

func _on_reroll_button_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property($"RemovalContainer/Reroll Button", "scale", Vector2(1, 1), 0.1)
	AudioManager.play_card_hover()

func _reset_removal_slots_for_reroll() -> void:
	removalSlotsActive = [0, 0, 0]
	allowRemovalSelections = false
	$NumberSelected.text = "0/3 Selected"
	
	for visual in removalCardVisuals:
		if is_instance_valid(visual):
			visual.free()
	removalCardVisuals.clear()
	await get_tree().process_frame
	
	for slot in [removalSlotOne, removalSlotTwo, removalSlotThree]:
		var iconNode = slot.get_node("Slot")
		iconNode.show()
		iconNode.modulate.a = 1
		iconNode.scale = Vector2(1, 1)
		iconNode.position = Vector2(40, 40)
		
		slot.get_node("Selected").hide()
		
		var currentStyleBox = slot.get_theme_stylebox("panel").duplicate()
		currentStyleBox.bg_color = Color("151515")
		slot.add_theme_stylebox_override("panel", currentStyleBox)
		
		slot.modulate.a = 1
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(removalSlotOne, "size", Vector2(180, 180), 0.15)
	tween.parallel().tween_property(removalSlotOne, "position", Vector2(730, 450), 0.15)
	tween.parallel().tween_property(removalSlotTwo, "size", Vector2(180, 180), 0.15)
	tween.parallel().tween_property(removalSlotTwo, "position", Vector2(1130, 450), 0.15)
	tween.parallel().tween_property(removalSlotThree, "size", Vector2(180, 180), 0.15)
	tween.parallel().tween_property(removalSlotThree, "position", Vector2(1530, 450), 0.15)
	
	await tween.finished


func _on_view_deck_button_pressed() -> void:
	$"RemovalContainer/View Deck Button".release_focus()
	$"RemovalContainer/View Deck Button".button_pressed = false
	
	if isAnimatingRemovalDeck:
		return
	
	if isShowingRemovalDeck:
		$"RemovalContainer/View Deck Button/Text".text = "View Decks"
		await _hide_removal_deck()
	else:
		$"RemovalContainer/View Deck Button/Text".text = "View Opponent"
		await _show_removal_deck()

func _on_view_deck_button_mouse_entered() -> void:
	if isAnimatingRemovalDeck:
		return
		
	var tween = create_tween()
	tween.tween_property($"RemovalContainer/View Deck Button", "scale", Vector2(1.05, 1.05), 0.1)
	AudioManager.play_card_hover()

func _on_view_deck_button_mouse_exited() -> void:
	if isAnimatingRemovalDeck:
		return
		
	var tween = create_tween()
	tween.tween_property($"RemovalContainer/View Deck Button", "scale", Vector2(1, 1), 0.1)
	AudioManager.play_card_hover()


func _on_confirm_button_pressed() -> void:
	# Just an opponent round
	if !isModifierRound and !isAllegianceRound and !isCardRemovalRound:
		await hide_hub()
		self.hide()
	
	if isModifierRound:
		# We only hide it if something doesnt come after
		if !isAllegianceRound and !isCardRemovalRound:
			# And only if we have something selected
			if modifierSlotsActive.reduce(func(accumulator, number): return accumulator + number, 0) > 0:
				await hide_hub()
				self.hide()
				return
			else:
				_play_denied_animation($ConfirmButton)
		else:
			# This is if there are 3 choices in a round
			if isAllegianceRound:
				if !modifierSelected:
					if modifierSlotsActive.reduce(func(accumulator, number): return accumulator + number, 0) > 0:
						modifierSelected = true
						_play_allegiance_after_modifier_sequence()
						return
					else:
						_play_denied_animation($ConfirmButton)
				else:
					if selectedAllegianceIndex != -1:
						await hide_hub()
						self.hide()
						return
					else:
						_play_denied_animation($ConfirmButton)
			
			elif isCardRemovalRound:
				if !modifierSelected:
					if modifierSlotsActive.reduce(func(accumulator, number): return accumulator + number, 0) > 0:
						modifierSelected = true
						_play_removal_after_modifier_sequence()
						return
					else:
						_play_denied_animation($ConfirmButton)
				else:
					_apply_selected_removals()
					await hide_hub()
					self.hide()
					return
	
	if isAllegianceRound and !isModifierRound:
		if selectedAllegianceIndex != -1:
			await hide_hub()
			self.hide()
			return
		else:
			_play_denied_animation($ConfirmButton)
	
	if isCardRemovalRound and !isModifierRound:
		_apply_selected_removals()
		await hide_hub()
		self.hide()
		return
	
	$ConfirmButton.release_focus()

func _on_confirm_button_mouse_entered() -> void:
	AudioManager.play_button_hover()

func _play_denied_animation(currentButton: Button):
	var originalPos = currentButton.position.x
	var shake_offset = 5.0
	var duration = 0.05
	
	var tween = create_tween()
	tween.tween_property(currentButton, "position:x", originalPos + shake_offset, duration)
	tween.tween_property(currentButton, "position:x", originalPos - shake_offset, duration)
	tween.tween_property(currentButton, "position:x", originalPos, duration)


func _play_allegiance_after_modifier_sequence() -> void:
	$NumberSelected.modulate.a = 0
	$Heading.modulate.a = 0
	$Subheading.modulate.a = 0
	$ConfirmButton.modulate.a = 0
	
	_animate_opponent_container_four()
	await _animate_modifier_container_three()
	
	await get_tree().create_timer(0.5).timeout
	
	await _animate_allegiance_container_one_variant()
	
	await get_tree().create_timer(1).timeout
	
	_animate_allegiance_container_two()
	
	await get_tree().create_timer(0.75).timeout
	
	$Heading.text = "PICK AN ALLEGIANCE"
	$Subheading.text = "You must select only one."
	$NumberSelected.text = "0/1 Selected"
	var headingTween = create_tween()
	headingTween.tween_property($Heading, "modulate:a", 1, 1)
	headingTween.parallel().tween_property($Subheading, "modulate:a", 1, 1)
	headingTween.parallel().tween_property($NumberSelected, "modulate:a", 1, 1)
	
	$ConfirmButton.text = "CONFIRM"
	$ConfirmButton.position = Vector2((get_viewport_rect().size.x - $ConfirmButton.size.x) / 2, 850)
	$ConfirmButton.show()
	var confirmButtonTween = create_tween()
	confirmButtonTween.tween_property($ConfirmButton, "modulate:a", 1, 1)

func _play_removal_after_modifier_sequence() -> void:
	$NumberSelected.modulate.a = 0
	$Heading.modulate.a = 0
	$Subheading.modulate.a = 0
	$ConfirmButton.modulate.a = 0
	
	_animate_opponent_container_four()
	await _animate_modifier_container_three()
	
	await get_tree().create_timer(0.5).timeout
	
	await _animate_removal_container_one_variant()
	
	await get_tree().create_timer(1).timeout
	
	await _animate_removal_container_two()
	
	_animate_removal_container_three()
	
	$Heading.text = "REMOVE A CARD?"
	$Subheading.text = "Select any number of cards."
	$NumberSelected.text = "0/3 Selected"
	$NumberSelected.position = Vector2(1375, 750)
	var headingTween = create_tween()
	headingTween.tween_property($Heading, "modulate:a", 1, 1)
	headingTween.parallel().tween_property($Subheading, "modulate:a", 1, 1)
	headingTween.parallel().tween_property($NumberSelected, "modulate:a", 1, 1)
	
	$ConfirmButton.text = "CONFIRM"
	$ConfirmButton.position = Vector2((get_viewport_rect().size.x - $ConfirmButton.size.x) / 2, 850)
	$ConfirmButton.show()
	var confirmButtonTween = create_tween()
	confirmButtonTween.tween_property($ConfirmButton, "modulate:a", 1, 1)
