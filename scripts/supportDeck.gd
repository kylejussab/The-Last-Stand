extends Node2D

const PLAYER_CARD_SCENE_PATH = "res://scenes/card.tscn"
const OPPONENT_CARD_SCENE_PATH = "res://scenes/opponentCard.tscn"
const CARD_DRAW_SPEED = 0.2

const SUPPORT_DECK_POSITION = Vector2(135, 548)

const ICON_SIZE = 12 # Will be tied to font size

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
	
	var newCard = _create_card_instance(cardDrawn, OPPONENT_CARD_SCENE_PATH, false)
	
	$"../opponentHand".add_card_to_hand(newCard, CARD_DRAW_SPEED)
	newCard.play_draw_sound()
	
	if $"../battleManager".showOpponentsCards:
		newCard.get_node("AnimationPlayer").play("cardFlip")
	else:
		newCard.get_node("image").visible = false

func reshuffle_from_discards(discardedCards):
	for card in discardedCards:
		deck.append(card.cardKey)
		
		card.play_draw_sound()
		await move_card_back_to_deck(card)
		
		card.queue_free()
	
	deck.shuffle()
	
	z_index = 100
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property($image, "scale", Vector2(0.288, 0.288), 0.15)
	await tween.finished
	
	play_shuffle_sound()
	
	await get_tree().create_timer(0.2).timeout
	var tween_back = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween_back.tween_property($image, "scale", Vector2(0.188, 0.188), 0.2)
	z_index = -2
	
	$RichTextLabel.text = str(deck.size())

func move_card_back_to_deck(card):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", SUPPORT_DECK_POSITION, 0.1)
	await tween.finished

func play_shuffle_sound():
	var randomSound = shuffleSounds.pick_random()
	soundPlayer.stream = randomSound
	soundPlayer.play()

# Privates
func _create_card_instance(cardKey: String, scenePath: String, _isPlayer: bool = false) -> Node2D:
	var cardScene = load(scenePath)
	var newCard = cardScene.instantiate()
	
	newCard.cardKey = cardKey
	newCard.position = SUPPORT_DECK_POSITION
	newCard.name = "Card"
	newCard.canBePlayed = false

	var data = cardDatabaseReference.SUPPORTS[cardKey]
	newCard.value = data[0]
	newCard.type = data[1]
	newCard.role = data[2]
	newCard.nameText = data[4]
	
	newCard.get_node("value").text = str(newCard.value)
	newCard.get_node("name").text = newCard.nameText
	newCard.get_node("image").texture = load("res://assets/cards/" + cardKey + "Card.png")
	newCard.get_node("imageBack").texture = load("res://assets/cards/CardBackBlank.png")
	
	if data.size() > 5:
		var rawText = data[5]
		var formattedText = _format_perk_text(rawText)
		newCard.get_node("supportingText/perkText").text = formattedText
	else:
		newCard.get_node("supportingText/perkText").text = ""
	
	if cardDatabaseReference.PERKS.has(cardKey):
		newCard.perk = load(cardDatabaseReference.PERKS[cardKey]).new()
	
	var iconsNode = newCard.get_node("icons")
	
	iconsNode.get_node("faction").visible = false
	
	var perkList = newCard.role.split("/") if newCard.role else []
	
	var activePerks = []
	for perk in perkList:
		if perk != "": activePerks.append(perk)
	
	var perkSprites = [iconsNode.get_node("perk1"), iconsNode.get_node("perk2")]
	
	if activePerks.is_empty() or activePerks.size() == 5:
		for sprite in perkSprites:
			sprite.visible = false
	else:
		for i in range(perkSprites.size()):
			if i < activePerks.size():
				perkSprites[i].visible = true
				perkSprites[i].texture = load("res://assets/cardIcons/" + activePerks[i] + ".png")
			else:
				perkSprites[i].visible = false

	$"../cardManager".add_child(newCard)
	
	return newCard

func _format_perk_text(raw_text: String) -> String:
	var rich_text = raw_text
	for keyword in KEYWORD_ICONS:
		if keyword in rich_text:
			var icon_path = KEYWORD_ICONS[keyword]
			# width=%d sets the size to ICON_SIZE (10)
			var replacement = "[img height=%d]%s[/img]" % [ICON_SIZE, icon_path]
			rich_text = rich_text.replace(keyword, replacement)
	return rich_text
