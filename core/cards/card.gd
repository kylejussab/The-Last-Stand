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

var HUNTED_ICON_Y_POSITION = 60

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
var borrowedPerk = null
var perkValueAtRoundEnd
var canBePlayed: bool
var perkDescription: String
var perkValueAppliedMidRound: int = 0
var isNullified: bool = false
var parity: String
var gotInfected: bool = false
var permanentInfection: bool = false
var originalFaction: String = ""
var frenzyBonusApplied: bool = false
var splitAllegianceBonusApplied: bool = false
var isDoctrineBackfired: bool = false
var isHunted: bool = false

var roundStartValue: int = 0
var hasRoundSnapshot: bool = false

var handPosition: Vector2
var _isGuardingCollision: bool = false
var _preAnimationCollisionState: bool = false
const GUARDED_ANIMATIONS = ["modifierIndicator", "cardFlip", "backfire", "lock"]

func _ready() -> void:
	if get_parent().has_method("connect_card_signals"):
		get_parent().connect_card_signals(self)
	
	if has_node("infectedImage"):
		if permanentInfection:
			$infectedImage.modulate.a = 1.0
		else:
			$infectedImage.modulate.a = 0.0
	
	if has_node("AnimationPlayer"):
		$AnimationPlayer.animation_started.connect(_evaluate_collision_guard)
		$AnimationPlayer.animation_finished.connect(_evaluate_collision_guard)
		$AnimationPlayer.current_animation_changed.connect(_evaluate_collision_guard)

func _evaluate_collision_guard(_animName: String = "") -> void:
	if not has_node("Area2D/CollisionShape2D"):
		return
	
	var animPlayer = $AnimationPlayer
	var needs_guard = false
	
	if animPlayer.is_playing() and animPlayer.current_animation in GUARDED_ANIMATIONS:
		needs_guard = true
	
	if not needs_guard:
		for q_anim in animPlayer.get_queue():
			if q_anim in GUARDED_ANIMATIONS:
				needs_guard = true
				break
	
	if needs_guard:
		if not _isGuardingCollision:
			_preAnimationCollisionState = $Area2D/CollisionShape2D.disabled
			_isGuardingCollision = true
		$Area2D/CollisionShape2D.disabled = true
	else:
		if _isGuardingCollision:
			_isGuardingCollision = false
			$Area2D/CollisionShape2D.disabled = _preAnimationCollisionState

func snapshot_round_start_value() -> void:
	roundStartValue = value
	hasRoundSnapshot = true

func clear_round_snapshot() -> void:
	hasRoundSnapshot = false

func update_visuals():
	_apply_accessibility_settings()
	_apply_visibility_settings()
	_apply_frenzied_state_bonus()
	_apply_split_allegiance_bonus()
	
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
		var hunted = $icons.get_node("hunted")
		
		perkOne.scale = Vector2(PERK_ICON_SCALE, PERK_ICON_SCALE)
		perkOne.position = Vector2(-58.5, PERK_ICON_ONE_Y_POSITION)
		
		perkTwo.scale = Vector2(PERK_ICON_SCALE, PERK_ICON_SCALE)
		perkTwo.position = Vector2(-58.5, PERK_ICON_TWO_Y_POSITION)
		
		hunted.scale = Vector2(PERK_ICON_SCALE, PERK_ICON_SCALE)
		hunted.position = Vector2(-58.5, HUNTED_ICON_Y_POSITION)
		
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
			HUNTED_ICON_Y_POSITION = 65
			FACTION_ICON_SCALE = 0.12
			PERK_LINE_Y_SIZE = 15
		AccessibilityData.CardUISize.MEDIUM:
			CARD_TEXT_SIZE = 20
			DESCRIPTION_TEXT_SIZE = 12
			DESCRIPTION_ICON_SIZE = 14
			PERK_ICON_SCALE = 0.117
			PERK_ICON_ONE_Y_POSITION = -61
			PERK_ICON_TWO_Y_POSITION = -33.5
			HUNTED_ICON_Y_POSITION = 60
			FACTION_ICON_SCALE = 0.145
			PERK_LINE_Y_SIZE = 17.5
		AccessibilityData.CardUISize.LARGE:
			CARD_TEXT_SIZE = 24
			DESCRIPTION_TEXT_SIZE = 14
			DESCRIPTION_ICON_SIZE = 16
			PERK_ICON_SCALE = 0.15
			PERK_ICON_ONE_Y_POSITION = -56
			PERK_ICON_TWO_Y_POSITION = -28.5
			HUNTED_ICON_Y_POSITION = 55
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
	
	if has_node("infectedImage") and gotInfected:
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
		
	var animationPlayer = get_node("AnimationPlayer")
	
	# Bloater Plating Allegiance negation
	if amount < 0 and _is_bloater_plating_immune():
		get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Bloater Plating.png")
		
		if animationPlayer.is_playing():
			animationPlayer.queue("modifierIndicator")
		else:
			animationPlayer.play("modifierIndicator")
		return
	
	var previousValue = value
	value += amount
	
	if amount < 0 and hasRoundSnapshot and _has_stubborn_resolve() and value < roundStartValue:
		value = roundStartValue
		get_node("ModifierIndicator").texture = load("res://holdout/modifiers/icons/Stubborn Resolve.png")
		if animationPlayer.is_playing():
			animationPlayer.queue("modifierIndicator")
		else:
			animationPlayer.play("modifierIndicator")
	
	var actualDelta = value - previousValue
	
	if not animationPlayer.animation_started.is_connected(_when_animation_starts):
		animationPlayer.animation_started.connect(_when_animation_starts)
	
	if actualDelta == 0:
		return
	
	var stringSign = "+" if actualDelta >= 0 else "" 
	
	get_node("perk").text = stringSign + str(actualDelta)
	
	if animationPlayer.is_playing():
		animationPlayer.queue("showPerk")
	else:
		animationPlayer.play("showPerk")

