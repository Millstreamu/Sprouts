extends Control

const MAX_COLUMNS_PER_ROW: int = 2

@export var player_row0_path: NodePath
@export var player_row1_path: NodePath
@export var player_row2_path: NodePath

@export var enemy_row0_path: NodePath
@export var enemy_row1_path: NodePath
@export var enemy_row2_path: NodePath

@export var battle_status_label_path: NodePath
@export var hint_label_path: NodePath

@export var result_overlay_path: NodePath
@export var result_label_path: NodePath

@onready var _player_row0: HBoxContainer = get_node(player_row0_path) as HBoxContainer
@onready var _player_row1: HBoxContainer = get_node(player_row1_path) as HBoxContainer
@onready var _player_row2: HBoxContainer = get_node(player_row2_path) as HBoxContainer

@onready var _enemy_row0: HBoxContainer = get_node(enemy_row0_path) as HBoxContainer
@onready var _enemy_row1: HBoxContainer = get_node(enemy_row1_path) as HBoxContainer
@onready var _enemy_row2: HBoxContainer = get_node(enemy_row2_path) as HBoxContainer

@onready var _battle_status_label: Label = get_node(battle_status_label_path) as Label
@onready var _hint_label: Label = get_node(hint_label_path) as Label

@onready var _result_overlay: Control = get_node(result_overlay_path) as Control
@onready var _result_label: Label = get_node(result_label_path) as Label

var _player_units: Array = []
var _enemy_units: Array = []
var _battle_active: bool = false
var _battle_result: String = ""
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
    _rng.randomize()
    _result_overlay.visible = false
    _hint_label.text = "Space: Continue | Esc: Abort"
    _load_teams_from_context()
    _build_unit_ui()
    _battle_active = true
    _battle_result = ""
    _battle_status_label.text = "Battle in progress..."
    print("BattleWindow: ready, player=%d, enemy=%d" % [_player_units.size(), _enemy_units.size()])

func _process(delta: float) -> void:
    if not _battle_active:
        return

    _update_unit_cooldowns(delta)
    _check_battle_end()

func _input(event: InputEvent) -> void:
    if Input.is_action_just_pressed("ui_cancel"):
        print("BattleWindow: aborting battle, returning to ShroudWorld")
        get_tree().change_scene_to_file("res://scenes/world/ShroudWorld.tscn")
        accept_event()
        return

    if Input.is_action_just_pressed("ui_accept"):
        if not _battle_active:
            print("BattleWindow: battle finished, returning to ShroudWorld")
            get_tree().change_scene_to_file("res://scenes/world/ShroudWorld.tscn")
            accept_event()
            return

func _load_teams_from_context() -> void:
    _player_units.clear()
    _enemy_units.clear()

    if Engine.has_singleton("BattleContext"):
        var ctx := BattleContext
        ctx.debug_print()
        for src in ctx.player_team:
            _player_units.append(src.duplicate(true))
        for src in ctx.enemy_team:
            _enemy_units.append(src.duplicate(true))
    else:
        print("BattleWindow: WARNING - BattleContext singleton not found, using dummy teams")
        _player_units = _make_dummy_team(true)
        _enemy_units = _make_dummy_team(false)

func _make_dummy_team(is_player: bool) -> Array:
    var team: Array = []
    for i in 3:
        var cooldown: float = 3.0
        var unit := {
            "name": (is_player ? "Sprout_%d" : "Smog_%d") % i,
            "max_hp": 50,
            "hp": 50,
            "attack": 8,
            "cooldown": cooldown,
            "cooldown_remaining": _rng.randf_range(0.0, cooldown),
            "is_player": is_player
        }
        team.append(unit)
    return team

