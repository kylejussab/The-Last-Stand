extends Node2D

signal hoverEntered(card)
signal hoverExited(card)

var CARD_TEXT_SIZE = 16
var DESCRIPTION_TEXT_SIZE = 10
var DESCRIPTION_ICON_SIZE = 12
var PERK_ICON_SCALE = 0.095
var FACTION_ICON_SCALE = 0.12
var PERK_ICON_ONE_Y_POSITION = -66
var PERK_ICON_TWO_Y_POSITION = -43.5
var PERK_LINE_Y_SIZE = 15

const KEYWORD_ICONS = {
	"Aggressive": "res://assets/cardIcons/Aggressive.png",
	"Defensive": "res://assets/cardIcons/Defensive.png",
	"Stealthy": "res://assets/cardIcons/Stealthy.png",
	"Survivor": "res://assets/cardIcons/Survivor.png",
	"Crafty": "res://assets/cardIcons/Crafty.png",
	"Seraphite": "res://assets/cardIcons/colorFaction/Seraphite.png",
	"WLF": "res://assets/cardIcons/colorFaction/WLF.png",
	"Firefly": "res://assets/cardIcons/colorFaction/Firefly.png",
	"Jackson": "res://assets/cardIcons/colorFaction/Jackson.png",
	"Infected": "res://assets/cardIcons/colorFaction/Infected.png"
}

var cardSlot
var cardKey: String
var nameText: String
var type
var value: int
var role: String
var faction: String
var perk
var perkValueAtRoundEnd
var canBePlayed: bool
var perkDescription: String

var handPosition: Vector2

#@onready var soundPlayer = $AudioStreamPlayer2D
#
#@export var drawSounds = [
	#preload("res://assets/sounds/cards/deal_1.wav"),
	#preload("res://assets/sounds/cards/deal_2.wav"),
	#preload("res://assets/sounds/cards/deal_3.wav"),
	#preload("res://assets/sounds/cards/deal_4.wav"),
	#preload("res://assets/sounds/cards/deal_5.wav"),
	#preload("res://assets/sounds/cards/deal_6.wav"),
	#preload("res://assets/sounds/cards/deal_7.wav")
#]

func _ready() -> void:
	if get_parent().has_method("connect_card_signals"):
		get_parent().connect_card_signals(self)

func update_visuals():
	_apply_accessibility_settings()
	_apply_visibility_settings()
	
	if has_node("value"):
		$value.text = str(value)
		$value.add_theme_font_size_override("normal_font_size", CARD_TEXT_SIZE)
	if has_node("name"):
		$name.text = nameText
		$name.add_theme_font_size_override("normal_font_size", CARD_TEXT_SIZE)
	if has_node("perk"):
		$perk.add_theme_font_size_override("normal_font_size", CARD_TEXT_SIZE)
	
	if has_node("hoverDescription/text"):
		if perkDescription != "":
			var formatted_text = _format_perk_text(perkDescription)
			$hoverDescription/text.text = formatted_text
			$hoverDescription/text.add_theme_font_size_override("normal_font_size", DESCRIPTION_TEXT_SIZE)
		else:
			$hoverDescription/text.text = ""
	
	if has_node("icons"):
		var perkOne = $icons.get_node("perk1")
		var perkTwo = $icons.get_node("perk2")
		
		perkOne.scale = Vector2(PERK_ICON_SCALE, PERK_ICON_SCALE)
		perkOne.position = Vector2(-58.5, PERK_ICON_ONE_Y_POSITION)
		
		perkTwo.scale = Vector2(PERK_ICON_SCALE, PERK_ICON_SCALE)
		perkTwo.position = Vector2(-58.5, PERK_ICON_TWO_Y_POSITION)
		
		if $icons.has_node("faction"):
			$icons.get_node("faction").scale = Vector2(FACTION_ICON_SCALE, FACTION_ICON_SCALE)
			
			if faction in KEYWORD_ICONS:
				$icons.get_node("faction").texture = load("res://assets/cardIcons/" + faction + ".png")
		
		if role != null and role != "":
			var roles = role.split("/")
			
			if roles.size() > 0 and roles.size() <= 2:
				if roles[0] in KEYWORD_ICONS:
					perkOne.texture = load(KEYWORD_ICONS[roles[0]])
					perkOne.visible = true
				
				if roles.size() > 1 and roles[1] in KEYWORD_ICONS:
					perkTwo.texture = load(KEYWORD_ICONS[roles[1]])
					perkTwo.visible = true
				else:
					perkTwo.visible = false
			else:
				perkOne.visible = false
				perkTwo.visible = false
	
	if has_node("line"):
		$line.size.y = PERK_LINE_Y_SIZE
		
	_update_art_style()

