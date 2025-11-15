extends Control
class_name TotemSelectScreen

@export var totem_name_label_path: NodePath
@export var totem_description_label_path: NodePath
@export var prev_totem_button_path: NodePath
@export var next_totem_button_path: NodePath
@export var difficulty_container_path: NodePath
@export var back_button_path: NodePath
@export var status_label_path: NodePath

@onready var _totem_name_label: Label = get_node(totem_name_label_path) as Label
@onready var _totem_description_label: Label = get_node(totem_description_label_path) as Label
@onready var _prev_totem_button: Button = get_node(prev_totem_button_path) as Button
@onready var _next_totem_button: Button = get_node(next_totem_button_path) as Button
@onready var _difficulty_container: HBoxContainer = get_node(difficulty_container_path) as HBoxContainer
@onready var _back_button: Button = get_node(back_button_path) as Button
@onready var _status_label: Label = get_node(status_label_path) as Label
@onready var _difficulty_buttons: Array[Button] = []

const DIFF_EASY: int = 0
const DIFF_MEDIUM: int = 1
const DIFF_HARD: int = 2

var _totem_entries: Array = []
var _current_totem_index: int = 0
var _selected_difficulty: int = -1
var _in_tab_mode: bool = true
var _can_continue: bool = false

func _ready() -> void:
    _load_totems_from_meta()
    _collect_difficulty_buttons()
    _prev_totem_button.pressed.connect(func() -> void:
        _change_totem(-1)
    )
    _next_totem_button.pressed.connect(func() -> void:
        _change_totem(1)
    )
    _back_button.pressed.connect(_go_back_to_main_menu)
    _enter_totem_mode()
    _current_totem_index = 0
    _selected_difficulty = -1
    _can_continue = false
    _update_totem_display()
    _update_difficulty_focus()
    _update_status_label()
    print("TotemSelect: ready")

func _load_totems_from_meta() -> void:
    _totem_entries.clear()
    if not Engine.has_singleton("MetaProgress"):
        print("TotemSelect: MetaProgress not available, using empty list")
        return
    var meta := MetaProgress
    _totem_entries = meta.get_all_totem_entries()
    print("TotemSelect: loaded %d totems from MetaProgress" % _totem_entries.size())

func _collect_difficulty_buttons() -> void:
    _difficulty_buttons.clear()
    for child in _difficulty_container.get_children():
        if child is Button:
            var button := child as Button
            button.toggle_mode = true
            button.focus_mode = Control.FOCUS_ALL
            button.button_pressed = false
            var captured_index := _difficulty_buttons.size()
            button.pressed.connect(func() -> void:
                _on_difficulty_button_pressed(captured_index)
            )
            _difficulty_buttons.append(button)

func _on_difficulty_button_pressed(index: int) -> void:
    if index < 0 or index >= _difficulty_buttons.size():
        return
    if _in_tab_mode:
        _enter_difficulty_mode()
    _selected_difficulty = index
    _can_continue = false
    print("TotemSelect: difficulty index = %d" % index)
    _update_difficulty_focus()
    _update_status_label()

func _update_totem_display() -> void:
    if _totem_entries.is_empty():
        _totem_name_label.text = "No Totems"
        _totem_description_label.text = ""
        return
    _current_totem_index = clampi(_current_totem_index, 0, _totem_entries.size() - 1)
    var current: Dictionary = _totem_entries[_current_totem_index]
    var unlocked := bool(current.get("unlocked", false))
    if unlocked:
        var name_text: String = str(current.get("name", "Unknown Totem"))
        _totem_name_label.text = name_text
        _totem_description_label.text = str(current.get("description", ""))
    else:
        _totem_name_label.text = "Locked"
        _totem_description_label.text = ""

func _update_status_label() -> void:
    if _in_tab_mode and _selected_difficulty == -1:
        _status_label.text = "Select a Totem (Left/Right, Space to confirm)"
        return
    if not _in_tab_mode and _selected_difficulty == -1:
        _status_label.text = "Select Difficulty (Left/Right, Space to confirm)"
        return
    if _selected_difficulty != -1:
        _status_label.text = "Press P to continue"

func _update_difficulty_focus() -> void:
    for i in range(_difficulty_buttons.size()):
        var button := _difficulty_buttons[i]
        button.button_pressed = i == _selected_difficulty and _selected_difficulty != -1
        if i == _selected_difficulty and _selected_difficulty != -1:
            button.grab_focus()
        elif button.has_focus():
            button.release_focus()

