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
@export var commune_overlay_path: NodePath
@export var commune_title_label_path: NodePath
@export var commune_hint_label_path: NodePath
@export var tile_choice_button_0_path: NodePath
@export var tile_choice_button_1_path: NodePath
@export var tile_choice_button_2_path: NodePath

@onready var _turn_label: Label = get_node(turn_label_path) as Label
@onready var _phase_label: Label = get_node(phase_label_path) as Label
@onready var _world_root: Node2D = get_node(world_root_path) as Node2D
@onready var _hex_grid: Node2D = get_node(hex_grid_path) as Node2D
@onready var _selector: Node2D = get_node(selector_path) as Node2D
@onready var _tile_info_label: Label = get_node(tile_info_label_path) as Label
@onready var _resource_label: Label = get_node(resource_label_path) as Label
@onready var _end_turn_hint_label: Label = get_node(end_turn_hint_label_path) as Label
@onready var _back_button: Button = get_node(back_button_path) as Button
@onready var _commune_overlay: Control = get_node(commune_overlay_path) as Control
@onready var _commune_title_label: Label = get_node(commune_title_label_path) as Label
@onready var _commune_hint_label: Label = get_node(commune_hint_label_path) as Label
@onready var _tile_choice_button_0: Button = get_node(tile_choice_button_0_path) as Button
@onready var _tile_choice_button_1: Button = get_node(tile_choice_button_1_path) as Button
@onready var _tile_choice_button_2: Button = get_node(tile_choice_button_2_path) as Button
@onready var _tile_choice_buttons: Array[Button] = []

const GRID_WIDTH: int = 7
const GRID_HEIGHT: int = 5
const HEX_SIZE: float = 40.0

const PHASE_COMMUNE: int = 0
const PHASE_PLAYER: int = 1

var _turn_number: int = 1
var _current_phase: String = "Player"
var _phase: int = PHASE_COMMUNE

var _selector_q: int = 0
var _selector_r: int = 0

var _tiles: Array = []
var _current_tile_id: String = ""
var _current_tile_name: String = ""
var _has_placed_this_turn: bool = false

var _tile_defs: Array = []
var _tile_defs_by_id: Dictionary = {}
var _dummy_tiles: Array = []

var _current_commune_choices: Array = []

var _res_nature: int = 0
var _res_water: int = 0
var _res_earth: int = 0
var _res_souls: int = 0

func _ready() -> void:
    _back_button.pressed.connect(_on_back_pressed)
    _tile_choice_buttons = [
        _tile_choice_button_0,
        _tile_choice_button_1,
        _tile_choice_button_2
    ]
    _tile_choice_button_0.pressed.connect(func() -> void:
        _select_commune_choice(0)
    )
    _tile_choice_button_1.pressed.connect(func() -> void:
        _select_commune_choice(1)
    )
    _tile_choice_button_2.pressed.connect(func() -> void:
        _select_commune_choice(2)
    )
    _init_tiles()
    _load_tile_defs()
    _turn_number = 1
    _phase = PHASE_COMMUNE
    _current_phase = "Commune"
    _current_tile_id = ""
    _current_tile_name = ""
    _has_placed_this_turn = false
    _res_nature = 0
    _res_water = 0
    _res_earth = 0
    _res_souls = 0
    _update_turn_and_phase_labels()
    _update_tile_panel()
    _update_resource_label()
    _end_turn_hint_label.text = "RL - Next Turn (Press V)"
    _show_commune()
    _update_selector_position()
    _hex_grid.update()
    _selector.update()
    print("ShroudWorld: ready")

func _input(event: InputEvent) -> void:
    if Input.is_action_just_pressed("ui_cancel"):
        _go_back_to_main_menu()
        accept_event()
        return

    if _phase == PHASE_COMMUNE and _commune_overlay.visible:
        if event is InputEventKey and event.pressed and not event.echo:
            match event.keycode:
                Key.KEY_1:
                    _select_commune_choice(0)
                    accept_event()
                    return
                Key.KEY_2:
                    _select_commune_choice(1)
                    accept_event()
                    return
                Key.KEY_3:
                    _select_commune_choice(2)
                    accept_event()
                    return
        return

    if _phase != PHASE_PLAYER:
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
            row.append("")
        _tiles.append(row)

func _load_tile_defs() -> void:
    _tile_defs.clear()
    _tile_defs_by_id.clear()
    _dummy_tiles.clear()

    var path := "res://data/tiles.json"
    if not FileAccess.file_exists(path):
        print("ShroudWorld: tiles.json not found at ", path)
        return

    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        print("ShroudWorld: failed to open tiles.json")
        return

    var text := file.get_as_text()
    var parsed := JSON.parse_string(text)
    if parsed == null:
        print("ShroudWorld: JSON parse failed for tiles.json")
        return

    if parsed is Array:
        for entry in parsed:
            if entry is Dictionary:
                var id := str(entry.get("id", ""))
                if id.is_empty():
                    continue
                _tile_defs.append(entry)
                _tile_defs_by_id[id] = entry
        _dummy_tiles = _tile_defs.duplicate()
        print("ShroudWorld: loaded %d tile defs" % _tile_defs.size())
    else:
        print("ShroudWorld: tiles.json root is not an Array")

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
    var phase_name := "Player"
    if _phase == PHASE_COMMUNE:
        phase_name = "Commune"
    elif _phase == PHASE_PLAYER:
        phase_name = "Player"
    _phase_label.text = "Phase: %s" % phase_name

