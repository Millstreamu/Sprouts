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
@export var sprout_registry_overlay_path: NodePath
@export var sprout_registry_list_path: NodePath
@export var battle_overlay_layer_path: NodePath

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
@onready var _sprout_registry_overlay: Control = get_node(sprout_registry_overlay_path) as Control
@onready var _sprout_registry_list: VBoxContainer = get_node(sprout_registry_list_path) as VBoxContainer
@onready var _battle_overlay_layer: Control = get_node(battle_overlay_layer_path) as Control

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
var _overgrowth_age: Array = []
var _decay_grid: Array = []
var _decay_count: int = 0
var _current_tile_id: String = ""
var _current_tile_name: String = ""
var _has_placed_this_turn: bool = false

var _sprouts: Array = []

var _battle_overlay_active: bool = false
var _battle_window: Control = null

# Cluster detection
var _cluster_ids: Array = []
var _clusters: Dictionary = {}
var _next_cluster_id: int = 0
const CLUSTER_THRESHOLDS: Array[int] = [3, 6, 12, 24]
# cluster_id -> highest threshold already rewarded for that cluster
var _cluster_rewards: Dictionary = {}

const TILE_ID_OVERGROWTH: String = "tile.special.overgrowth"
const TILE_ID_GROVE: String = "tile.special.grove"

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
    _init_decay_grid()
    _load_tile_defs()
    _cluster_rewards.clear()
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
    _spawn_initial_decay_sources()
    _recompute_clusters()
    _apply_cluster_threshold_rewards()
    _update_turn_and_phase_labels()
    _update_tile_panel()
    _update_resource_label()
    _end_turn_hint_label.text = "RL - Next Turn (Press V)"
    _show_commune()
    _update_selector_position()
    _update_tile_info_for_selector()
    if is_instance_valid(_hex_grid):
        _hex_grid.update()
    _selector.update()
    if is_instance_valid(_sprout_registry_overlay):
        _sprout_registry_overlay.visible = false
    _update_sprout_registry_view()
    if is_instance_valid(_battle_overlay_layer):
        _battle_overlay_layer.visible = false
    if Engine.has_singleton("RunContext"):
        var ctx := RunContext
        ctx.debug_print()
        print(
            "ShroudWorld: starting run with totem=%s difficulty=%d sprouts=%s" % [
                ctx.selected_totem_id,
                ctx.selected_difficulty,
                ctx.selected_sprout_ids
            ]
        )
    else:
        print("ShroudWorld: WARNING - RunContext singleton not found")
    print("ShroudWorld: ready")

func _input(event: InputEvent) -> void:
    if _battle_overlay_active:
        return

    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == Key.KEY_R:
            _toggle_sprout_registry()
            accept_event()
            return

        if event.keycode == Key.KEY_C:
            _debug_print_clusters()
            accept_event()
            return

        if event.keycode == Key.KEY_B:
            _start_debug_battle()
            accept_event()
            return

    if Input.is_action_just_pressed("ui_cancel"):
        if is_instance_valid(_sprout_registry_overlay) and _sprout_registry_overlay.visible:
            _hide_sprout_registry()
            accept_event()
            return
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
    _overgrowth_age.clear()
    _cluster_ids.clear()
    for r in GRID_HEIGHT:
        var row: Array = []
        var age_row: Array = []
        var cluster_row: Array = []
        for q in GRID_WIDTH:
            row.append("")
            age_row.append(0)
            cluster_row.append(-1)
        _tiles.append(row)
        _overgrowth_age.append(age_row)
        _cluster_ids.append(cluster_row)

func _get_tile_category(tile_id: String) -> String:
    if tile_id.is_empty():
        return ""
    if not _tile_defs_by_id.has(tile_id):
        return ""
    var def := _tile_defs_by_id[tile_id]
    return str(def.get("category", ""))

func _recompute_clusters() -> void:
    _clusters.clear()
    _next_cluster_id = 0

    for r in GRID_HEIGHT:
        for q in GRID_WIDTH:
            _cluster_ids[r][q] = -1

    for r in GRID_HEIGHT:
        for q in GRID_WIDTH:
            var tile_id := str(_tiles[r][q])
            if tile_id == "":
                continue

            var category := _get_tile_category(tile_id)
            if category != "Nature" and category != "Water" and category != "Earth":
                continue

            if _cluster_ids[r][q] != -1:
                continue

            _flood_fill_cluster(q, r, category)

    print("ShroudWorld: recomputed clusters; total clusters = %d" % _clusters.size())