func _enter_totem_mode() -> void:
    _in_tab_mode = true
    _can_continue = false
    _selected_difficulty = -1
    _update_difficulty_focus()
    print("TotemSelect: entered TOTEM mode")
    _update_status_label()

func _enter_difficulty_mode() -> void:
    _in_tab_mode = false
    _can_continue = false
    print("TotemSelect: entered DIFFICULTY mode")
    _update_difficulty_focus()
    _update_status_label()

func _change_totem(delta: int) -> void:
    if _totem_entries.is_empty():
        return
    var new_index := _current_totem_index + delta
    var totem_count := _totem_entries.size()
    if totem_count == 0:
        return
    new_index = (new_index % totem_count + totem_count) % totem_count
    _current_totem_index = new_index
    print("TotemSelect: totem index = %d" % _current_totem_index)
    _update_totem_display()
    var current: Dictionary = _totem_entries[_current_totem_index]
    _can_continue = false
    if not current.get("unlocked", false):
        _selected_difficulty = -1
    _update_difficulty_focus()
    _update_status_label()

func _change_difficulty(delta: int) -> void:
    if _difficulty_buttons.is_empty():
        return
    if _selected_difficulty == -1:
        _selected_difficulty = DIFF_EASY
    else:
        var max_index := _difficulty_buttons.size() - 1
        _selected_difficulty = clampi(_selected_difficulty + delta, DIFF_EASY, max_index)
    print("TotemSelect: difficulty index = %d" % _selected_difficulty)
    _update_difficulty_focus()
    _can_continue = false
    _update_status_label()

func _confirm_totem() -> void:
    if _totem_entries.is_empty():
        return
    var current: Dictionary = _totem_entries[_current_totem_index]
    if not current.get("unlocked", false):
        print("TotemSelect: selected totem is locked")
        return
    print("TotemSelect: totem confirmed: %s" % current.get("id", ""))
    _selected_difficulty = -1
    _update_difficulty_focus()
    _enter_difficulty_mode()

func _confirm_difficulty() -> void:
    if _selected_difficulty < DIFF_EASY or _selected_difficulty > DIFF_HARD:
        print("TotemSelect: no difficulty selected yet")
        return
    _can_continue = true
    print("TotemSelect: difficulty confirmed: %d" % _selected_difficulty)
    _update_status_label()

func _continue_if_ready() -> void:
    if not _can_continue:
        return
    if _totem_entries.is_empty():
        return
    var current: Dictionary = _totem_entries[_current_totem_index]
    var totem_id: String = str(current.get("id", ""))
    if not bool(current.get("unlocked", false)):
        print("TotemSelect: cannot continue with locked totem %s" % totem_id)
        return
    var run_context_path := NodePath("/root/RunContext")
    var ctx := get_node_or_null(run_context_path) as RunContext
    if ctx:
        ctx.selected_totem_id = totem_id
        ctx.selected_difficulty = _selected_difficulty
        ctx.selected_sprout_ids.clear()
        ctx.debug_print()
    else:
        print("TotemSelect: WARNING - RunContext singleton not found")
    print("TotemSelect: CONTINUE with totem %s, difficulty %d" % [totem_id, _selected_difficulty])
    get_tree().change_scene_to_file("res://scenes/run_setup/SproutSelect.tscn")

func _go_back_to_main_menu() -> void:
    print("TotemSelect: back to main menu")
    get_tree().change_scene_to_file("res://scenes/meta/MainMenu.tscn")

func _input(event: InputEvent) -> void:
    if Input.is_action_just_pressed("ui_cancel"):
        if _in_tab_mode:
            _go_back_to_main_menu()
        else:
            _enter_totem_mode()
        accept_event()
        return
    if Input.is_action_just_pressed("ui_accept"):
        if _in_tab_mode:
            _confirm_totem()
        else:
            _confirm_difficulty()
        accept_event()
        return
    if event is InputEventKey and event.pressed and not event.echo:
        var key_event := event as InputEventKey
        if key_event.keycode == Key.KEY_P:
            _continue_if_ready()
            accept_event()
            return
    if _in_tab_mode:
        if Input.is_action_just_pressed("ui_left"):
            _change_totem(-1)
            accept_event()
        elif Input.is_action_just_pressed("ui_right"):
            _change_totem(1)
            accept_event()
    else:
        if Input.is_action_just_pressed("ui_left"):
            _change_difficulty(-1)
            accept_event()
        elif Input.is_action_just_pressed("ui_right"):
            _change_difficulty(1)
            accept_event()
