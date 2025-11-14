extends Node2D

const GRID_WIDTH: int = 7
const GRID_HEIGHT: int = 5
const HEX_SIZE: float = 40.0

func _ready() -> void:
    update()

func _grid_to_world(q: int, r: int) -> Vector2:
    var x := q * HEX_SIZE * 1.1
    var y := r * HEX_SIZE * 0.9
    return Vector2(x, y)

func _draw() -> void:
    for r in GRID_HEIGHT:
        for q in GRID_WIDTH:
            var pos := _grid_to_world(q, r)
            draw_circle(pos, HEX_SIZE * 0.45, Color(0.3, 0.4, 0.3, 1.0))
