extends CanvasLayer

@onready var color_rect = $ColorRect

func _ready() -> void:
	color_rect.modulate.a = 0.0
	color_rect.visible = false

func change_scene(target_path: String, fadeOutDuration: float = 1.0) -> void:
	color_rect.visible = true
	var inTween = create_tween()
	inTween.tween_property(color_rect, "modulate:a", 1.0, 1)
	
	await inTween.finished
	
	get_tree().change_scene_to_file(target_path)
	
	await get_tree().process_frame
	
	var outTween = create_tween()
	outTween.tween_property(color_rect, "modulate:a", 0.0, fadeOutDuration)
	
	await outTween.finished
	color_rect.visible = false

func fade_in(duration: float = 0.5):
	color_rect.visible = true
	var inTween = create_tween()
	inTween.tween_property(color_rect, "modulate:a", 1.0, duration)
	
	await inTween.finished

func fade_out(duration: float = 0.5):
	var outTween = create_tween()
	outTween.tween_property(color_rect, "modulate:a", 0.0, duration)
	
	await outTween.finished
	color_rect.visible = false
