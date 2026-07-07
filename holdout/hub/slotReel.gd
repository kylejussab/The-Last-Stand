extends Control

@onready var strip = $IconStrip

var animationDuration: float = 2.0 
var extraSpinRotations: int = 15 

var iconHeight: float = 0.0
var currentItems: Array = []
var iconScaleFactor: float = 0.24 

func _ready():
	strip.position = Vector2.ZERO

func setup_reel(itemsList: Array):
	currentItems = itemsList
	for child in strip.get_children():
		child.queue_free()
	
	for i in range(30): 
		for item in itemsList:
			_add_icon_to_strip(item)

	await get_tree().process_frame
	if strip.get_child_count() > 0:
		iconHeight = strip.get_child(0).size.y

func spin_to_modifier(targetModifierData: Dictionary):
	var baseIndex = -1
	var targetId = targetModifierData.get("id")
	
	for i in range(currentItems.size()):
		if currentItems[i].get("id") == targetId:
			baseIndex = i
			break
	
	if baseIndex != -1:
		_spin_down_to(baseIndex)

# Privates
func _add_icon_to_strip(item: Dictionary):
	var textureRectangle = TextureRect.new()
	if item.has("icon"):
		textureRectangle.texture = load(item["icon"])
			
		if textureRectangle.texture:
			textureRectangle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			textureRectangle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var targetSize = textureRectangle.texture.get_size() * iconScaleFactor
			textureRectangle.custom_minimum_size = targetSize
			if custom_minimum_size == Vector2.ZERO:
				custom_minimum_size = targetSize
	else:
		var placeholder = ColorRect.new()
		placeholder.custom_minimum_size = Vector2(50, 50)
		placeholder.color = Color.RED
		textureRectangle = placeholder

	strip.add_child(textureRectangle)

func _spin_down_to(baseIndex: int):
	if iconHeight == 0: return
	
	var startIndex = baseIndex + extraSpinRotations
	if startIndex >= strip.get_child_count():
		startIndex = strip.get_child_count() - 1
		
	var startY = -startIndex * iconHeight
	var finalY = -baseIndex * iconHeight
	var overshootY = finalY + (iconHeight * 0.4)
	
	strip.position.y = startY
	var tween = create_tween()
	
	tween.tween_property(strip, "position:y", overshootY, animationDuration * 0.85)\
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(strip, "position:y", finalY, animationDuration * 0.15)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
