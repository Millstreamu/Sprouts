extends Control
class_name ShroudWorldScreen

@export var turn_label_path: NodePath
@export var phase_label_path: NodePath
@export var world_root_path: NodePath
@export var hex_grid_path: NodePath
@export var selector_path: NodePath
@export var tile_info_label_path: NodePath
@export var tile_info_panel_path: NodePath
@export var world_hud_path: NodePath
@export var back_button_path: NodePath
@export var commune_window_path: NodePath
@export var sprout_registry_overlay_path: NodePath
@export var sprout_registry_list_path: NodePath
@export var battle_overlay_layer_path: NodePath
@export var run_end_overlay_path: NodePath
@export var run_end_result_label_path: NodePath
@export var run_end_hint_label_path: NodePath
@export var run_end_stats_list_path: NodePath

@onready var _turn_label: Label = get_node(turn_label_path) as Label
@onready var _phase_label: Label = get_node(phase_label_path) as Label
@onready var _world_root: Node2D = get_node(world_root_path) as Node2D
@onready var _hex_grid: Node2D = get_node(hex_grid_path) as Node2D
@onready var _selector: Node2D = get_node(selector_path) as Node2D
@onready var _tile_info_label: Label = get_node(tile_info_label_path) as Label
@onready var _tile_info_panel: WorldTileInfoPanel = get_node(tile_info_panel_path) as WorldTileInfoPanel
@onready var _world_hud: WorldHUD = get_node(world_hud_path) as WorldHUD
@onready var _back_button: Button = get_node(back_button_path) as Button
@onready var _commune_window: CommuneWindow = get_node(commune_window_path) as CommuneWindow
@onready var _sprout_registry_overlay: Control = get_node(sprout_registry_overlay_path) as Control
@onready var _sprout_registry_list: VBoxContainer = get_node(sprout_registry_list_path) as VBoxContainer
@onready var _battle_overlay_layer: Control = get_node(battle_overlay_layer_path) as Control
@onready var _run_end_overlay: Control = get_node(run_end_overlay_path) as Control
@onready var _run_end_result_label: Label = get_node(run_end_result_label_path) as Label
@onready var _run_end_hint_label: Label = get_node(run_end_hint_label_path) as Label
@onready var _run_end_stats_list: VBoxContainer = get_node(run_end_stats_list_path) as VBoxContainer

const GRID_WIDTH: int = 7
const GRID_HEIGHT: int = 5
const HEX_SIZE: float = 40.0

const SPROUT_REGEN_PCT_PER_TURN: float = 0.05
const SOUL_SEED_COST_BASE: int = 1
const SOUL_SEED_COST_PER_LEVEL: int = 1

const PHASE_COMMUNE: int = 0
const PHASE_PLAYER: int = 1

var _turn_number: int = 1
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
var _tile_info_enabled: bool = true

var _sprouts: Array = []
var _sprout_registry_selected_index: int = 0
var _next_sprout_instance_id: int = 0

var _battle_overlay_active: bool = false
var _battle_window: Control = null
var _pending_battle_mode: String = ""
var _pending_battle_target_q: int = -1
var _pending_battle_target_r: int = -1

# Decay Totems and player Totem
var _player_totem_q: int = -1
var _player_totem_r: int = -1

# Each element: { "q": int, "r": int, "alive": bool }
var _decay_totems: Array = []
var _alive_decay_totem_count: int = 0

var _run_over: bool = false
var _run_result: String = ""
var _run_sprouts_spawned: int = 0
var _run_sprouts_fallen: int = 0
var _run_initial_decay_totems: int = 0

# Cluster detection
var _cluster_ids: Array = []
var _clusters: Dictionary = {}
var _next_cluster_id: int = 0
const CLUSTER_THRESHOLDS: Array[int] = [3, 6, 12, 24]
const RUN_CONTEXT_PATH := NodePath("/root/RunContext")
# cluster_id -> highest threshold already rewarded for that cluster
var _cluster_rewards: Dictionary = {}

const TILE_ID_OVERGROWTH: String = "tile.special.overgrowth"
const TILE_ID_GROVE: String = "tile.special.grove"

const ENEMY_CONFIG := {
	"easy": {
		"normal": {
			"min_units": 2,
			"max_units": 3,
			"hp_min": 40,
			"hp_max": 60,
			"attack_min": 6,
			"attack_max": 9,
			"cooldown_min": 3.5,
			"cooldown_max": 4.5
		},
		"totem": {
			"min_units": 3,
			"max_units": 4,
			"hp_min": 60,
			"hp_max": 80,
			"attack_min": 8,
			"attack_max": 11,
			"cooldown_min": 3.0,
			"cooldown_max": 4.0
		}
	},
	"medium": {
		"normal": {
			"min_units": 3,
			"max_units": 4,
			"hp_min": 60,
			"hp_max": 80,
			"attack_min": 9,
			"attack_max": 12,
			"cooldown_min": 3.0,
			"cooldown_max": 4.0
		},
		"totem": {
			"min_units": 4,
			"max_units": 5,
			"hp_min": 80,
			"hp_max": 100,
			"attack_min": 11,
			"attack_max": 15,
			"cooldown_min": 2.8,
			"cooldown_max": 3.6
		}
	},
	"hard": {
		"normal": {
			"min_units": 4,
			"max_units": 5,
			"hp_min": 80,
			"hp_max": 100,
			"attack_min": 12,
			"attack_max": 16,
			"cooldown_min": 2.8,
			"cooldown_max": 3.5
		},
		"totem": {
			"min_units": 5,
			"max_units": 6,
			"hp_min": 100,
			"hp_max": 130,
			"attack_min": 15,
			"attack_max": 20,
			"cooldown_min": 2.5,
			"cooldown_max": 3.2
		}
	}
}

