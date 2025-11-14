extends Control
class_name MainMenu

@export var start_run_button_path: NodePath
@export var collection_button_path: NodePath
@export var challenges_button_path: NodePath
@export var settings_button_path: NodePath
@export var exit_button_path: NodePath

@onready var _start_run_button: Button = get_node(start_run_button_path) as Button
@onready var _collection_button: Button = get_node(collection_button_path) as Button
@onready var _challenges_button: Button = get_node(challenges_button_path) as Button
@onready var _settings_button: Button = get_node(settings_button_path) as Button
@onready var _exit_button: Button = get_node(exit_button_path) as Button

var _selected_index: int = 0
var _buttons: Array[Button] = []

func _ready() -> void:
	_buttons = [
		_start_run_button,
		_collection_button,
		_challenges_button,
		_settings_button,
		_exit_button,
	]
	_update_selection()
	print("MainMenu: ready")

func _update_selection() -> void:
	if _buttons.is_empty():
		return
	_selected_index = clampi(_selected_index, 0, _buttons.size() - 1)
	_buttons[_selected_index].grab_focus()

func _move_selection(delta: int) -> void:
	_selected_index += delta
	_selected_index = clampi(_selected_index, 0, _buttons.size() - 1)
	_update_selection()

func _activate_selection() -> void:
	match _selected_index:
		0:
			_on_start_run()
		1:
			_on_collection()
		2:
			_on_challenges()
		3:
			_on_settings()
		4:
			_on_exit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		_move_selection(-1)
	elif event.is_action_pressed("ui_down"):
		_move_selection(1)
	elif event.is_action_pressed("ui_accept"):
		_activate_selection()

func _on_start_run() -> void:
	print("MainMenu: Start Run selected")
	# TODO: change scene to run setup, e.g.:
	# get_tree().change_scene_to_file("res://scenes/run_setup/TotemSelect.tscn")

func _on_collection() -> void:
	print("MainMenu: Collection selected")
	get_tree().change_scene_to_file("res://scenes/meta/Collection.tscn")

func _on_challenges() -> void:
	print("MainMenu: Challenges selected")
	get_tree().change_scene_to_file("res://scenes/meta/Challenges.tscn")

func _on_settings() -> void:
	print("MainMenu: Settings selected")
	# TODO: change scene to Settings scene
	# get_tree().change_scene_to_file("res://scenes/meta/Settings.tscn")

func _on_exit() -> void:
	print("MainMenu: Exit selected")
	get_tree().quit()