func _update_tile_panel() -> void:
    if _current_tile_id.is_empty():
        _tile_info_label.text = "Current Tile: None"
    else:
        _tile_info_label.text = "Current Tile: %s" % _current_tile_name

func _update_resource_label() -> void:
    _resource_label.text = "Nature: %d | Water: %d | Earth: %d | Souls: %d" % [
        _res_nature,
        _res_water,
        _res_earth,
        _res_souls
    ]

func _generate_resources_for_turn() -> void:
    var add_nature: int = 0
    var add_water: int = 0
    var add_earth: int = 0
    var add_souls: int = 0

    for r in GRID_HEIGHT:
        for q in GRID_WIDTH:
            var tile_id := str(_tiles[r][q])
            if tile_id == "":
                continue
            if not _tile_defs_by_id.has(tile_id):
                continue
            var def := _tile_defs_by_id[tile_id]
            var base_output := def.get("base_output", {})
            if base_output is Dictionary:
                add_nature += int(base_output.get("nature", 0))
                add_water += int(base_output.get("water", 0))
                add_earth += int(base_output.get("earth", 0))
                add_souls += int(base_output.get("souls", 0))

    _res_nature += add_nature
    _res_water += add_water
    _res_earth += add_earth
    _res_souls += add_souls

    print("ShroudWorld: resources gained this turn -> N:%d W:%d E:%d S:%d" % [
        add_nature,
        add_water,
        add_earth,
        add_souls
    ])

    _update_resource_label()

func _end_turn() -> void:
    if _phase != PHASE_PLAYER:
        print("ShroudWorld: cannot end turn, not in Player phase")
        return

    if not _has_placed_this_turn:
        print("ShroudWorld: must place a tile before ending the turn")
        return

    _generate_resources_for_turn()
    _turn_number += 1
    print("ShroudWorld: End turn -> Turn %d" % _turn_number)
    _show_commune()

func _place_tile_at_selector() -> void:
    _clamp_selector()
    if _phase != PHASE_PLAYER:
        print("ShroudWorld: cannot place tile, not in Player phase")
        return

    if _current_tile_id.is_empty():
        print("ShroudWorld: no current tile selected")
        return

    if _has_placed_this_turn:
        print("ShroudWorld: already placed a tile this turn")
        return

    if _tiles[_selector_r][_selector_q] != "":
        print("ShroudWorld: tile already placed at (%d, %d)" % [_selector_q, _selector_r])
        return

    _tiles[_selector_r][_selector_q] = _current_tile_id
    _has_placed_this_turn = true
    print("ShroudWorld: placed %s at (%d, %d)" % [_current_tile_id, _selector_q, _selector_r])
    _tile_info_label.text = "Placed %s at (%d, %d)" % [_current_tile_name, _selector_q, _selector_r]
    _current_tile_id = ""
    _current_tile_name = ""
    _update_tile_panel()

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

func _show_commune() -> void:
    _phase = PHASE_COMMUNE
    _current_phase = "Commune"
    _has_placed_this_turn = false
    _current_tile_id = ""
    _current_tile_name = ""
    _update_tile_panel()
    _update_turn_and_phase_labels()
    _current_commune_choices.clear()
    var count := 3
    if _dummy_tiles.is_empty():
        print("ShroudWorld: no tiles loaded for Commune")
    else:
        for i in count:
            var idx := randi() % _dummy_tiles.size()
            _current_commune_choices.append(_dummy_tiles[idx])
    for i in _tile_choice_buttons.size():
        var button := _tile_choice_buttons[i]
        if i < _current_commune_choices.size():
            var data := _current_commune_choices[i]
            var tile_name := str(data.get("name", "Tile"))
            button.text = tile_name
            button.disabled = false
        else:
            button.text = "-"
            button.disabled = true
    _commune_title_label.text = "Commune – Choose a Tile"
    _commune_hint_label.text = "Use 1/2/3 or Space/Enter while focused, arrows move selector"
    _commune_overlay.visible = true
    print("ShroudWorld: Commune open with choices: ", _current_commune_choices)

func _select_commune_choice(index: int) -> void:
    if index < 0 or index >= _current_commune_choices.size():
        return
    var choice := _current_commune_choices[index]
    _current_tile_id = str(choice.get("id", ""))
    _current_tile_name = str(choice.get("name", ""))
    _phase = PHASE_PLAYER
    _current_phase = "Player"
    _has_placed_this_turn = false
    _update_tile_panel()
    _update_turn_and_phase_labels()
    _commune_overlay.visible = false
    print("ShroudWorld: selected tile %s" % _current_tile_id)