var _tile_defs: Array = []
var _tile_defs_by_id: Dictionary = {}

var _commune_active: bool = false

var _res_nature: int = 0
var _res_water: int = 0
var _res_earth: int = 0
var _res_souls: int = 0

func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	if is_instance_valid(_commune_window):
		_commune_window.offer_chosen.connect(_on_commune_offer_chosen)
		_commune_window.visible = false
	_init_tiles()
	_init_decay_grid()
	_load_tile_defs()
	_cluster_rewards.clear()
	_turn_number = 1
	_phase = PHASE_COMMUNE
	_run_over = false
	_run_result = ""
	_run_sprouts_spawned = 0
	_run_sprouts_fallen = 0
	_run_initial_decay_totems = 0
	_current_tile_id = ""
	_current_tile_name = ""
	_has_placed_this_turn = false
	_res_nature = 0
	_res_water = 0
	_res_earth = 0
	_res_souls = 0
	if is_instance_valid(_world_hud):
		_world_hud.next_turn_requested.connect(_on_hud_next_turn_requested)
		_refresh_hud_resources()
	if is_instance_valid(_tile_info_panel):
		_tile_info_panel.show_empty()
		_tile_info_panel.visible = _tile_info_enabled
	_spawn_initial_decay_sources()
	_init_totems_for_run()
	_recompute_clusters()
	_apply_cluster_threshold_rewards()
	_update_turn_and_phase_labels()
	_update_tile_panel()
	_update_resource_label()
	_start_new_turn()
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
	if is_instance_valid(_run_end_overlay):
		_run_end_overlay.visible = false
	if get_tree().has_node(RUN_CONTEXT_PATH):
		var ctx := get_tree().get_node(RUN_CONTEXT_PATH) as RunContext
		ctx.debug_print()
		print(
			"ShroudWorld: starting run with totem=%s difficulty=%s sprouts=%s" % [
				ctx.selected_totem_id,
				str(ctx.selected_difficulty),
				ctx.selected_sprout_ids
			]
		)
	else:
		print("ShroudWorld: WARNING - RunContext singleton not found")
	print("ShroudWorld: ready")

func _get_current_difficulty_key() -> String:
	if Engine.has_singleton("RunContext"):
		var ctx := RunContext
		var diff := str(ctx.selected_difficulty).to_lower()
		if diff in ["easy", "medium", "hard"]:
			return diff
	return "easy"

func _input(event: InputEvent) -> void:
	if _run_over:
		if Input.is_action_just_pressed("ui_accept"):
			print("ShroudWorld: returning to Main Menu after run end")
			get_tree().change_scene_to_file("res://scenes/meta/MainMenu.tscn")
			accept_event()
		return

	if _battle_overlay_active:
		return

	if _commune_active:
		return

	if is_instance_valid(_sprout_registry_overlay) and _sprout_registry_overlay.visible:
		if Input.is_action_just_pressed("ui_up"):
			_sprout_registry_move_selection(-1)
			accept_event()
			return
		if Input.is_action_just_pressed("ui_down"):
			_sprout_registry_move_selection(1)
			accept_event()
			return
		if Input.is_action_just_pressed("ui_cancel"):
			_hide_sprout_registry()
			accept_event()
			return
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == Key.KEY_G:
				_try_level_selected_sprout_with_soul_seeds()
				accept_event()
				return
			if event.keycode == Key.KEY_R:
				_hide_sprout_registry()
				accept_event()
				return
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
		if event.keycode == Key.KEY_V:
			_try_end_turn_from_input()
			accept_event()
			return
		if event.keycode == Key.KEY_M:
			_tile_info_enabled = not _tile_info_enabled
			if is_instance_valid(_tile_info_panel):
				_tile_info_panel.visible = _tile_info_enabled
				if _tile_info_enabled:
					_refresh_tile_info_for_cursor()
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

	if _phase != PHASE_PLAYER:
		return

	if Input.is_action_just_pressed("ui_accept"):
		if _selector_r >= 0 and _selector_r < GRID_HEIGHT and _selector_q >= 0 and _selector_q < GRID_WIDTH:
			if _decay_grid[_selector_r][_selector_q]:
				_start_decay_attack_battle(_selector_q, _selector_r)
				accept_event()
				return

		_place_tile_at_selector()
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

func _try_end_turn_from_input() -> void:
	if _run_over:
		return
	if _battle_overlay_active:
		return
	_end_turn()

