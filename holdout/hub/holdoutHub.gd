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

const ALLEGIANCE_FACTIONS = ["Firefly", "Infected", "Jackson", "Seraphite", "WLF"]

@onready var fungusSlotOne: Control = $"AllegianceContainer/Fungus A1"
@onready var fungusSlotTwo: Control = $"AllegianceContainer/Fungus A2"
@onready var fungusSlotThree: Control = $"AllegianceContainer/Fungus A3"

const FACTION_FUNGUS_COLORS = {
	"Firefly": ["C2A23E", "9D7F2E", "4F4119"],
	"Infected": ["CD6429", "96371F", "6F2214"],
	"Jackson": ["546E32", "3D4F23", "29331B"],
	"Seraphite": ["8657A3", "724099", "4B2B74"],
	"WLF": ["81B0DE", "4A89C8", "185799"],
}

# Flags
var isModifierRound: bool = false
var isCardRemovalRound: bool = false
var isAllegianceRound: bool = false

# Hub
func _setup_hub() -> void:
	_reset_internal_data()
	_setup_round_flags()
	
	$Overlay.modulate.a = 1
	$Heading.modulate.a = 0
	$Subheading.modulate.a = 0
	$NumberSelected.modulate.a = 0
	$NumberSelected.text = "0/3 Selected"
	$ConfirmButton.text = "START BATTLE"
	$ConfirmButton.hide()
	$ConfirmButton.modulate.a = 0
	
	_setup_opponent_container()
	_setup_modifier_container()
	_setup_allegiance_container()
	
	# Hide everything else
	modifierContainer.hide()
	allegianceContainer.hide()
	%currentAllegiance.modulate.a = 0
	
	self.show()

func _setup_round_flags() -> void:
	if (HoldoutStats.numberOfWins + 1) % 2 == 0: # Even round
		isModifierRound = true
	
	isAllegianceRound = _is_allegiance_round(HoldoutStats.numberOfWins + 1)

func _is_allegiance_round(roundNumber: int) -> bool:
	if roundNumber == 1:
		return true
	
	if (roundNumber + 6) % 5 == 0:
		@warning_ignore("integer_division")
		return int((roundNumber + 6) / 5) >= 2
	
	return false

func show_hub() -> void:
	if HoldoutStats.replayedRound:
		GameStats.gameMode = GameStats.Mode.HOLDOUT
		%battleManager.initialize_game()
		return
		
	_setup_hub()
	
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
	
	_hide_opponent_container()
	
	if isModifierRound:
		_hide_modifier_container()
	
	if isAllegianceRound:
		_hide_allegiance_container()
	
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
	GameStats.record_modifier_selection(selectedOpponentModifier.name)
	
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
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_select_allegiance_slot(0)

func _on_allegiance_2_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_select_allegiance_slot(1)

func _on_allegiance_3_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_select_allegiance_slot(2)

func _on_allegiance_1_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(allegianceSlotOne, "scale", Vector2(1.05, 1.05), 0.1)
	tween.parallel().tween_property(fungusSlotOne.get_node("1"), "scale", Vector2(1.05, 1.05), 0.1)
	tween.parallel().tween_property(fungusSlotOne.get_node("2"), "scale", Vector2(1.05, 1.05), 0.1)
	tween.parallel().tween_property(fungusSlotOne.get_node("3"), "scale", Vector2(1.05, 1.05), 0.1)
	AudioManager.play_card_hover()

func _on_allegiance_1_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(allegianceSlotOne, "scale", Vector2(1, 1), 0.1)
	tween.parallel().tween_property(fungusSlotOne.get_node("1"), "scale", Vector2(1, 1), 0.1)
	tween.parallel().tween_property(fungusSlotOne.get_node("2"), "scale", Vector2(1, 1), 0.1)
	tween.parallel().tween_property(fungusSlotOne.get_node("3"), "scale", Vector2(1, 1), 0.1)
	AudioManager.play_card_hover()

func _on_allegiance_2_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(allegianceSlotTwo, "scale", Vector2(1.05, 1.05), 0.1)
	tween.parallel().tween_property(fungusSlotTwo.get_node("1"), "scale", Vector2(1.05, 1.05), 0.1)
	tween.parallel().tween_property(fungusSlotTwo.get_node("2"), "scale", Vector2(1.05, 1.05), 0.1)
	tween.parallel().tween_property(fungusSlotTwo.get_node("3"), "scale", Vector2(1.05, 1.05), 0.1)
	AudioManager.play_card_hover()

func _on_allegiance_2_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(allegianceSlotTwo, "scale", Vector2(1, 1), 0.1)
	tween.parallel().tween_property(fungusSlotTwo.get_node("1"), "scale", Vector2(1, 1), 0.1)
	tween.parallel().tween_property(fungusSlotTwo.get_node("2"), "scale", Vector2(1, 1), 0.1)
	tween.parallel().tween_property(fungusSlotTwo.get_node("3"), "scale", Vector2(1, 1), 0.1)
	AudioManager.play_card_hover()

func _on_allegiance_3_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(allegianceSlotThree, "scale", Vector2(1.05, 1.05), 0.1)
	tween.parallel().tween_property(fungusSlotThree.get_node("1"), "scale", Vector2(1.05, 1.05), 0.1)
	tween.parallel().tween_property(fungusSlotThree.get_node("2"), "scale", Vector2(1.05, 1.05), 0.1)
	tween.parallel().tween_property(fungusSlotThree.get_node("3"), "scale", Vector2(1.05, 1.05), 0.1)
	AudioManager.play_card_hover()

func _on_allegiance_3_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(allegianceSlotThree, "scale", Vector2(1, 1), 0.1)
	tween.parallel().tween_property(fungusSlotThree.get_node("1"), "scale", Vector2(1, 1), 0.1)
	tween.parallel().tween_property(fungusSlotThree.get_node("2"), "scale", Vector2(1, 1), 0.1)
	tween.parallel().tween_property(fungusSlotThree.get_node("3"), "scale", Vector2(1, 1), 0.1)
	AudioManager.play_card_hover()

func _hide_allegiance_container() -> void:
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
				pass
	
	if isAllegianceRound and !isModifierRound:
		if selectedAllegianceIndex != -1:
			await hide_hub()
			self.hide()
			return
		else:
			_play_denied_animation($ConfirmButton)
	
	# Over here would be a check if its a card removal and not a modifier round
	
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
