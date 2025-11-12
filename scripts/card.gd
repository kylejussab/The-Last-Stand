extends Node2D

signal hoverEntered(card)
signal hoverExited(card)

var cardSlot
var type
var value: int

var handPosition: Vector2

func _ready() -> void:
	get_parent().connect_card_signals(self)

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hoverEntered", self)

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hoverExited", self)