func _apply_accessibility_settings():
	match AccessibilityData.currentCardUISize:
		AccessibilityData.CardUISize.SMALL:
			CARD_TEXT_SIZE = 16
			DESCRIPTION_TEXT_SIZE = 10
			DESCRIPTION_ICON_SIZE = 12
			PERK_ICON_SCALE = 0.095
			PERK_ICON_ONE_Y_POSITION = -66
			PERK_ICON_TWO_Y_POSITION = -43.5
			FACTION_ICON_SCALE = 0.12
			PERK_LINE_Y_SIZE = 15
		AccessibilityData.CardUISize.MEDIUM:
			CARD_TEXT_SIZE = 20
			DESCRIPTION_TEXT_SIZE = 12
			DESCRIPTION_ICON_SIZE = 14
			PERK_ICON_SCALE = 0.117
			PERK_ICON_ONE_Y_POSITION = -61
			PERK_ICON_TWO_Y_POSITION = -33.5
			FACTION_ICON_SCALE = 0.145
			PERK_LINE_Y_SIZE = 17.5
		AccessibilityData.CardUISize.LARGE:
			CARD_TEXT_SIZE = 24
			DESCRIPTION_TEXT_SIZE = 14
			DESCRIPTION_ICON_SIZE = 16
			PERK_ICON_SCALE = 0.15
			PERK_ICON_ONE_Y_POSITION = -56
			PERK_ICON_TWO_Y_POSITION = -28.5
			FACTION_ICON_SCALE = 0.17
			PERK_LINE_Y_SIZE = 20

func _apply_visibility_settings():
	if has_node("name"): $name.visible = true
	if faction != "Support": $icons/faction.visible = true
	
	if AccessibilityData.currentCardStyle == AccessibilityData.CardStyle.MINIMAL:
		if has_node("name"): $name.visible = false
		if has_node("icons/faction"): $icons/faction.visible = false

func _update_art_style():
	if not has_node("image"): return
	
	match AccessibilityData.currentCardStyle:
		AccessibilityData.CardStyle.MINIMAL:
			$image.texture = load("res://assets/cards/" + cardKey + "Card.png")
		AccessibilityData.CardStyle.NO_ARTWORK:
			if faction != "":
				$image.texture = load("res://assets/cards/" + faction + ".png")
			else:
				$image.texture = load("res://assets/cards/Support.png")
		_:
			$image.texture = load("res://assets/cards/" + cardKey + "Card.png")

func _format_perk_text(rawText: String) -> String:
	var richText = rawText
	for keyword in KEYWORD_ICONS:
		if keyword in richText:
			var iconPath = KEYWORD_ICONS[keyword]
			var replacement = "[img height=%d]%s[/img]" % [DESCRIPTION_ICON_SIZE, iconPath]
			richText = richText.replace(keyword, replacement)
	return richText

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hoverEntered", self)

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hoverExited", self)

#func play_draw_sound():
	#var randomSound = drawSounds.pick_random()
	#soundPlayer.stream = randomSound
	#soundPlayer.play()

func disable_interaction() -> void:
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
	
	scale = Vector2(1, 1)
	
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play_backwards("showPerkDescription")
		$AnimationPlayer.seek(0, true)

func modify_value(amount: int) -> void:
	value += amount
	
	if not get_node("AnimationPlayer").animation_started.is_connected(_when_animation_starts):
		get_node("AnimationPlayer").animation_started.connect(_when_animation_starts)
	
	var stringSign = "+" if amount >= 0 else "" 
	
	get_node("perk").text = stringSign + str(amount)
	get_node("AnimationPlayer").queue("showPerk")

func _when_animation_starts(animationName: String):
	if animationName == "showPerk":
		_updateCardValue()

func _updateCardValue():
	var label = get_node("value")
	var startValue = int(label.text)
	
	var tween = create_tween()
	
	tween.tween_method(
		func(val: int): label.text = str(val),
		startValue,
		value,
		0.5
	)