func _has_stubborn_resolve() -> bool:
	for m in HoldoutStats.activeModifiers:
		if m.get("id") == Database.Modifier.STUBBORN_RESOLVE:
			return true
	return false

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
		
		if has_node("infectedImage"):
			$infectedImage.texture = _load_infected_texture(faction if faction != "" else "Support")
		
		if animate:
			_play_infection_shake()
		
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

func _apply_frenzied_state_bonus() -> void:
	if frenzyBonusApplied:
		return
	if type != "Character" or faction != "Infected":
		return
	if HoldoutStats.activeAllegiance.get("id") != Database.Allegiance.FRENZIED_STATE:
		return
	if not Database.CHARACTERS.has(cardKey):
		return
	
	var baseValue = Database.CHARACTERS[cardKey][0]
	if baseValue <= 3:
		frenzyBonusApplied = true
		value += 2

func _apply_split_allegiance_bonus() -> void:
	if splitAllegianceBonusApplied:
		return
	if cardKey != "Lev" and cardKey != "Yara":
		return
	if HoldoutStats.activeAllegiance.get("id") != Database.Allegiance.SPLIT_ALLEGIANCE:
		return
	
	splitAllegianceBonusApplied = true
	value += 2

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

func _play_infection_shake() -> void:
	var collisionShape = get_node("Area2D/CollisionShape2D")
	collisionShape.set_deferred("disabled", true)
	
	if AccessibilityData.animationsDisabled:
		collisionShape.set_deferred("disabled", false)
		return
	
	var originalScale = scale
	var originalRotation = rotation
	var peakScale = Vector2(1.35, 1.35)
	
	var tween = create_tween()
	
	tween.tween_property(self, "scale", peakScale, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween.parallel().tween_property(self, "rotation", originalRotation + deg_to_rad(8), 0.06)
	tween.tween_property(self, "rotation", originalRotation - deg_to_rad(8), 0.06)
	tween.tween_property(self, "rotation", originalRotation + deg_to_rad(6), 0.06)
	tween.tween_property(self, "rotation", originalRotation - deg_to_rad(6), 0.06)
	tween.tween_property(self, "rotation", originalRotation + deg_to_rad(3), 0.06)
	tween.tween_property(self, "rotation", originalRotation - deg_to_rad(3), 0.06)
	tween.tween_property(self, "rotation", originalRotation, 0.05)
	
	tween.tween_property(self, "scale", originalScale, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	await tween.finished
	collisionShape.set_deferred("disabled", false)


func _is_bloater_plating_immune() -> bool:
	if type != "Character" or faction != "Infected":
		return false
	return HoldoutStats.activeAllegiance.get("id") == Database.Allegiance.BLOATER_PLATING

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
