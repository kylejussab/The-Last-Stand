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
	"Aggressive": "res://core/cards/icons/Aggressive.png",
	"Defensive": "res://core/cards/icons/Defensive.png",
	"Stealthy": "res://core/cards/icons/Stealthy.png",
	"Survivor": "res://core/cards/icons/Survivor.png",
	"Crafty": "res://core/cards/icons/Crafty.png",
	"Seraphite": "res://core/cards/icons/color/Seraphite.png",
	"WLF": "res://core/cards/icons/color/WLF.png",
	"Firefly": "res://core/cards/icons/color/Firefly.png",
	"Jackson": "res://core/cards/icons/color/Jackson.png",
	"Infected": "res://core/cards/icons/color/Infected.png",
	"Smuggler": "res://core/cards/icons/color/Smuggler.png"
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
var perkValueAppliedMidRound: int = 0
var isNullified: bool = false
var parity: String

var handPosition: Vector2

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
				$icons.get_node("faction").texture = load(_get_card_icon_path(faction))
		
		if role != null and role != "":
			var roles = role.split("/")
			
			if roles.size() > 0 and roles.size() <= 2:
				if roles[0] in KEYWORD_ICONS:
					perkOne.texture = load(_get_card_icon_path(roles[0]))
					perkOne.visible = true
				
				if roles.size() > 1 and roles[1] in KEYWORD_ICONS:
					perkTwo.texture = load(_get_card_icon_path(roles[1]))
					perkTwo.visible = true
				else:
					perkTwo.visible = false
			else:
				perkOne.visible = false
				perkTwo.visible = false
		else:
			perkOne.visible = false
			perkTwo.visible = false
	
	if type == "Character":
		_populate_character_tooltip()
	
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
	
	if has_node("icons/faction"):
		if faction != "Support": 
			$icons/faction.visible = true
		else:
			$icons/faction.visible = false

func _update_art_style():
	if not has_node("image"): return
	
	var premiumPath = ""
	var fallbackPath = ""
	var safeFaction = faction if faction != "" else "Support"
	
	match AccessibilityData.currentCardStyle:
		AccessibilityData.CardStyle.STENCIL:
			premiumPath = "res://core/cards/art/premium/stencil/" + cardKey + "Card.png"
			fallbackPath = "res://core/cards/art/" + safeFaction + "Stencil.png"
		
		AccessibilityData.CardStyle.DEFAULT, _:
			premiumPath = "res://core/cards/art/premium/" + cardKey + "Card.png"
			fallbackPath = "res://core/cards/art/" + safeFaction + ".png"
		
	if ResourceLoader.exists(premiumPath):
		$image.texture = load(premiumPath)
	else:
		$image.texture = load(fallbackPath)
	
	var targetColor = Color.WHITE
	
	if faction != "Support" and AccessibilityData.currentCardStyle == AccessibilityData.CardStyle.STENCIL:
		targetColor = Color("#353535")
		
	$name.add_theme_color_override("default_color", targetColor)
	$value.add_theme_color_override("default_color", targetColor)
	$perk.add_theme_color_override("default_color", targetColor)
	$line.color = targetColor

func _format_perk_text(rawText: String) -> String:
	var richText = rawText
	for keyword in KEYWORD_ICONS:
		if keyword in richText:
			var iconPath = _get_description_icon_path(keyword)
			var replacement = "[img height=%d]%s[/img]" % [DESCRIPTION_ICON_SIZE, iconPath]
			richText = richText.replace(keyword, replacement)
	return richText

func _apply_va_suffix(basePath: String) -> String:
	if AccessibilityData.useVisualAssistIcons:
		return basePath.replace(".png", "_VA.png")
	return basePath

func _get_description_icon_path(keyword: String) -> String:
	if not keyword in KEYWORD_ICONS:
		return ""
		
	var basePath = KEYWORD_ICONS[keyword]
	
	if AccessibilityData.currentCardStyle == AccessibilityData.CardStyle.STENCIL:
		if "/color/" in KEYWORD_ICONS[keyword]: # Use white icons for factions (better contrast)
			basePath = "res://core/cards/icons/" + keyword + ".png"
		else:
			basePath = "res://core/cards/icons/stencil/" + keyword + ".png"
		
	return _apply_va_suffix(basePath)

func _get_card_icon_path(iconName: String) -> String:
	var basePath = "res://core/cards/icons/"
	
	if AccessibilityData.currentCardStyle == AccessibilityData.CardStyle.STENCIL:
		basePath += "stencil/"
		
	basePath += iconName + ".png"
	
	return _apply_va_suffix(basePath)

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hoverEntered", self)

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hoverExited", self)

func disable_interaction() -> void:
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
	
	scale = Vector2(1, 1)
	
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play_backwards("showPerkDescription")
		$AnimationPlayer.seek(0, true)

func modify_value(amount: int) -> void:
	if amount == 0:
		return
	
	value += amount
	
	var animationPlayer = get_node("AnimationPlayer")
	
	if not animationPlayer.animation_started.is_connected(_when_animation_starts):
		animationPlayer.animation_started.connect(_when_animation_starts)
	
	var stringSign = "+" if amount >= 0 else "" 
	
	get_node("perk").text = stringSign + str(amount)
	
	if animationPlayer.is_playing():
		animationPlayer.queue("showPerk")
	else:
		animationPlayer.play("showPerk")

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

# Tooltips
func _populate_character_tooltip():
	if not has_node("CharacterTooltip"):
		return
	
	var tooltip = $CharacterTooltip
	if not tooltip.has_node("VBoxContainer/Type Grid Container"):
		return
	
	var typeGrid = tooltip.get_node("VBoxContainer/Type Grid Container")
	var type1Container = typeGrid.get_node("Type 1 Container")
	var type1Icon = type1Container.get_node("TextureRect")
	var type1Text = typeGrid.get_node("Type 1 Text")
	
	var type2Container = typeGrid.get_node("Type 2 Container")
	var type2Icon = type2Container.get_node("TextureRect")
	var type2Text = typeGrid.get_node("Type 2 Text")
	
	var roles = []
	if role != null and role != "":
		roles = role.split("/")
	
	if roles.size() > 0 and roles[0] in KEYWORD_ICONS:
		type1Icon.texture = load(_get_card_icon_path(roles[0]))
		type1Text.text = roles[0]
		type1Container.visible = true
		type1Text.visible = true
	else:
		type1Container.visible = false
		type1Text.visible = false
	
	if roles.size() > 1 and roles[1] in KEYWORD_ICONS:
		type2Icon.texture = load(_get_card_icon_path(roles[1]))
		type2Text.text = roles[1]
		type2Container.visible = true
		type2Text.visible = true
	else:
		type2Container.visible = false
		type2Text.visible = false
	
	if tooltip.has_node("VBoxContainer/Faction Grid Container"):
		var factionGrid = tooltip.get_node("VBoxContainer/Faction Grid Container")
		var factionContainer = factionGrid.get_node("Faction Container")
		var factionIcon = factionContainer.get_node("TextureRect")
		var factionText = factionGrid.get_node("Faction Text")
		
		if faction != "" and faction in KEYWORD_ICONS:
			factionIcon.texture = load(_get_card_icon_path(faction))
			factionText.text = faction
