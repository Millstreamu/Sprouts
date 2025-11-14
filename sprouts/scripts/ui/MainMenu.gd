extends Control
class_name MainMenu

@export var menu_container_path: NodePath

@onready var _menu_container: VBoxContainer = get_node(menu_container_path) as VBoxContainer
@onready var _buttons: Array[Button] = []

var _selected_index: int = 0

func _ready() -> void:
	_menu_container = get_node(menu_container_path) as VBoxContainer
	if _menu_container == null:
		print("MainMenu: warning - menu container not found at path %s" % menu_container_path)
		_buttons = []
	else:
		_buttons = _collect_ordered_buttons()
		if _buttons.size() != 5:
			print("MainMenu: warning - expected 5 buttons but found %d" % _buttons.size())
	_selected_index = 0
	_update_selection()
	print("MainMenu: ready")

func _collect_ordered_buttons() -> Array[Button]:
	var ordered_names: Dictionary = {
		"StartRunButton": 0,
		"CollectionButton": 1,
		"ChallengesButton": 2,
		"SettingsButton": 3,
		"ExitButton": 4,
	}
	var ordered_buttons: Array[Button] = []
	ordered_buttons.resize(ordered_names.size())
	if _menu_container:
		for child in _menu_container.get_children():
			if child is Button:
				var button: Button = child
				if ordered_names.has(button.name):
					var index: int = ordered_names[button.name]
					ordered_buttons[index] = button
	var result: Array[Button] = []
	for button in ordered_buttons:
		if button:
			result.append(button)
	return result

func _sync_index_from_focus() -> void:
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused == null:
		return
	var idx: int = _buttons.find(focused)
	if idx != -1:
		_selected_index = idx

func _update_selection() -> void:
	if _buttons.is_empty():
		return
	_selected_index = clamp(_selected_index, 0, _buttons.size() - 1)
	_buttons[_selected_index].grab_focus()

func _move_selection(delta: int) -> void:
	if _buttons.is_empty():
		return
	_selected_index += delta
	_selected_index = clamp(_selected_index, 0, _buttons.size() - 1)
	_update_selection()
	print("MainMenu: selection index = ", _selected_index)

func _activate_selection() -> void:
	if _buttons.is_empty():
		return

	_sync_index_from_focus()

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
		_:
			print("MainMenu: invalid selection index: ", _selected_index)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		_move_selection(-1)
		accept_event()
	elif event.is_action_pressed("ui_down"):
		_move_selection(1)
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		_activate_selection()
		accept_event()


func _on_start_run() -> void:
	print("MainMenu: Start Run selected")
	# TODO: change scene to run setup later

func _on_collection() -> void:
	print("MainMenu: Collection selected")
	get_tree().change_scene_to_file("res://scenes/meta/Collection.tscn")

func _on_challenges() -> void:
	print("MainMenu: Challenges selected")
	# TODO: change scene to Challenges scene later

func _on_settings() -> void:
	print("MainMenu: Settings selected")
	# TODO: change scene to Settings scene later

func _on_exit() -> void:
	print("MainMenu: Exit selected")
	get_tree().quit()