func _build_unit_ui() -> void:
    var player_rows := [_player_row0, _player_row1, _player_row2]
    for row in player_rows:
        for child in row.get_children():
            child.queue_free()
    var enemy_rows := [_enemy_row0, _enemy_row1, _enemy_row2]
    for row in enemy_rows:
        for child in row.get_children():
            child.queue_free()

    for unit in _player_units:
        unit["node"] = null
        unit["hp_bar"] = null
    for unit in _enemy_units:
        unit["node"] = null
        unit["hp_bar"] = null

    _layout_units_in_rows(_player_units, true)
    _layout_units_in_rows(_enemy_units, false)

func _layout_units_in_rows(team: Array, is_player: bool) -> void:
    var rows := is_player ? [_player_row0, _player_row1, _player_row2] : [_enemy_row0, _enemy_row1, _enemy_row2]
    for index in team.size():
        var unit := team[index]
        var row_index: int = index / MAX_COLUMNS_PER_ROW
        if row_index >= rows.size():
            continue
        var row := rows[row_index] as HBoxContainer
        if row == null:
            continue

        var unit_box := VBoxContainer.new()
        unit_box.alignment = BoxContainer.ALIGNMENT_CENTER
        unit_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        unit_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER

        var name_label := Label.new()
        name_label.text = str(unit.get("name", "Unit"))
        name_label.horizontal_alignment = HorizontalAlignment.CENTER
        unit_box.add_child(name_label)

        var hp_bar := ProgressBar.new()
        hp_bar.min_value = 0
        hp_bar.max_value = int(unit.get("max_hp", 1))
        hp_bar.value = int(unit.get("hp", 0))
        hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        unit_box.add_child(hp_bar)

        row.add_child(unit_box)

        unit["node"] = unit_box
        unit["hp_bar"] = hp_bar

func _update_unit_cooldowns(delta: float) -> void:
    var all_units: Array = []
    all_units.append_array(_player_units)
    all_units.append_array(_enemy_units)

    for unit in all_units:
        if int(unit.get("hp", 0)) <= 0:
            continue
        var cooldown_remaining: float = float(unit.get("cooldown_remaining", 0.0))
        cooldown_remaining -= delta
        if cooldown_remaining <= 0.0:
            _unit_attack(unit)
            cooldown_remaining += float(unit.get("cooldown", 3.0))
        unit["cooldown_remaining"] = cooldown_remaining

func _unit_attack(attacker: Dictionary) -> void:
    var is_player: bool = bool(attacker.get("is_player", true))
    var targets := _get_alive_units(not is_player)
    if targets.is_empty():
        return

    var target := targets[_rng.randi_range(0, targets.size() - 1)]
    var damage: int = int(attacker.get("attack", 5))
    target["hp"] = int(target.get("hp", 0)) - damage
    if target["hp"] < 0:
        target["hp"] = 0

    var hp_bar := target.get("hp_bar")
    if hp_bar is ProgressBar:
        (hp_bar as ProgressBar).value = target["hp"]

    print("BattleWindow: %s hit %s for %d (hp=%d)" % [
        str(attacker.get("name", "?")),
        str(target.get("name", "?")),
        damage,
        target["hp"]
    ])

func _get_alive_units(is_player: bool) -> Array:
    var result: Array = []
    var source := is_player ? _player_units : _enemy_units
    for unit in source:
        if int(unit.get("hp", 0)) > 0:
            result.append(unit)
    return result

func _check_battle_end() -> void:
    var player_alive := not _get_alive_units(true).is_empty()
    var enemy_alive := not _get_alive_units(false).is_empty()

    if player_alive and enemy_alive:
        return

    _battle_active = false

    if player_alive and not enemy_alive:
        _battle_result = "victory"
        _result_label.text = "Victory"
    elif enemy_alive and not player_alive:
        _battle_result = "defeat"
        _result_label.text = "Defeat"
    else:
        _battle_result = "draw"
        _result_label.text = "Draw"

    _battle_status_label.text = "Battle ended: %s" % _battle_result.capitalize()
    _result_overlay.visible = true
    print("BattleWindow: battle ended with result = ", _battle_result)
