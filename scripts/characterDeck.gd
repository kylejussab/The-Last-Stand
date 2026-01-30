extends Node2D

const PLAYER_CARD_SCENE_PATH = "res://scenes/card.tscn"
const OPPONENT_CARD_SCENE_PATH = "res://scenes/opponentCard.tscn"
const CARD_DRAW_SPEED = 0.2

const CHARACTER_DECK_POSITION = Vector2(135, 796)

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

@onready var soundPlayer = $AudioStreamPlayer2D

var shuffleSounds = [
	preload("res://assets/sounds/cards/shuffle_1.wav"),
	preload("res://assets/sounds/cards/shuffle_2.wav"),
	preload("res://assets/sounds/cards/shuffle_3.wav"),
	preload("res://assets/sounds/cards/shuffle_4.wav")
]

var deck: Array

var cardDatabaseReference

func _ready() -> void:
	$RichTextLabel.text = str(deck.size())
	cardDatabaseReference = preload("res://scripts/database.gd")
	
	apply_card_scale()

func draw_card():
	var cardDrawn = deck[0]
	deck.erase(cardDrawn)
	
	$RichTextLabel.text = str(deck.size())
	
	var newCard = _create_card_instance(cardDrawn, PLAYER_CARD_SCENE_PATH, true)
	
	$"../playerHand".add_card_to_hand(newCard, CARD_DRAW_SPEED)
	
	newCard.get_node("AnimationPlayer").play("cardFlip")
	newCard.play_draw_sound()

func draw_opponent_card():
	var cardDrawn = deck[0]
	deck.erase(cardDrawn)
	
	$RichTextLabel.text = str(deck.size())
	
	var newCard = _create_card_instance(cardDrawn, OPPONENT_CARD_SCENE_PATH)
	
	$"../opponentHand".add_card_to_hand(newCard, CARD_DRAW_SPEED)
	newCard.play_draw_sound()
	
	# This if statement hides and shows the cards (In place for now, for debugging)
	if $"../battleManager".showOpponentsCards:
		newCard.get_node("AnimationPlayer").play("cardFlip")
	else:
		newCard.get_node("image").visible = false

func reshuffle_from_discards(discardedCards):
	var processedNodes = []

	for card in discardedCards:
		if not is_instance_valid(card):
			continue
		
		if card in processedNodes:
			continue
		
		processedNodes.append(card)
		
		deck.append(card.cardKey)
		
		card.play_draw_sound()
		await move_card_back_to_deck(card)
		
		if is_instance_valid(card):
			card.queue_free()
		
	deck.shuffle()
	
	z_index = 100
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property($image, "scale", Vector2(0.288, 0.288), 0.15)
	await tween.finished
	
	_play_shuffle_sound()
	
	await get_tree().create_timer(0.2).timeout
	var tween_back = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween_back.tween_property($image, "scale", Vector2(0.188, 0.188), 0.2)
	z_index = -2
	
	$RichTextLabel.text = str(deck.size())

func move_card_back_to_deck(card):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", CHARACTER_DECK_POSITION, 0.1)
	await tween.finished

# Privates
func _create_card_instance(cardKey: String, scenePath: String, isPlayer: bool = false) -> Node2D:
	var cardScene = load(scenePath)
	var newCard = cardScene.instantiate()
	
	newCard.cardKey = cardKey
	newCard.position = CHARACTER_DECK_POSITION
	newCard.name = "Card"
	newCard.canBePlayed = true

	var data = cardDatabaseReference.CHARACTERS[cardKey]
	newCard.value = data[0]
	newCard.type = data[1]
	newCard.faction = data[2]
	newCard.role = data[3]
	newCard.nameText = data[4]
	
	if %battleManager.noDefenseActive and "Defensive" in newCard.role and isPlayer:
		newCard.value = 0
	
	if %battleManager.loneWolfActive and isPlayer:
		newCard.value *= 1.5
	
	var valueNode = newCard.get_node("value")
	valueNode.text = str(newCard.value)
	valueNode.add_theme_font_size_override("normal_font_size", CARD_TEXT_SIZE)
	
	newCard.get_node("perk").add_theme_font_size_override("normal_font_size", CARD_TEXT_SIZE)
	
	var nameNode = newCard.get_node("name")
	nameNode.text = newCard.nameText
	nameNode.add_theme_font_size_override("normal_font_size", CARD_TEXT_SIZE)
	
	newCard.get_node("image").texture = load("res://assets/cards/" + cardKey + "Card.png")
	newCard.get_node("imageBack").texture = load("res://assets/cards/CardBackBlank.png")
	
	if data.size() > 5:
		var rawText = data[5]
		var formattedText = _format_perk_text(rawText)
		var perkLabel = newCard.get_node("supportingText/perkText")
		perkLabel.text = formattedText
		perkLabel.add_theme_font_size_override("normal_font_size", DESCRIPTION_TEXT_SIZE)
	else:
		newCard.get_node("supportingText/perkText").text = ""
	
	if cardDatabaseReference.PERKS.has(cardKey):
		newCard.perk = load(cardDatabaseReference.PERKS[cardKey]).new()
	
	newCard.get_node("line").size.y = PERK_LINE_Y_SIZE
	
	# Icons
	var iconsNode = newCard.get_node("icons")
	
	var factionPath = "res://assets/cardIcons/" + newCard.faction + ".png" 
	iconsNode.get_node("faction").texture = load(factionPath)
	iconsNode.get_node("faction").scale = Vector2(FACTION_ICON_SCALE, FACTION_ICON_SCALE)

	var perkList = newCard.role.split("/") if newCard.role else []
	
	var activePerks = []
	for perk in perkList:
		if perk != "": activePerks.append(perk)
	
	var perkSprites = [iconsNode.get_node("perk1"), iconsNode.get_node("perk2")]
	
	iconsNode.get_node("perk1").position = Vector2(-58.5, PERK_ICON_ONE_Y_POSITION)
	iconsNode.get_node("perk2").position = Vector2(-58.5, PERK_ICON_TWO_Y_POSITION)
	
	if activePerks.is_empty() or activePerks.size() == 5:
		for sprite in perkSprites:
			sprite.visible = false
	else:
		for i in range(perkSprites.size()):
			if i < activePerks.size():
				perkSprites[i].visible = true
				perkSprites[i].texture = load("res://assets/cardIcons/" + activePerks[i] + ".png")
				perkSprites[i].scale = Vector2(PERK_ICON_SCALE, PERK_ICON_SCALE)
			else:
				perkSprites[i].visible = false
	
	$"../cardManager".add_child(newCard)
	
	return newCard

