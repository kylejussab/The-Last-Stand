extends Control

@onready var cardPlaceholder = $HBoxContainer/MarginContainer/HBoxContainer/CardPlaceholder
@onready var descriptionLabel = $HBoxContainer/MarginContainer/HBoxContainer/DescLabel

var currentPreviewCard = null

func _ready():
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	if visible and currentPreviewCard != null:
		currentPreviewCard.update_visuals()

func update_preview_card(targetKey: String):
	if currentPreviewCard != null:
		currentPreviewCard.queue_free()
		
	if not Database.CHARACTERS.has(targetKey):
		push_error("Card key '" + targetKey + "' missing from database!")
		return
		
	var cardData = Database.CHARACTERS[targetKey]
	
	var card_scene = load("res://core/cards/card.tscn")
	currentPreviewCard = card_scene.instantiate()
	
	cardPlaceholder.add_child(currentPreviewCard)
	
	currentPreviewCard.scale = Vector2(3, 3)
	currentPreviewCard.position = cardPlaceholder.size / 2 
	
	currentPreviewCard.cardKey = targetKey
	currentPreviewCard.value = cardData[0]
	currentPreviewCard.type = cardData[1]
	currentPreviewCard.faction = cardData[2]
	currentPreviewCard.role = cardData[3]
	currentPreviewCard.nameText = cardData[4]
	currentPreviewCard.perkDescription = cardData[5]
	
	currentPreviewCard.get_node("value").text = str(currentPreviewCard.value)
	currentPreviewCard.get_node("name").text = currentPreviewCard.nameText
	currentPreviewCard.get_node("imageBack").texture = load("res://core/cards/art/CardBackBlank.png")
	
	var faction_path = "res://core/cards/icons/" + currentPreviewCard.faction + ".png"
	currentPreviewCard.get_node("icons/faction").texture = load(faction_path)
	
	currentPreviewCard.update_visuals()
	
	descriptionLabel.text = Database.CARD_VIEWER_DESCRIPTIONS[targetKey]
