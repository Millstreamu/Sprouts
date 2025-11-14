extends Node2D

const HEX_SIZE: float = 40.0

func _draw() -> void:
    draw_circle(Vector2.ZERO, HEX_SIZE * 0.5, Color(1.0, 1.0, 0.0, 0.2))
    draw_circle(Vector2.ZERO, HEX_SIZE * 0.5, Color(1.0, 1.0, 0.0, 1.0))
