extends Control

var isViewDeckActive: bool = false

func _ready() -> void:
	hide()
	$overlay.modulate.a = 0.0
	$viewPanel/background.modulate.a = 0.94
	
	$viewPanel/background.scale.x = 0.0

func open_deck_view():
	show()
	$overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# This is so right clicking closes the deck
	%pause.currentNavigation = "View Deck"
	$"../pauseIcon/text".text = "BACK"
	
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property($viewPanel/background, "scale:x", 1.0, 0.4)

func close_deck_view():
	# This is so right clicking closes the deck
	%pause.currentNavigation = "Main"
	$"../pauseIcon/text".text = "PAUSE"
	
	var tween = create_tween()
	tween.tween_property($viewPanel/background, "scale:x", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC)
	
	await tween.finished
	
	if $"../characterDeck".isHovered:
		$"../characterDeck".force_reset_visuals()
	
	if $"../supportDeck".isHovered:
		$"../supportDeck".force_reset_visuals()
		
	isViewDeckActive = false
	
	hide()
	$overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_overlay_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT) and event.pressed:
		close_deck_view()