func _apply_cluster_threshold_rewards() -> void:
    if _cluster_rewards == null:
        _cluster_rewards = {}

    for cluster_id in _clusters.keys():
        var c := _clusters[cluster_id]
        var category := str(c.get("category", ""))
        if category != "Nature" and category != "Water" and category != "Earth":
            continue

        var size := int(c.get("size", 0))
        if size <= 0:
            continue

        var old_threshold: int = -1
        if _cluster_rewards.has(cluster_id):
            old_threshold = int(_cluster_rewards[cluster_id])

        for threshold in CLUSTER_THRESHOLDS:
            if size >= threshold and threshold > old_threshold:
                _grant_cluster_reward(cluster_id, c, category, threshold)
                _cluster_rewards[cluster_id] = threshold

func _grant_cluster_reward(cluster_id: int, cluster_data: Dictionary, category: String, threshold: int) -> void:
    var tiles: Array = cluster_data.get("tiles", [])
    if tiles.is_empty():
        return

    var idx := randi() % tiles.size()
    var pos: Vector2i = tiles[idx]
    var q := pos.x
    var r := pos.y

    print("ShroudWorld: cluster %d (category=%s, size=%d) reached threshold %d at (%d, %d)" % [
        cluster_id,
        category,
        int(cluster_data.get("size", 0)),
        threshold,
        q,
        r
    ])

    var spawned: bool = _try_spawn_sprout_from_cluster(q, r, category, threshold)
    if not spawned:
        var souls_amount := _get_cluster_soul_reward(category, threshold)
        _res_souls += souls_amount
        _update_resource_label()
        print("ShroudWorld: granted %d Soul Seeds from cluster %d" % [souls_amount, cluster_id])

func _get_cluster_soul_reward(category: String, threshold: int) -> int:
    match threshold:
        3:
            return 1
        6:
            return 2
        12:
            return 4
        24:
            return 8
        _:
            return 1

func _try_spawn_sprout_from_cluster(q: int, r: int, category: String, threshold: int) -> bool:
    if not Engine.has_singleton("RunContext"):
        print("ShroudWorld: cannot spawn sprout from cluster, RunContext not found")
        return false

    var ctx := RunContext
    if ctx.selected_sprout_ids.is_empty():
        print("ShroudWorld: no selected sprouts in RunContext to spawn (cluster reward)")
        return false

    var idx := randi() % ctx.selected_sprout_ids.size()
    var sprout_id: String = ctx.selected_sprout_ids[idx]

    var sprout := {
        "id": sprout_id,
        "level": 1,
        "q": q,
        "r": r
    }
    _sprouts.append(sprout)
    print("ShroudWorld: spawned sprout %s at (%d, %d) from cluster reward (threshold %d, category %s)" % [
        sprout_id,
        q,
        r,
        threshold,
        category
    ])

    _update_sprout_registry_view()
    return true

func _flood_fill_cluster(start_q: int, start_r: int, category: String) -> void:
    var cluster_id := _next_cluster_id
    _next_cluster_id += 1

    var tiles: Array = []
    var open_list: Array = []
    open_list.append(Vector2i(start_q, start_r))

    while not open_list.is_empty():
        var v: Vector2i = open_list.pop_back()
        var q := v.x
        var r := v.y

        if r < 0 or r >= GRID_HEIGHT:
            continue
        if q < 0 or q >= GRID_WIDTH:
            continue
        if _cluster_ids[r][q] != -1:
            continue

        var tile_id := str(_tiles[r][q])
        if tile_id == "":
            continue
        var tile_category := _get_tile_category(tile_id)
        if tile_category != category:
            continue

        _cluster_ids[r][q] = cluster_id
        tiles.append(v)

        var neighbors := [
            Vector2i(q - 1, r),
            Vector2i(q + 1, r),
            Vector2i(q, r - 1),
            Vector2i(q, r + 1)
        ]
        for n in neighbors:
            if n.x >= 0 and n.x < GRID_WIDTH and n.y >= 0 and n.y < GRID_HEIGHT:
                if _cluster_ids[n.y][n.x] == -1:
                    open_list.append(n)

    var cluster_data := {
        "category": category,
        "tiles": tiles,
        "size": tiles.size()
    }
    _clusters[cluster_id] = cluster_data

