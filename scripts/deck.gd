extends Node2D

const CARD_SCENE_PATH = "res://scenes/card.tscn"
const CARD_DRAW_SPEED = 0.2

var playerDeck = ["Joel", "Ellie", "Clicker"]

var cardDatabaseReference

func _ready() -> void:
	playerDeck.shuffle()
	
	$RichTextLabel.text = str(playerDeck.size())
	cardDatabaseReference = preload("res://scripts/database.gd")

func draw_card():
	var cardDrawn = playerDeck[0]
	playerDeck.erase(cardDrawn)
	
	if playerDeck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$image.visible = false
	
	$RichTextLabel.text = str(playerDeck.size())
	var cardScene = preload(CARD_SCENE_PATH)
	var newCard = cardScene.instantiate()
	var cardImagePath = str("res://assets/" + cardDrawn + "Card.png")
	
	newCard.get_node("image").texture = load(cardImagePath)
	newCard.get_node("value").text = str(cardDatabaseReference.CARDS[cardDrawn][0])
	
	$"../cardManager".add_child(newCard)
	newCard.name = "Card"
	$"../playerHand".add_card_to_hand(newCard, CARD_DRAW_SPEED)
	
	newCard.get_node("AnimationPlayer").play("cardFlip")
