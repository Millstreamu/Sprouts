extends Control
class_name ChallengesScreen

@export var title_label_path: NodePath
@export var challenge_list_path: NodePath
@export var back_button_path: NodePath

@onready var _title_label: Label = get_node(title_label_path) as Label
@onready var _challenge_list: VBoxContainer = get_node(challenge_list_path) as VBoxContainer
@onready var _back_button: Button = get_node(back_button_path) as Button

var _selected_index: int = 0
var _challenge_cache: Array = []

func _ready() -> void:
    if is_instance_valid(_back_button):
        _back_button.pressed.connect(_on_back_pressed)

    if is_instance_valid(_title_label):
        _title_label.text = "Challenges"

    _refresh_challenge_list()
    print("ChallengesScreen: ready")

func _refresh_challenge_list() -> void:
    if not is_instance_valid(_challenge_list):
        return

    var previous_index := _selected_index
    for child in _challenge_list.get_children():
        child.queue_free()

    _challenge_cache.clear()

    if not Engine.has_singleton("ChallengeContext"):
        var label := Label.new()
        label.text = "Challenge system not available."
        _challenge_list.add_child(label)
        _selected_index = 0
        return

    var ctx := ChallengeContext
    _challenge_cache = ctx.get_all_challenges()

    if _challenge_cache.is_empty():
        var label := Label.new()
        label.text = "No challenges defined."
        _challenge_list.add_child(label)
        _selected_index = 0
        return

    _selected_index = clamp(previous_index, 0, _challenge_cache.size() - 1)

    for i in range(_challenge_cache.size()):
        var ch := _challenge_cache[i]
        var label := Label.new()

        var name := str(ch.get("name", ch.get("id", "")))
        var desc := str(ch.get("description", ""))
        var progress := int(ch.get("progress", 0))
        var target := int(ch.get("target", 1))
        var completed := bool(ch.get("completed", false))

        var status_text := "%d / %d" % [progress, target]
        if completed:
            status_text += " (Completed)"

        var text := "%s - %s [%s]" % [name, desc, status_text]

        if i == _selected_index:
            text = "➤ " + text
        else:
            text = "   " + text

        label.text = text
        _challenge_list.add_child(label)

func _move_selection(delta: int) -> void:
    if _challenge_cache.is_empty():
        return
    _selected_index += delta
    _selected_index = clamp(_selected_index, 0, _challenge_cache.size() - 1)
    _refresh_challenge_list()

func _activate_selected() -> void:
    if _challenge_cache.is_empty():
        return
    _selected_index = clamp(_selected_index, 0, _challenge_cache.size() - 1)
    var ch := _challenge_cache[_selected_index]
    print("ChallengesScreen: inspected challenge %s (progress %d / %d, completed=%s)" % [
        str(ch.get("id", "")),
        int(ch.get("progress", 0)),
        int(ch.get("target", 1)),
        str(ch.get("completed", false))
    ])

func _on_back_pressed() -> void:
    print("ChallengesScreen: back to Main Menu")
    get_tree().change_scene_to_file("res://scenes/meta/MainMenu.tscn")

func _unhandled_input(event: InputEvent) -> void:
    if Input.is_action_just_pressed("ui_up"):
        _move_selection(-1)
        accept_event()
        return
    elif Input.is_action_just_pressed("ui_down"):
        _move_selection(1)
        accept_event()
        return
    elif Input.is_action_just_pressed("ui_accept"):
        _activate_selected()
        accept_event()
        return
    elif Input.is_action_just_pressed("ui_cancel"):
        _on_back_pressed()
        accept_event()
        return