func _get_current_tile_selection_text() -> String:
    if _current_tile_id.is_empty():
        return "Current Tile: None"
    return "Current Tile: %s" % _current_tile_name

func _update_tile_info_for_selector() -> void:
    var selection_text := _get_current_tile_selection_text()
    var q := _selector_q
    var r := _selector_r

    if r < 0 or r >= GRID_HEIGHT or q < 0 or q >= GRID_WIDTH:
        _tile_info_label.text = "%s\nTile: None" % selection_text
        return

    var tile_id := str(_tiles[r][q])
    if tile_id == "":
        _tile_info_label.text = "%s\nTile: None" % selection_text
        return

    var tile_name := tile_id
    if _tile_defs_by_id.has(tile_id):
        var def := _tile_defs_by_id[tile_id]
        tile_name = str(def.get("name", tile_id))

    var info_text := "%s\nTile: %s at (%d, %d)" % [selection_text, tile_name, q, r]

    var cluster_id := _cluster_ids[r][q]
    if cluster_id != -1 and _clusters.has(cluster_id):
        var c := _clusters[cluster_id]
        var cat := str(c.get("category", ""))
        var size := int(c.get("size", 0))
        info_text += " | Cluster: %s size %d" % [cat, size]

    _tile_info_label.text = info_text

func _debug_print_clusters() -> void:
    print("ShroudWorld: debug clusters, count = %d" % _clusters.size())
    for cluster_id in _clusters.keys():
        var c := _clusters[cluster_id]
        var cat := str(c.get("category", ""))
        var size := int(c.get("size", 0))
        print("  Cluster %d: category=%s size=%d" % [cluster_id, cat, size])

func _init_decay_grid() -> void:
    _decay_grid.clear()
    _decay_count = 0
    for r in GRID_HEIGHT:
        var row: Array = []
        for q in GRID_WIDTH:
            row.append(false)
        _decay_grid.append(row)

func _get_initial_decay_sources_for_difficulty() -> int:
    var difficulty: int = 0
    if Engine.has_singleton("RunContext"):
        var ctx := RunContext
        difficulty = ctx.selected_difficulty
    match difficulty:
        0:
            return 1
        1:
            return 2
        2:
            return 3
        _:
            return 1

func _spawn_initial_decay_sources() -> void:
    var count := _get_initial_decay_sources_for_difficulty()
    var attempts := 0
    var max_attempts := 100

    while count > 0 and attempts < max_attempts:
        attempts += 1
        var edge := randi() % 4
        var q := 0
        var r := 0
        match edge:
            0:
                r = 0
                q = randi() % GRID_WIDTH
            1:
                r = GRID_HEIGHT - 1
                q = randi() % GRID_WIDTH
            2:
                q = 0
                r = randi() % GRID_HEIGHT
            3:
                q = GRID_WIDTH - 1
                r = randi() % GRID_HEIGHT

        if _decay_grid[r][q]:
            continue

        _decay_grid[r][q] = true
        _decay_count += 1
        count -= 1
        print("ShroudWorld: spawned initial decay at (%d, %d)" % [q, r])

    if is_instance_valid(_hex_grid):
        _hex_grid.update()

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
    _update_tile_info_for_selector()

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

func _advance_overgrowth_and_groves() -> void:
    for r in GRID_HEIGHT:
        for q in GRID_WIDTH:
            var tile_id := str(_tiles[r][q])
            if tile_id != TILE_ID_OVERGROWTH:
                continue
            _overgrowth_age[r][q] += 1
            if _overgrowth_age[r][q] >= 3:
                _transform_overgrowth_to_grove(q, r)

func _transform_overgrowth_to_grove(q: int, r: int) -> void:
    _tiles[r][q] = TILE_ID_GROVE
    _overgrowth_age[r][q] = 0
    print("ShroudWorld: Overgrowth at (%d, %d) transformed into Grove" % [q, r])
    _spawn_sprout_from_grove(q, r)
    if is_instance_valid(_hex_grid):
        _hex_grid.update()

