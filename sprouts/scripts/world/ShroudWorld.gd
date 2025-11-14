extends Control
class_name ShroudWorldScreen

@export var turn_label_path: NodePath
@export var phase_label_path: NodePath
@export var world_root_path: NodePath
@export var hex_grid_path: NodePath
@export var selector_path: NodePath
@export var tile_info_label_path: NodePath
@export var resource_label_path: NodePath
@export var end_turn_hint_label_path: NodePath
@export var back_button_path: NodePath

@onready var _turn_label: Label = get_node(turn_label_path) as Label
@onready var _phase_label: Label = get_node(phase_label_path) as Label
@onready var _world_root: Node2D = get_node(world_root_path) as Node2D
@onready var _hex_grid: Node2D = get_node(hex_grid_path) as Node2D
@onready var _selector: Node2D = get_node(selector_path) as Node2D
@onready var _tile_info_label: Label = get_node(tile_info_label_path) as Label
@onready var _resource_label: Label = get_node(resource_label_path) as Label
@onready var _end_turn_hint_label: Label = get_node(end_turn_hint_label_path) as Label
@onready var _back_button: Button = get_node(back_button_path) as Button

const GRID_WIDTH: int = 7
const GRID_HEIGHT: int = 5
const HEX_SIZE: float = 40.0

var _turn_number: int = 1
var _current_phase: String = "Player"

var _selector_q: int = 0
var _selector_r: int = 0

var _tiles: Array = []

func _ready() -> void:
    _back_button.pressed.connect(_on_back_pressed)
    _init_tiles()
    _update_turn_and_phase_labels()
    _update_resource_label()
    _end_turn_hint_label.text = "RL - Next Turn (Press V)"
    _update_selector_position()
    _hex_grid.update()
    _selector.update()
    print("ShroudWorld: ready")

func _input(event: InputEvent) -> void:
    if Input.is_action_just_pressed("ui_cancel"):
        _go_back_to_main_menu()
        accept_event()
        return

    if Input.is_action_just_pressed("ui_accept"):
        _place_tile_at_selector()
        accept_event()
        return

    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == Key.KEY_V:
            _end_turn()
            accept_event()
            return

    if Input.is_action_just_pressed("ui_left"):
        _move_selector(-1, 0)
        accept_event()
    elif Input.is_action_just_pressed("ui_right"):
        _move_selector(1, 0)
        accept_event()
    elif Input.is_action_just_pressed("ui_up"):
        _move_selector(0, -1)
        accept_event()
    elif Input.is_action_just_pressed("ui_down"):
        _move_selector(0, 1)
        accept_event()

func _init_tiles() -> void:
    _tiles.clear()
    for r in GRID_HEIGHT:
        var row: Array = []
        for q in GRID_WIDTH:
            row.append(false)
        _tiles.append(row)

func _clamp_selector() -> void:
    _selector_q = clampi(_selector_q, 0, GRID_WIDTH - 1)
    _selector_r = clampi(_selector_r, 0, GRID_HEIGHT - 1)

func _grid_to_world(q: int, r: int) -> Vector2:
    var x := q * HEX_SIZE * 1.1
    var y := r * HEX_SIZE * 0.9
    return Vector2(x, y)

func _update_selector_position() -> void:
    _clamp_selector()
    var base := _grid_to_world(_selector_q, _selector_r)
    _selector.position = base

func _update_turn_and_phase_labels() -> void:
    _turn_label.text = "Turn %d" % _turn_number
    _phase_label.text = "Phase: %s" % _current_phase

func _update_resource_label() -> void:
    _resource_label.text = "Nature: 0 | Water: 0 | Earth: 0 | Souls: 0"

func _end_turn() -> void:
    _turn_number += 1
    print("ShroudWorld: End turn -> Turn %d" % _turn_number)
    _update_turn_and_phase_labels()

func _place_tile_at_selector() -> void:
    _clamp_selector()
    if _tiles[_selector_r][_selector_q]:
        print("ShroudWorld: tile already placed at (%d, %d)" % [_selector_q, _selector_r])
        return
    _tiles[_selector_r][_selector_q] = true
    print("ShroudWorld: placed tile at (%d, %d)" % [_selector_q, _selector_r])
    _tile_info_label.text = "Placed tile at (%d, %d)" % [_selector_q, _selector_r]

func _move_selector(dq: int, dr: int) -> void:
    _selector_q += dq
    _selector_r += dr
    _clamp_selector()
    _update_selector_position()
    print("ShroudWorld: selector at (%d, %d)" % [_selector_q, _selector_r])

func _on_back_pressed() -> void:
    _go_back_to_main_menu()

func _go_back_to_main_menu() -> void:
    print("ShroudWorld: back to Main Menu")
    get_tree().change_scene_to_file("res://scenes/meta/MainMenu.tscn")
