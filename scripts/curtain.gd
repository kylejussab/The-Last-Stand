extends CanvasLayer

@onready var color_rect = $ColorRect

func _ready() -> void:
	color_rect.modulate.a = 0.0
	color_rect.visible = false

func change_scene(target_path: String) -> void:
	color_rect.visible = true
	var inTween = create_tween()
	inTween.tween_property(color_rect, "modulate:a", 1.0, 1)
	
	await inTween.finished
	
	get_tree().change_scene_to_file(target_path)
	
	await get_tree().process_frame
	
	var outTween = create_tween()
	outTween.tween_property(color_rect, "modulate:a", 0.0, 1)
	
	await outTween.finished
	color_rect.visible = false

func fade_in():
	color_rect.visible = true
	var inTween = create_tween()
	inTween.tween_property(color_rect, "modulate:a", 1.0, 0.5)
	
	await inTween.finished

func fade_out():
	var outTween = create_tween()
	outTween.tween_property(color_rect, "modulate:a", 0.0, 0.5)
	
	await outTween.finished
	color_rect.visible = false