func _spawn_sprout_from_grove(q: int, r: int) -> void:
    if not Engine.has_singleton("RunContext"):
        print("ShroudWorld: cannot spawn sprout, RunContext not found")
        return

    var ctx := RunContext
    if ctx.selected_sprout_ids.is_empty():
        print("ShroudWorld: no selected sprouts in RunContext to spawn")
        return

    var idx := randi() % ctx.selected_sprout_ids.size()
    var sprout_id: String = ctx.selected_sprout_ids[idx]
    var sprout := {
        "id": sprout_id,
        "level": 1,
        "q": q,
        "r": r
    }
    _sprouts.append(sprout)
    print("ShroudWorld: spawned sprout %s at (%d, %d)" % [sprout_id, q, r])
    _update_sprout_registry_view()

func _update_sprout_registry_view() -> void:
    if not is_instance_valid(_sprout_registry_list):
        return

    for child in _sprout_registry_list.get_children():
        child.queue_free()

    if _sprouts.is_empty():
        var empty_label := Label.new()
        empty_label.text = "No sprouts yet."
        _sprout_registry_list.add_child(empty_label)
        return

    for sprout in _sprouts:
        var label := Label.new()
        var sprout_id := str(sprout.get("id", ""))
        var level := int(sprout.get("level", 1))
        var q := int(sprout.get("q", -1))
        var r := int(sprout.get("r", -1))
        label.text = "%s (Lv %d) at (%d, %d)" % [sprout_id, level, q, r]
        _sprout_registry_list.add_child(label)

func _show_sprout_registry() -> void:
    if not is_instance_valid(_sprout_registry_overlay):
        return
    _sprout_registry_overlay.visible = true
    _update_sprout_registry_view()
    print("ShroudWorld: Sprout registry opened")

func _hide_sprout_registry() -> void:
    if not is_instance_valid(_sprout_registry_overlay):
        return
    _sprout_registry_overlay.visible = false
    print("ShroudWorld: Sprout registry closed")

func _toggle_sprout_registry() -> void:
    if not is_instance_valid(_sprout_registry_overlay):
        return
    if _sprout_registry_overlay.visible:
        _hide_sprout_registry()
    else:
        _show_sprout_registry()

func _end_turn() -> void:
    if _phase != PHASE_PLAYER:
        print("ShroudWorld: cannot end turn, not in Player phase")
        return

    if not _has_placed_this_turn:
        print("ShroudWorld: must place a tile before ending the turn")
        return

    _generate_resources_for_turn()
    _spread_decay_for_turn()
    _advance_overgrowth_and_groves()
    _recompute_clusters()
    _apply_cluster_threshold_rewards()
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
    _overgrowth_age[_selector_r][_selector_q] = 0
    _has_placed_this_turn = true
    print("ShroudWorld: placed %s at (%d, %d)" % [_current_tile_id, _selector_q, _selector_r])
    _current_tile_id = ""
    _current_tile_name = ""
    _update_tile_panel()
    _recompute_clusters()
    _update_tile_info_for_selector()
    if is_instance_valid(_hex_grid):
        _hex_grid.update()

func _move_selector(dq: int, dr: int) -> void:
    _selector_q += dq
    _selector_r += dr
    _clamp_selector()
    _update_selector_position()
    print("ShroudWorld: selector at (%d, %d)" % [_selector_q, _selector_r])
    _update_tile_info_for_selector()

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

func _get_neighbors(q: int, r: int) -> Array[Vector2i]:
    var neighbors: Array[Vector2i] = []
    var dirs := [
        Vector2i(-1, 0),
        Vector2i(1, 0),
        Vector2i(0, -1),
        Vector2i(0, 1)
    ]
    for d in dirs:
        var nq := q + d.x
        var nr := r + d.y
        if nq >= 0 and nq < GRID_WIDTH and nr >= 0 and nr < GRID_HEIGHT:
            neighbors.append(Vector2i(nq, nr))
    return neighbors

