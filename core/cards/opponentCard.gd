extends Node2D

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
	"Infected": "res://core/cards/icons/color/Infected.png"
}

signal hoverEntered(card)
signal hoverExited(card)

var cardSlot: Node2D
var cardKey: String
var nameText: String
var type
var handPosition: Vector2
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
var gotInfected: bool = false
var permanentInfection: bool = false
var frenzyBonusApplied: bool = false
var splitAllegianceBonusApplied: bool = false
var isDoctrineBackfired: bool = false

var originalFaction: String = ""

var _activeGuardedAnimations: int = 0
var _preAnimationCollisionState: bool = false
const GUARDED_ANIMATIONS = ["modifierIndicator", "cardFlip", "backfire", "lock"]

func _ready() -> void:
	if get_parent().has_method("connect_card_signals"):
		get_parent().connect_card_signals(self)
	
	if has_node("AnimationPlayer"):
		$AnimationPlayer.animation_started.connect(_on_any_animation_started)
		$AnimationPlayer.animation_finished.connect(_on_any_animation_finished)
	
	if has_node("image") and has_node("infectedImage"):
		$image.visibility_changed.connect(_on_image_visibility_changed)
		$infectedImage.visible = $image.visible

func _on_any_animation_started(animName: String) -> void:
	if animName not in GUARDED_ANIMATIONS:
		return
	if not has_node("Area2D/CollisionShape2D"):
		return
	
	if _activeGuardedAnimations == 0:
		_preAnimationCollisionState = $Area2D/CollisionShape2D.disabled
		
	_activeGuardedAnimations += 1
	$Area2D/CollisionShape2D.set_deferred("disabled", true)

func _on_any_animation_finished(animName: String) -> void:
	if animName not in GUARDED_ANIMATIONS:
		return
	if not has_node("Area2D/CollisionShape2D"):
		return
	
	_activeGuardedAnimations -= 1
	
	if _activeGuardedAnimations <= 0:
		_activeGuardedAnimations = 0
		$Area2D/CollisionShape2D.set_deferred("disabled", _preAnimationCollisionState)

func _on_image_visibility_changed() -> void:
	if has_node("infectedImage"):
		$infectedImage.visible = $image.visible

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
	
	if has_node("infectedImage") and _can_be_infected():
		$infectedImage.texture = _load_infected_texture(safeFaction)
	
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
	# If the front image is hidden, the card is face-down!
	var isFaceDown = true
	if has_node("image") and get_node("image").visible:
		isFaceDown = false
		
	if isFaceDown:
		return
		
	emit_signal("hoverEntered", self)

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hoverExited", self)

func modify_value(amount: int) -> void:
	if amount == 0:
		return
	
	value += amount
	
	var isFaceDown = true
	if has_node("image") and get_node("image").visible:
		isFaceDown = false
		
	if isFaceDown:
		if has_node("value"):
			get_node("value").text = str(value)
		return
	
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

func _load_infected_texture(safeFaction: String) -> Texture2D:
	var premiumPath = "res://core/cards/art/premium/infected/" + cardKey + "Card.png"
	var fallbackPath = "res://core/cards/art/infected/" + safeFaction + ".png"
	
	if ResourceLoader.exists(premiumPath):
		return load(premiumPath)
	return load(fallbackPath)


func _can_be_infected() -> bool:
	return type == "Character" and faction != "Infected" and faction != "Support"

func set_infected(infected: bool, animate: bool = true, permanent: bool = false) -> void:
	if infected:
		if not _can_be_infected() or gotInfected:
			return
		
		gotInfected = true
		permanentInfection = permanent
		originalFaction = faction
		faction = "Infected"
		
		_update_faction_icon("Infected")
		
		if animate:
			pass # In card this is used to play the shake
		
		if has_node("infectedImage"):
			if animate:
				var tween = create_tween()
				tween.tween_property($infectedImage, "modulate:a", 1.0, 0.4)
			else:
				$infectedImage.modulate.a = 1.0
	else:
		if not gotInfected:
			return
		
		gotInfected = false
		permanentInfection = false
		faction = originalFaction
		originalFaction = ""
		
		_update_faction_icon(faction)
		
		if has_node("infectedImage"):
			if animate:
				var tween = create_tween()
				tween.tween_property($infectedImage, "modulate:a", 0.0, 0.4)
			else:
				$infectedImage.modulate.a = 0.0

func _update_faction_icon(newFaction: String) -> void:
	if not has_node("icons/faction"):
		return
	
	if newFaction in KEYWORD_ICONS:
		$icons.get_node("faction").texture = load(_get_card_icon_path(newFaction))

func matches_faction(targetFaction: String) -> bool:
	if faction == targetFaction:
		return true
	if faction == "Seraphite" and HoldoutStats.activeAllegiance.get("id") == Database.Allegiance.FALSE_COLORS:
		return true
	return false

func is_named_companion(key: String) -> bool:
	if cardKey == key:
		return true
	if cardKey in ["Lev", "Yara"] and HoldoutStats.activeAllegiance.get("id") == Database.Allegiance.SPLIT_ALLEGIANCE:
		return true
	return false

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