func _on_hud_next_turn_requested() -> void:
	_try_end_turn_from_input()

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
	if not get_tree().has_node(RUN_CONTEXT_PATH):
		print("ShroudWorld: cannot spawn sprout from cluster, RunContext not found")
		return false

	var ctx := get_tree().get_node(RUN_CONTEXT_PATH) as RunContext
	if ctx.selected_sprout_ids.is_empty():
		print("ShroudWorld: no selected sprouts in RunContext to spawn (cluster reward)")
		return false

	var idx := randi() % ctx.selected_sprout_ids.size()
	var sprout_id: String = ctx.selected_sprout_ids[idx]
	var level: int = 1
	var max_hp: int = 60 + level * 10
	var current_hp: int = max_hp

	var sprout := {
		"instance_id": _next_sprout_instance_id,
		"id": sprout_id,
		"level": level,
		"max_hp": max_hp,
		"current_hp": current_hp,
		"q": q,
		"r": r,
		"dead": false
	}
	_next_sprout_instance_id += 1

		_sprouts.append(sprout)
		_run_sprouts_spawned += 1
		print("ShroudWorld: spawned sprout %s (instance %d) at (%d, %d) from cluster reward (threshold %d, category %s)" % [
				sprout_id,
				sprout.get("instance_id"),
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

func _get_cursor_coords() -> Vector2i:
	return Vector2i(_selector_q, _selector_r)

func _build_tile_info_for(q: int, r: int) -> Dictionary:
	var info: Dictionary = {
		"name": "Unknown",
		"category": "Unknown",
		"tags": [],
		"cluster_type": "N/A",
		"cluster_size": 0,
		"state": "Unknown",
		"output_summary": "N/A",
		"description": ""
	}

	if r < 0 or r >= GRID_HEIGHT or q < 0 or q >= GRID_WIDTH:
		info["name"] = "Outside Map"
		info["category"] = "N/A"
		info["state"] = "Empty"
		return info

	var tile_id := ""
	if _tiles.size() > r and _tiles[r].size() > q:
		tile_id = str(_tiles[r][q])

	var is_decay := false
	if _decay_grid.size() > r and _decay_grid[r].size() > q:
		is_decay = bool(_decay_grid[r][q])

	if tile_id.is_empty() and not is_decay:
		info["name"] = "Empty Tile"
		info["category"] = "None"
		info["state"] = "Empty"
		return info

	if is_decay:
		info["name"] = "Creeping Decay"
		info["category"] = "Decay"
		info["tags"] = ["DECAY"]
		info["state"] = "Decay"
		var decay_desc := "Spreading corruption. Destroys life tiles and totems if left unchecked."
		if not tile_id.is_empty():
			var target_name := tile_id
			if _tile_defs_by_id.has(tile_id):
				var target_def := _tile_defs_by_id[tile_id]
				target_name = str(target_def.get("name", tile_id))
			decay_desc += " Currently overrunning %s." % target_name
		info["description"] = decay_desc
		return info

	var display_name := tile_id
	var category := "Unknown"
	var description := ""
	var tags: Array[String] = []

	if _tile_defs_by_id.has(tile_id):
		var def := _tile_defs_by_id[tile_id]
		display_name = str(def.get("name", tile_id))
		category = str(def.get("category", "Unknown"))
		description = str(def.get("description", ""))
		var def_tags := def.get("tags", [])
		if def_tags is Array:
			for tag in def_tags:
				tags.append(str(tag))
		elif def_tags is PackedStringArray:
			var packed_tags := def_tags as PackedStringArray
			for tag in packed_tags:
				tags.append(tag)
	else:
		display_name = tile_id
		category = "Unknown"

	var state := "Normal"
	if tile_id == TILE_ID_OVERGROWTH:
		state = "Overgrowth"
		var turns_until_grove := 3
		if _overgrowth_age.size() > r and _overgrowth_age[r].size() > q:
			turns_until_grove = max(0, 3 - int(_overgrowth_age[r][q]))
		if turns_until_grove < 0:
			turns_until_grove = 0
		var overgrowth_note := "Overgrowth that will become a Grove soon."
		if turns_until_grove > 0:
			overgrowth_note = "Overgrowth that will become a Grove in %d turn(s)." % turns_until_grove
		if description.is_empty():
			description = overgrowth_note
		else:
			description = "%s\n%s" % [description, overgrowth_note]
		if not tags.has("OVERGROWTH"):
			tags.append("OVERGROWTH")
	elif tile_id == TILE_ID_GROVE:
		state = "Grove"
		var grove_note := "A fragile grove that can spawn sprouts but is vulnerable to Decay."
		if description.is_empty():
			description = grove_note
		else:
			description = "%s\n%s" % [description, grove_note]
		if not tags.has("GROVE"):
			tags.append("GROVE")

	if description.is_empty():
		description = "No description available."

	info["name"] = display_name
	info["category"] = category
	info["tags"] = tags
	info["state"] = state
	info["output_summary"] = _build_output_summary_for_tile(tile_id)
	info["description"] = description

	var cluster_type := "N/A"
	var cluster_size := 0
	if _cluster_ids.size() > r and _cluster_ids[r].size() > q:
		var cluster_id := int(_cluster_ids[r][q])
		if cluster_id != -1 and _clusters.has(cluster_id):
			var cluster := _clusters[cluster_id]
			cluster_type = str(cluster.get("category", "N/A"))
			cluster_size = int(cluster.get("size", 0))

	if cluster_type == "N/A" and (category == "Nature" or category == "Water" or category == "Earth"):
		cluster_type = category

	info["cluster_type"] = cluster_type
	info["cluster_size"] = cluster_size

	return info

func _build_output_summary_for_tile(tile_id: String) -> String:
	if tile_id.is_empty():
		return "N/A"
	if not _tile_defs_by_id.has(tile_id):
		return "N/A"

	var def := _tile_defs_by_id[tile_id]
	var base_output := def.get("base_output", {})
	if not (base_output is Dictionary):
		return "N/A"

	var output_dict := base_output as Dictionary
	var nature_out := int(output_dict.get("nature", 0))
	var water_out := int(output_dict.get("water", 0))
	var earth_out := int(output_dict.get("earth", 0))
	var souls_out := int(output_dict.get("souls", 0))

	var parts: Array[String] = []
	if nature_out != 0:
		parts.append("Nature %+d/turn" % nature_out)
	if earth_out != 0:
		parts.append("Earth %+d/turn" % earth_out)
	if water_out != 0:
		parts.append("Water %+d/turn" % water_out)
	if souls_out != 0:
		parts.append("Soul Seeds %+d/turn" % souls_out)

	if parts.is_empty():
		return "N/A"

	return ", ".join(parts)

func _refresh_tile_info_for_cursor() -> void:
	if not _tile_info_enabled:
		return
	if not is_instance_valid(_tile_info_panel):
		return

	var coords := _get_cursor_coords()
	var info := _build_tile_info_for(coords.x, coords.y)
	_tile_info_panel.show_tile(info)

func _update_tile_info_for_selector() -> void:
	var selection_text := _get_current_tile_selection_text()
	var q := _selector_q
	var r := _selector_r

	var label_text := "%s\nTile: None" % selection_text

	if r >= 0 and r < GRID_HEIGHT and q >= 0 and q < GRID_WIDTH:
		var tile_id := str(_tiles[r][q])
		var is_decay := false
		if _decay_grid.size() > r and _decay_grid[r].size() > q:
			is_decay = bool(_decay_grid[r][q])
		if tile_id != "" or is_decay:
			var tile_name := "None"
			if is_decay:
				tile_name = "Creeping Decay"
			elif _tile_defs_by_id.has(tile_id):
				var def := _tile_defs_by_id[tile_id]
				tile_name = str(def.get("name", tile_id))
			else:
				tile_name = tile_id
			label_text = "%s\nTile: %s at (%d, %d)" % [selection_text, tile_name, q, r]
			if not is_decay:
				var cluster_id := _cluster_ids[r][q]
				if cluster_id != -1 and _clusters.has(cluster_id):
					var c := _clusters[cluster_id]
					var cat := str(c.get("category", ""))
					var size := int(c.get("size", 0))
					label_text += " | Cluster: %s size %d" % [cat, size]

	if is_instance_valid(_tile_info_label):
		_tile_info_label.text = label_text

	_refresh_tile_info_for_cursor()

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
	if get_tree().has_node(RUN_CONTEXT_PATH):
		var ctx := get_tree().get_node(RUN_CONTEXT_PATH) as RunContext
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

func _trigger_run_victory() -> void:
		if _run_over:
				return
		_run_over = true
		_run_result = "victory"

		if is_instance_valid(_run_end_overlay):
				_run_end_overlay.visible = true
		if is_instance_valid(_run_end_result_label):
				_run_end_result_label.text = "Victory – All Decay Totems destroyed"
		if is_instance_valid(_run_end_hint_label):
				_run_end_hint_label.text = "Press Space to return to Main Menu"

		_populate_run_end_stats()
		if Engine.has_singleton("ChallengeContext"):
				var stats := _build_run_stats_for_challenges()
				ChallengeContext.update_after_run("victory", stats)
		print("ShroudWorld: run ended with VICTORY")

func _trigger_run_defeat(reason: String) -> void:
		if _run_over:
				return
		_run_over = true
		_run_result = "defeat"

		if is_instance_valid(_run_end_overlay):
				_run_end_overlay.visible = true
		if is_instance_valid(_run_end_result_label):
				match reason:
						"totem_consumed":
								_run_end_result_label.text = "Defeat – Totem consumed by Decay"
						"no_valid_placements":
								_run_end_result_label.text = "Defeat – No valid placements remain"
						_:
								_run_end_result_label.text = "Defeat"
		if is_instance_valid(_run_end_hint_label):
				_run_end_hint_label.text = "Press Space to return to Main Menu"

		_populate_run_end_stats()
		if Engine.has_singleton("ChallengeContext"):
				var stats := _build_run_stats_for_challenges()
				ChallengeContext.update_after_run("defeat", stats)
		print("ShroudWorld: run ended with DEFEAT (%s)" % reason)

func _populate_run_end_stats() -> void:
		if not is_instance_valid(_run_end_stats_list):
				return

		for child in _run_end_stats_list.get_children():
				child.queue_free()

		var turns_label := Label.new()
		turns_label.text = "Turns survived: %d" % _turn_number
		_run_end_stats_list.add_child(turns_label)

		var destroyed := _run_initial_decay_totems - _alive_decay_totem_count
		if destroyed < 0:
				destroyed = 0

		var totem_label := Label.new()
		totem_label.text = "Decay Totems destroyed: %d / %d" % [
				destroyed,
				_run_initial_decay_totems
		]
		_run_end_stats_list.add_child(totem_label)

		var spawned_label := Label.new()
		spawned_label.text = "Sprouts spawned: %d" % _run_sprouts_spawned
		_run_end_stats_list.add_child(spawned_label)

		var fallen_label := Label.new()
		fallen_label.text = "Sprouts fallen: %d" % _run_sprouts_fallen
		_run_end_stats_list.add_child(fallen_label)

func _build_run_stats_for_challenges() -> Dictionary:
		var destroyed := _run_initial_decay_totems - _alive_decay_totem_count
		if destroyed < 0:
				destroyed = 0
		return {
				"turns": _turn_number,
				"sprouts_spawned": _run_sprouts_spawned,
				"sprouts_fallen": _run_sprouts_fallen,
				"decay_totems_destroyed": destroyed
		}

func _init_totems_for_run() -> void:
		_decay_totems.clear()
		_alive_decay_totem_count = 0

		_player_totem_q = GRID_WIDTH / 2
		_player_totem_r = GRID_HEIGHT / 2

		if _player_totem_r >= 0 and _player_totem_r < GRID_HEIGHT and _player_totem_q >= 0 and _player_totem_q < GRID_WIDTH:
				if _decay_grid[_player_totem_r][_player_totem_q]:
						_decay_grid[_player_totem_r][_player_totem_q] = false
						_decay_count = max(_decay_count - 1, 0)

		var totem_count: int = 1
		if Engine.has_singleton("RunContext"):
				var ctx := RunContext
				var difficulty_value := ctx.selected_difficulty
				var value_type := typeof(difficulty_value)
				if value_type == TYPE_STRING:
						var diff := str(difficulty_value).to_lower()
						match diff:
								"easy":
										totem_count = 1
								"medium":
										totem_count = 2
								"hard":
										totem_count = 3
								_:
										totem_count = 1
				else:
						var diff_int := int(difficulty_value)
						match diff_int:
								0:
										totem_count = 1
								1:
										totem_count = 2
								2:
										totem_count = 3
								_:
										totem_count = 1

		for i in totem_count:
				var q := GRID_WIDTH - 4 + i
				var r := GRID_HEIGHT / 2

				q = clampi(q, 0, GRID_WIDTH - 1)
				r = clampi(r, 0, GRID_HEIGHT - 1)

				if not _decay_grid[r][q]:
						_decay_grid[r][q] = true
						_decay_count += 1

				var data := {
						"q": q,
						"r": r,
						"alive": true
				}
				_decay_totems.append(data)

		_alive_decay_totem_count = _decay_totems.size()
		_run_initial_decay_totems = _alive_decay_totem_count
		print("ShroudWorld: initialized %d decay totems" % _alive_decay_totem_count)

func _load_tile_defs() -> void:
		_tile_defs.clear()
		_tile_defs_by_id.clear()

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

func _refresh_hud_resources() -> void:
	if not is_instance_valid(_world_hud):
		return
	_world_hud.set_resources(_res_nature, _res_earth, _res_water, _res_souls)

func _update_resource_label() -> void:
	_refresh_hud_resources()

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
	if not get_tree().has_node(RUN_CONTEXT_PATH):
		print("ShroudWorld: cannot spawn sprout, RunContext not found")
		return

	var ctx := get_tree().get_node(RUN_CONTEXT_PATH) as RunContext
	if ctx.selected_sprout_ids.is_empty():
		print("ShroudWorld: no selected sprouts in RunContext to spawn")
		return

	var idx := randi() % ctx.selected_sprout_ids.size()
	var sprout_id: String = ctx.selected_sprout_ids[idx]
	var level: int = 1
	var max_hp: int = 60 + level * 10
	var current_hp: int = max_hp

	var sprout := {
		"instance_id": _next_sprout_instance_id,
		"id": sprout_id,
		"level": level,
		"max_hp": max_hp,
		"current_hp": current_hp,
		"q": q,
		"r": r,
		"dead": false
	}
	_next_sprout_instance_id += 1

		_sprouts.append(sprout)
		_run_sprouts_spawned += 1
		print("ShroudWorld: spawned sprout %s (instance %d) at (%d, %d)" % [
				sprout_id,
				sprout.get("instance_id"),
				q,
				r
		])
	_update_sprout_registry_view()

func _update_sprout_registry_view() -> void:
	if not is_instance_valid(_sprout_registry_list):
		return

	for child in _sprout_registry_list.get_children():
		child.queue_free()

	if _sprouts.is_empty():
		_sprout_registry_selected_index = 0
		var empty_label := Label.new()
		empty_label.text = "No sprouts yet."
		_sprout_registry_list.add_child(empty_label)
		return

	_sprout_registry_selected_index = clampi(
		_sprout_registry_selected_index,
		0,
		_sprouts.size() - 1
	)

	for i in range(_sprouts.size()):
		var sprout := _sprouts[i]
		var label := Label.new()
		var sprout_id := str(sprout.get("id", "sprout"))
		var level := int(sprout.get("level", 1))
		var max_hp := int(sprout.get("max_hp", 0))
		var current_hp := int(sprout.get("current_hp", 0))
		var q := int(sprout.get("q", -1))
		var r := int(sprout.get("r", -1))
		var is_dead := bool(sprout.get("dead", false))

		var text := "%s (Lv %d) HP %d/%d at (%d, %d)" % [
			sprout_id,
			level,
			current_hp,
			max_hp,
			q,
			r
		]
		if is_dead:
			text += " [DEAD]"

		if i == _sprout_registry_selected_index:
			text = "➤ " + text
		else:
			text = "   " + text

		label.text = text
		_sprout_registry_list.add_child(label)

func _sprout_registry_move_selection(delta: int) -> void:
	if _sprouts.is_empty():
		_sprout_registry_selected_index = 0
		return

	_sprout_registry_selected_index += delta
	_sprout_registry_selected_index = clampi(
		_sprout_registry_selected_index,
		0,
		_sprouts.size() - 1
	)
	_update_sprout_registry_view()

func _get_soul_seed_cost_for_next_level(current_level: int) -> int:
	if current_level < 1:
		return SOUL_SEED_COST_BASE
	return SOUL_SEED_COST_BASE + (current_level - 1) * SOUL_SEED_COST_PER_LEVEL

func _try_level_selected_sprout_with_soul_seeds() -> void:
	if _sprouts.is_empty():
		print("ShroudWorld: no sprouts to level")
		return

	_sprout_registry_selected_index = clampi(
		_sprout_registry_selected_index,
		0,
		_sprouts.size() - 1
	)

	var sprout := _sprouts[_sprout_registry_selected_index]
	var current_level := int(sprout.get("level", 1))
	var cost := _get_soul_seed_cost_for_next_level(current_level)

	if _res_souls < cost:
		print(
			"ShroudWorld: not enough Soul Seeds to level sprout (need %d, have %d)" % [
				cost,
				_res_souls
			]
		)
		return

	_res_souls -= cost
	current_level += 1
	sprout["level"] = current_level

	var new_max_hp := 60 + current_level * 10
	sprout["max_hp"] = new_max_hp
	sprout["current_hp"] = new_max_hp
	sprout["dead"] = false

	_update_resource_label()
	_update_sprout_registry_view()

	print(
		"ShroudWorld: leveled sprout %s (instance %d) to level %d for %d Soul Seeds" % [
			str(sprout.get("id", "sprout")),
			int(sprout.get("instance_id", -1)),
			current_level,
			cost
		]
	)

func _regen_sprouts_for_turn() -> void:
	if _sprouts.is_empty():
		return

	for sprout in _sprouts:
		if bool(sprout.get("dead", false)):
			continue

		var max_hp := int(sprout.get("max_hp", 0))
		if max_hp <= 0:
			continue

		var current_hp := int(sprout.get("current_hp", 0))
		if current_hp >= max_hp:
			continue

		var regen_amount := int(round(float(max_hp) * SPROUT_REGEN_PCT_PER_TURN))
		if regen_amount < 1:
			regen_amount = 1

		current_hp += regen_amount
		if current_hp > max_hp:
			current_hp = max_hp

		sprout["current_hp"] = current_hp

	_update_sprout_registry_view()
	print("ShroudWorld: applied regen to sprouts for this turn")

func _get_living_sprout_count() -> int:
	var count := 0
	for sprout in _sprouts:
		if bool(sprout.get("dead", false)):
			continue
		var current_hp := int(sprout.get("current_hp", 0))
		if current_hp > 0:
			count += 1
	return count

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
		if _run_over:
				return
		_advance_overgrowth_and_groves()
		_recompute_clusters()
		_apply_cluster_threshold_rewards()
		_regen_sprouts_for_turn()
		if not _has_any_valid_tile_placements():
				print("ShroudWorld: no valid tile placements remain – defeat")
				_trigger_run_defeat("no_valid_placements")
				return
		_turn_number += 1
		print("ShroudWorld: End turn -> Turn %d" % _turn_number)
		_start_new_turn()

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

func _start_new_turn() -> void:
	if _run_over:
		return
	if Engine.has_singleton("RunContext"):
		var ctx := RunContext
		print(
			"ShroudWorld: new turn %d (totem=%s, difficulty=%s)" % [
				_turn_number,
				str(ctx.selected_totem_id),
				str(ctx.selected_difficulty)
			]
		)
	_phase = PHASE_COMMUNE
	_current_tile_id = ""
	_current_tile_name = ""
	_has_placed_this_turn = false
	_commune_active = false
	_update_tile_panel()
	_update_turn_and_phase_labels()
	_show_commune()

func _show_commune() -> void:
	if not is_instance_valid(_commune_window):
		print("ShroudWorld: CommuneWindow not available")
		_phase = PHASE_PLAYER
		_commune_active = false
		_update_turn_and_phase_labels()
		return

	var offers := _generate_tile_offers()
	if offers.is_empty():
		print("ShroudWorld: no unlocked tiles available for Commune offers")
		_phase = PHASE_PLAYER
		_commune_active = false
		_update_turn_and_phase_labels()
		return

	_commune_active = true
	_commune_window.open_with_offers(offers)
	print("ShroudWorld: Commune open with offers: ", offers)

func _generate_tile_offers() -> Array:
	var raw_entries: Array = []
	if Engine.has_singleton("MetaProgress"):
		raw_entries = MetaProgress.get_all_tile_entries()
	else:
		print("ShroudWorld: MetaProgress not available, cannot build commune offers")
		return []

	var unlocked_entries: Array = []
	for entry in raw_entries:
		if not (entry is Dictionary):
			continue
		if bool(entry.get("unlocked", false)):
			unlocked_entries.append(entry)

	if unlocked_entries.is_empty():
		print("ShroudWorld: no unlocked tiles for commune offers")
		return []

	var totem_id := ""
	var difficulty := "medium"
	if Engine.has_singleton("RunContext"):
		var ctx := RunContext
		totem_id = str(ctx.selected_totem_id)
		difficulty = str(ctx.selected_difficulty)
		if difficulty.is_empty():
			difficulty = "medium"
	else:
		print("ShroudWorld: RunContext not available when generating commune offers")

	if Engine.has_singleton("CommuneManager"):
		var offers := CommuneManager.generate_offers(
			_tile_defs_by_id,
			unlocked_entries,
			totem_id,
			difficulty,
			3
		)
		if not offers.is_empty():
			print(
				"ShroudWorld: generated weighted commune offers (totem=%s, difficulty=%s)" % [
					totem_id,
					difficulty
				]
			)
			return offers
		else:
			print("ShroudWorld: CommuneManager returned no offers, falling back to random")
	else:
		print("ShroudWorld: CommuneManager singleton not available, using fallback commune offers")

	var fallback_offers: Array = []
	var pool := unlocked_entries.duplicate()
	var max_offers := 3
	for i in range(max_offers):
		if pool.is_empty():
			break
		var idx := randi_range(0, pool.size() - 1)
		var entry := pool[idx]
		pool.remove_at(idx)

		if not (entry is Dictionary):
			continue
		var tile_id := str(entry.get("id", ""))
		if tile_id.is_empty():
			continue
		var name := tile_id
		var category := ""
		var description := ""
		if _tile_defs_by_id.has(tile_id):
			var def := _tile_defs_by_id[tile_id]
			name = str(def.get("name", name))
			category = str(def.get("category", ""))
			description = str(def.get("description", ""))

		fallback_offers.append({
			"id": tile_id,
			"name": name,
			"category": category,
			"description": description
		})

	return fallback_offers

func _on_commune_offer_chosen(tile_id: String) -> void:
	var chosen_id := str(tile_id)
	if chosen_id.is_empty():
		return

	_current_tile_id = chosen_id
	_current_tile_name = chosen_id
	if _tile_defs_by_id.has(chosen_id):
		var def := _tile_defs_by_id[chosen_id]
		_current_tile_name = str(def.get("name", chosen_id))

	_phase = PHASE_PLAYER
	_commune_active = false
	if is_instance_valid(_commune_window):
		_commune_window.close_commune()
	_update_tile_panel()
	_update_turn_and_phase_labels()
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

func _get_decay_totem_index_at(q: int, r: int) -> int:
		for i in _decay_totems.size():
				var data := _decay_totems[i]
				if not bool(data.get("alive", true)):
						continue
				if int(data.get("q", -1)) == q and int(data.get("r", -1)) == r:
						return i
		return -1

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

		_check_player_totem_for_decay()

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

func _check_player_totem_for_decay() -> void:
		if _player_totem_q < 0 or _player_totem_r < 0:
				return
		if _player_totem_r < 0 or _player_totem_r >= GRID_HEIGHT:
				return
		if _player_totem_q < 0 or _player_totem_q >= GRID_WIDTH:
				return

		if _decay_grid[_player_totem_r][_player_totem_q]:
				print("ShroudWorld: player Totem consumed by Decay at (%d, %d)" % [
						_player_totem_q,
						_player_totem_r
				])
				_trigger_run_defeat("totem_consumed")

func _has_any_valid_tile_placements() -> bool:
		for r in GRID_HEIGHT:
				for q in GRID_WIDTH:
						if _tiles[r][q] != "":
								continue
						if _decay_grid[r][q]:
								continue

						var neighbors := [
								Vector2i(q - 1, r),
								Vector2i(q + 1, r),
								Vector2i(q, r - 1),
								Vector2i(q, r + 1)
						]
						for v in neighbors:
								var nq := v.x
								var nr := v.y
								if nq < 0 or nq >= GRID_WIDTH or nr < 0 or nr >= GRID_HEIGHT:
										continue
								if _decay_grid[nr][nq]:
										continue
								if _tiles[nr][nq] != "":
										return true

		return false

func _build_player_battle_team_from_sprouts() -> Array:
	var team: Array = []
	for sprout in _sprouts:
		if bool(sprout.get("dead", false)):
			continue

		var current_hp := int(sprout.get("current_hp", sprout.get("max_hp", 0)))
		if current_hp <= 0:
			continue

		var name := str(sprout.get("id", "Sprout"))
		var level := int(sprout.get("level", 1))
		var max_hp := int(sprout.get("max_hp", 60 + level * 10))
		current_hp = clamp(current_hp, 0, max_hp)
		var attack := 10 + level * 2
		var cooldown := 3.0
		var unit := {
			"instance_id": sprout.get("instance_id", -1),
			"name": name,
			"max_hp": max_hp,
			"hp": current_hp,
			"attack": attack,
			"cooldown": cooldown,
			"cooldown_remaining": randf_range(0.0, cooldown),
			"is_player": true
		}
		team.append(unit)
	return team

func _build_enemy_battle_team(mode: String, q: int, r: int) -> Array:
		var difficulty_key := _get_current_difficulty_key()

		var type_key := "normal"
		if mode == "decay_totem":
				type_key = "totem"

		if mode == "debug":
				type_key = "normal"

		var diff_config := ENEMY_CONFIG.get(difficulty_key, null)
		if diff_config == null:
				diff_config = ENEMY_CONFIG["easy"]

		var type_config := diff_config.get(type_key, null)
		if type_config == null:
				type_config = diff_config["normal"]

		var min_units := int(type_config.get("min_units", 3))
		var max_units := int(type_config.get("max_units", 3))
		var hp_min := int(type_config.get("hp_min", 50))
		var hp_max := int(type_config.get("hp_max", 80))
		var attack_min := int(type_config.get("attack_min", 8))
		var attack_max := int(type_config.get("attack_max", 12))
		var cooldown_min := float(type_config.get("cooldown_min", 3.0))
		var cooldown_max := float(type_config.get("cooldown_max", 4.0))

		var unit_count := randi_range(min_units, max_units)

		var team: Array = []
		for i in unit_count:
				var hp := randi_range(hp_min, hp_max)
				var attack := randi_range(attack_min, attack_max)
				var cooldown := randf_range(cooldown_min, cooldown_max)

				var unit := {
						"instance_id": -1,
						"name": "",
						"max_hp": hp,
						"hp": hp,
						"attack": attack,
						"cooldown": cooldown,
						"cooldown_remaining": randf_range(0.0, cooldown),
						"is_player": false
				}

				if mode == "decay_totem":
						unit["name"] = "Totem Smog_%d" % i
				elif mode == "decay_normal":
						unit["name"] = "Decay Smog_%d" % i
				else:
						unit["name"] = "Smog_%d" % i

				team.append(unit)

		print("ShroudWorld: built enemy team (mode=%s, difficulty=%s, count=%d)" % [
				mode,
				difficulty_key,
				team.size()
		])

		return team

func _can_attack_decay_at(q: int, r: int) -> bool:
	if r < 0 or r >= GRID_HEIGHT or q < 0 or q >= GRID_WIDTH:
		return false
	if not _decay_grid[r][q]:
		return false

	var neighbors := [
		Vector2i(q - 1, r),
		Vector2i(q + 1, r),
		Vector2i(q, r - 1),
		Vector2i(q, r + 1)
	]

	for neighbor in neighbors:
		var nq := neighbor.x
		var nr := neighbor.y
		if nq < 0 or nq >= GRID_WIDTH or nr < 0 or nr >= GRID_HEIGHT:
			continue
		if _decay_grid[nr][nq]:
			continue
		if _tiles[nr][nq] != "":
			return true

	return false

func _start_decay_attack_battle(q: int, r: int) -> void:
	if _battle_overlay_active:
		print("ShroudWorld: battle overlay already active")
		return

	if not is_instance_valid(_battle_overlay_layer):
		print("ShroudWorld: battle overlay layer is not set")
		return

		if not _can_attack_decay_at(q, r):
				print("ShroudWorld: cannot attack decay at (%d, %d)" % [q, r])
				return

		var totem_index := _get_decay_totem_index_at(q, r)
		if totem_index != -1:
				print("ShroudWorld: starting decay attack battle vs Decay Totem at (%d, %d)" % [q, r])
		else:
				print("ShroudWorld: starting decay attack battle vs normal decay at (%d, %d)" % [q, r])

		if not Engine.has_singleton("BattleContext"):
				print("ShroudWorld: cannot start decay battle, BattleContext singleton not found")
				return

	var ctx := BattleContext
	ctx.reset()

	var living_count := _get_living_sprout_count()
	if living_count <= 0:
		print("ShroudWorld: no living sprouts available to fight decay")
		return

	var player_team := _build_player_battle_team_from_sprouts()
	if player_team.is_empty():
		print("ShroudWorld: no living sprouts available to fight")
		return

		var enemy_mode := "decay_normal"
		if totem_index != -1:
				enemy_mode = "decay_totem"

		var enemy_team := _build_enemy_battle_team(enemy_mode, q, r)

	ctx.player_team = player_team
	ctx.enemy_team = enemy_team
	ctx.debug_print()

	var scene := load("res://scenes/world/BattleWindow.tscn")
	if scene == null or not (scene is PackedScene):
		print("ShroudWorld: failed to load BattleWindow.tscn")
		return

	_pending_battle_mode = "decay_attack"
	_pending_battle_target_q = q
	_pending_battle_target_r = r

	_battle_window = (scene as PackedScene).instantiate() as Control
	if _battle_window == null:
		print("ShroudWorld: failed to instance BattleWindow")
		_pending_battle_mode = ""
		_pending_battle_target_q = -1
		_pending_battle_target_r = -1
		return

	_battle_overlay_layer.add_child(_battle_window)
	_battle_overlay_layer.visible = true
	_battle_overlay_active = true

	if _battle_window.has_signal("battle_finished"):
		(_battle_window as Node).connect("battle_finished", Callable(self, "_on_battle_finished"))

	print("ShroudWorld: started decay attack battle at (%d, %d)" % [q, r])

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
				player_team = _build_enemy_battle_team("debug", -1, -1)
				for unit in player_team:
						unit["is_player"] = true

		var enemy_team := _build_enemy_battle_team("debug", -1, -1)

	ctx.player_team = player_team
	ctx.enemy_team = enemy_team
	ctx.debug_print()

	var scene := load("res://scenes/world/BattleWindow.tscn")
	if scene == null or not (scene is PackedScene):
		print("ShroudWorld: failed to load BattleWindow.tscn")
		return

	_pending_battle_mode = "debug"
	_pending_battle_target_q = -1
	_pending_battle_target_r = -1

	_battle_window = (scene as PackedScene).instantiate() as Control
	if _battle_window == null:
		print("ShroudWorld: failed to instance BattleWindow")
		_pending_battle_mode = ""
		_pending_battle_target_q = -1
		_pending_battle_target_r = -1
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

	for unit in player_team:
		if not bool(unit.get("is_player", true)):
			continue

		var instance_id := int(unit.get("instance_id", -1))
		if instance_id < 0:
			continue

				for sprout in _sprouts:
						if int(sprout.get("instance_id", -1)) == instance_id:
								var new_hp := int(unit.get("hp", sprout.get("current_hp", 0)))
								var was_dead_before := bool(sprout.get("dead", false))
								sprout["current_hp"] = new_hp
								if new_hp <= 0:
										sprout["dead"] = true
										if not was_dead_before:
												_run_sprouts_fallen += 1
								else:
										sprout["dead"] = false
								break

	_update_sprout_registry_view()

	if _pending_battle_mode == "decay_attack":
		_apply_decay_attack_result(result)

	if is_instance_valid(_battle_window):
		_battle_window.queue_free()
		_battle_window = null

	if is_instance_valid(_battle_overlay_layer):
		_battle_overlay_layer.visible = false

	_battle_overlay_active = false
	_pending_battle_mode = ""
	_pending_battle_target_q = -1
	_pending_battle_target_r = -1

func _apply_decay_attack_result(result: String) -> void:
	var q := _pending_battle_target_q
	var r := _pending_battle_target_r

	if q < 0 or r < 0 or q >= GRID_WIDTH or r >= GRID_HEIGHT:
		print("ShroudWorld: no valid decay target stored for battle result")
		return

		if result == "victory":
				if _decay_grid[r][q]:
						_decay_grid[r][q] = false
						_decay_count = max(_decay_count - 1, 0)
						print("ShroudWorld: cleansed decay at (%d, %d) after victory" % [q, r])

				var totem_index := _get_decay_totem_index_at(q, r)
				if totem_index != -1:
						var totem := _decay_totems[totem_index]
						if bool(totem.get("alive", true)):
								totem["alive"] = false
								_decay_totems[totem_index] = totem
								_alive_decay_totem_count -= 1
								print("ShroudWorld: destroyed Decay Totem at (%d, %d). Remaining = %d" % [
										q,
										r,
										_alive_decay_totem_count
								])
								if _alive_decay_totem_count <= 0:
										_trigger_run_victory()
		elif result == "defeat":
				var neighbors := [
						Vector2i(q - 1, r),
						Vector2i(q + 1, r),
						Vector2i(q, r - 1),
			Vector2i(q, r + 1)
		]
		var candidates: Array = []
		for neighbor in neighbors:
			var nq := neighbor.x
			var nr := neighbor.y
			if nq < 0 or nq >= GRID_WIDTH or nr < 0 or nr >= GRID_HEIGHT:
				continue
			if _decay_grid[nr][nq]:
				continue
			if _tiles[nr][nq] != "":
				candidates.append(neighbor)

		if not candidates.is_empty():
			var chosen: Vector2i = candidates[randi() % candidates.size()]
			var cq := chosen.x
			var cr := chosen.y
			print("ShroudWorld: decay spreads to Life tile at (%d, %d) after defeat" % [cq, cr])
			_tiles[cr][cq] = ""
			_overgrowth_age[cr][cq] = 0
						if not _decay_grid[cr][cq]:
								_decay_grid[cr][cq] = true
								_decay_count += 1

		_check_player_totem_for_decay()

		if is_instance_valid(_hex_grid):
				_hex_grid.update()
