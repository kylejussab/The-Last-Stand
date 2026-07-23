extends Node2D

var currentlyHoveredCard: Node2D = null
var darkenAmount: float = 0.3

func _on_mouse_entered() -> void:
	if %battleManager.battleEngine.actionHistory.is_empty():
		return
		
	currentlyHoveredCard = _get_top_visual_card()
	
	if !%battleManager.lockPlayerInput and (!%viewDeckUI.isViewDeckActive and !%viewDeckUI.isViewHistoryActive):
		AudioManager.play_card_hover()
		
		$hoverText.show()
		
		var tween = create_tween()
		tween.tween_property($hoverText, "scale", Vector2(0.2068, 0.2068), 0.1)
		
		if is_instance_valid(currentlyHoveredCard):
			$hoverText.z_index = currentlyHoveredCard.z_index + 1
			tween.parallel().tween_property(currentlyHoveredCard, "scale", Vector2(1.1, 1.1), 0.1)
			tween.parallel().tween_property(currentlyHoveredCard, "modulate", Color(darkenAmount, darkenAmount, darkenAmount, 1.0), 0.1)

func _on_mouse_exited() -> void:
	if !%battleManager.lockPlayerInput and (!%viewDeckUI.isViewDeckActive and !%viewDeckUI.isViewHistoryActive):
		AudioManager.play_card_hover()
		
		$hoverText.hide()
		
		var tween = create_tween()
		tween.tween_property($hoverText, "scale", Vector2(0.188, 0.188), 0.1)
		
		if is_instance_valid(currentlyHoveredCard):
			tween.parallel().tween_property(currentlyHoveredCard, "scale", Vector2(1.0, 1.0), 0.1)
			tween.parallel().tween_property(currentlyHoveredCard, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)
		
	currentlyHoveredCard = null

func _on_mouse_pressed(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and !%battleManager.lockPlayerInput and event.pressed:
		if %battleManager.battleEngine.actionHistory.is_empty():
			return
		
		%viewDeckUI.isViewHistoryActive = true
		%viewDeckUI.open_history_view(%battleManager.battleEngine.actionHistory, self)

func _get_top_visual_card() -> Node2D:
	var topCard: Node2D = null
	var highestZ: int = -1
	
	for card in %battleManager.discardedCards:
		if is_instance_valid(card) and card.z_index > highestZ:
			highestZ = card.z_index
			topCard = card
			
	return topCard

func force_reset_visuals():
	$hoverText.hide()
	
	var topCard = _get_top_visual_card()
	
	if is_instance_valid(topCard):
		var tween = create_tween()
		tween.tween_property(topCard, "scale", Vector2(1.0, 1.0), 0.1)
		tween.parallel().tween_property(topCard, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)
