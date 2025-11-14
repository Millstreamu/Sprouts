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
    var world_control := get_parent().get_parent()
    var has_world := world_control != null and world_control.has_method("get_tile_id_at") and world_control.has_method("is_decay_at")

    for r in GRID_HEIGHT:
        for q in GRID_WIDTH:
            var pos := _grid_to_world(q, r)

            var is_decay := false
            var has_player_tile := false

            if has_world:
                is_decay = world_control.is_decay_at(q, r)
                var tile_id: String = world_control.get_tile_id_at(q, r)
                has_player_tile = tile_id != ""

            var color: Color
            if is_decay:
                color = Color(0.5, 0.1, 0.6, 1.0)
            elif has_player_tile:
                color = Color(0.2, 0.6, 0.2, 1.0)
            else:
                color = Color(0.2, 0.3, 0.2, 1.0)

            draw_circle(pos, HEX_SIZE * 0.45, color)
