extends Node2D

const RIGHT_MARGIN = 263.0
const SPACING = 90.0
const BUBBLE_SCENE = preload("res://scenes/modifierBubble.tscn")

func render_active_modifiers() -> void:
	var modifiers = GameStats.activeModifiers
	
	while get_child_count() < modifiers.size():
		var index_to_add = get_child_count()
		var mod_data = modifiers[index_to_add]
		
		var bubble = BUBBLE_SCENE.instantiate()
		bubble.setup(mod_data)
		
		bubble.scale = Vector2.ZERO 
		
		bubble.position = Vector2(get_viewport().get_visible_rect().size.x - RIGHT_MARGIN, 465)
		
		add_child(bubble)
		
		_update_bubble_positions(0.4)
		
		%CardHoverSound.play()
		
		var pop_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop_tween.tween_property(bubble, "scale", Vector2(0.24, 0.24), 0.4)
		
		await get_tree().create_timer(0.4).timeout

func clear_modifiers() -> void:
	while get_child_count() > 0:
		var target_bubble = get_child(0)
		
		%CardHoverSound.play()
		
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(target_bubble, "scale", Vector2.ZERO, 0.25)
		
		await tween.finished
		
		target_bubble.queue_free()
		
		await get_tree().process_frame
		
		if get_child_count() > 0:
			_update_bubble_positions(0.3)
			
			await get_tree().create_timer(0.1).timeout

func _update_bubble_positions(speed: float) -> void:
	var bubbles = get_children()
	var modifier_count = bubbles.size()
	
	if modifier_count == 0: return

	var center_y = 465.0
	var stack_span = (modifier_count - 1) * SPACING
	var start_y = center_y - (stack_span / 2.0)
	
	for i in range(modifier_count):
		var bubble = bubbles[i]
		
		var target_x = get_viewport().get_visible_rect().size.x - RIGHT_MARGIN
		var target_y = start_y + (i * SPACING)
		var new_pos = Vector2(target_x, target_y)
		
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(bubble, "position", new_pos, speed)