func _spread_decay_for_turn() -> void:
    var new_decay_positions: Array[Vector2i] = []

    for r in GRID_HEIGHT:
        for q in GRID_WIDTH:
            if not _decay_grid[r][q]:
                continue

            var neighbors := _get_neighbors(q, r)
            var possible_targets: Array[Vector2i] = []

            for v in neighbors:
                var nq := v.x
                var nr := v.y
                if _decay_grid[nr][nq]:
                    continue
                possible_targets.append(v)

            if possible_targets.is_empty():
                continue

            var idx := randi() % possible_targets.size()
            var chosen: Vector2i = possible_targets[idx]
            new_decay_positions.append(chosen)

    for v in new_decay_positions:
        var q := v.x
        var r := v.y
        if not _decay_grid[r][q]:
            _decay_grid[r][q] = true
            _decay_count += 1

            if _tiles[r][q] != "":
                print("ShroudWorld: decay overtook tile %s at (%d, %d)" % [_tiles[r][q], q, r])
                _tiles[r][q] = ""
                _overgrowth_age[r][q] = 0

    if not new_decay_positions.is_empty():
        print("ShroudWorld: decay spread to %d new cells this turn" % new_decay_positions.size())
    else:
        print("ShroudWorld: decay did not spread this turn")

    if is_instance_valid(_hex_grid):
        _hex_grid.update()

func get_tile_id_at(q: int, r: int) -> String:
    if r < 0 or r >= _tiles.size():
        return ""
    var row: Array = _tiles[r]
    if q < 0 or q >= row.size():
        return ""
    return str(row[q])

func is_decay_at(q: int, r: int) -> bool:
    if r < 0 or r >= _decay_grid.size():
        return false
    var row: Array = _decay_grid[r]
    if q < 0 or q >= row.size():
        return false
    return bool(row[q])

func _build_player_battle_team_from_sprouts() -> Array:
    var team: Array = []
    for sprout in _sprouts:
        var name := str(sprout.get("id", "Sprout"))
        var level := int(sprout.get("level", 1))
        var max_hp := 60 + level * 10
        var attack := 10 + level * 2
        var cooldown := 3.0
        var unit := {
            "name": name,
            "max_hp": max_hp,
            "hp": max_hp,
            "attack": attack,
            "cooldown": cooldown,
            "cooldown_remaining": randf_range(0.0, cooldown),
            "is_player": true
        }
        team.append(unit)
    return team

func _build_dummy_enemy_battle_team() -> Array:
    var team: Array = []
    for i in 3:
        var cooldown := 3.5
        var unit := {
            "name": "Smog_%d" % i,
            "max_hp": 70,
            "hp": 70,
            "attack": 9,
            "cooldown": cooldown,
            "cooldown_remaining": randf_range(0.0, cooldown),
            "is_player": false
        }
        team.append(unit)
    return team

func _start_debug_battle() -> void:
    if _battle_overlay_active:
        print("ShroudWorld: battle overlay already active")
        return

    if not is_instance_valid(_battle_overlay_layer):
        print("ShroudWorld: battle overlay layer is not set")
        return

    if not Engine.has_singleton("BattleContext"):
        print("ShroudWorld: cannot start battle, BattleContext singleton not found")
        return

    var ctx := BattleContext
    ctx.reset()

    var player_team := _build_player_battle_team_from_sprouts()
    if player_team.is_empty():
        print("ShroudWorld: no sprouts available, using dummy player team")
        player_team = _build_dummy_enemy_battle_team()
        for unit in player_team:
            unit["is_player"] = true

    var enemy_team := _build_dummy_enemy_battle_team()

    ctx.player_team = player_team
    ctx.enemy_team = enemy_team
    ctx.debug_print()

    var scene := load("res://scenes/world/BattleWindow.tscn")
    if scene == null or not (scene is PackedScene):
        print("ShroudWorld: failed to load BattleWindow.tscn")
        return

    _battle_window = (scene as PackedScene).instantiate() as Control
    if _battle_window == null:
        print("ShroudWorld: failed to instance BattleWindow")
        return

    _battle_overlay_layer.add_child(_battle_window)
    _battle_overlay_layer.visible = true
    _battle_overlay_active = true

    if _battle_window.has_signal("battle_finished"):
        (_battle_window as Node).connect("battle_finished", Callable(self, "_on_battle_finished"))

    print("ShroudWorld: started debug battle overlay")

func _on_battle_finished(result: String, player_team: Array, enemy_team: Array) -> void:
    print("ShroudWorld: battle finished with result = %s" % result)
    print("ShroudWorld: player team final state:")
    for unit in player_team:
        print("  P: ", unit)
    print("ShroudWorld: enemy team final state:")
    for unit in enemy_team:
        print("  E: ", unit)

    if is_instance_valid(_battle_window):
        _battle_window.queue_free()
        _battle_window = null

    if is_instance_valid(_battle_overlay_layer):
        _battle_overlay_layer.visible = false

    _battle_overlay_active = false