func _format_perk_text(raw_text: String) -> String:
	var rich_text = raw_text
	for keyword in KEYWORD_ICONS:
		if keyword in rich_text:
			var icon_path = KEYWORD_ICONS[keyword]
			var replacement = "[img height=%d]%s[/img]" % [DESCRIPTION_ICON_SIZE, icon_path]
			rich_text = rich_text.replace(keyword, replacement)
	return rich_text

func _play_shuffle_sound():
	var randomSound = shuffleSounds.pick_random()
	soundPlayer.stream = randomSound
	soundPlayer.play()

func spawn_top_card_node() -> Node2D:
	if deck.is_empty():
		return null
	
	var cardDrawn = deck[0]
	deck.erase(cardDrawn)
	
	$RichTextLabel.text = str(deck.size())
	
	var newCard = _create_card_instance(cardDrawn, PLAYER_CARD_SCENE_PATH, true)
	
	newCard.get_node("AnimationPlayer").play("cardFlip")
	newCard.play_draw_sound()
	
	return newCard

func apply_card_style(card_node: Node2D):
	match AccessibilityData.currentCardStyle:
		AccessibilityData.CardStyle.DEFAULT:
			pass 
		AccessibilityData.CardStyle.MINIMAL:
			# Hide Name, maybe hide other clutter?
			card_node.get_node("name").visible = false
		AccessibilityData.CardStyle.NO_ARTWORK:
			# Handled in main function to prevent loading, but ensuring here:
			if card_node.has_node("image"):
				card_node.get_node("image").texture = null

func apply_card_scale():
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
	
	_update_all_active_cards()

func _update_all_active_cards():
	var card_manager = $"../cardManager"
	if not card_manager: return

	for card in card_manager.get_children():
		card.get_node("value").add_theme_font_size_override("normal_font_size", CARD_TEXT_SIZE)
		card.get_node("name").add_theme_font_size_override("normal_font_size", CARD_TEXT_SIZE)
		
		card.get_node("perk").add_theme_font_size_override("normal_font_size", CARD_TEXT_SIZE)
		
		if card.has_node("supportingText/perkText") and cardDatabaseReference.CHARACTERS.has(card.cardKey):
			var data = cardDatabaseReference.CHARACTERS[card.cardKey]
			if data.size() > 5:
				var formatted_text = _format_perk_text(data[5])
				var perk_label = card.get_node("supportingText/perkText")
				perk_label.text = formatted_text
				perk_label.add_theme_font_size_override("normal_font_size", DESCRIPTION_TEXT_SIZE)
		
		var perkOne = card.get_node("icons/perk1")
		var perkTwo = card.get_node("icons/perk2")
		
		perkOne.scale = Vector2(PERK_ICON_SCALE, PERK_ICON_SCALE)
		perkOne.position = Vector2(-58.5, PERK_ICON_ONE_Y_POSITION)
		
		perkTwo.scale = Vector2(PERK_ICON_SCALE, PERK_ICON_SCALE)
		perkTwo.position = Vector2(-58.5, PERK_ICON_TWO_Y_POSITION)
		
		card.get_node("line").size.y = PERK_LINE_Y_SIZE
		card.get_node("icons/faction").scale = Vector2(FACTION_ICON_SCALE, FACTION_ICON_SCALE)
