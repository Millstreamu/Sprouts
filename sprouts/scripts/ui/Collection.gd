extends Control
class_name CollectionScreen

@export var tabs_container_path: NodePath
@export var card_grid_path: NodePath
@export var back_button_path: NodePath

@onready var _tabs_container: HBoxContainer = get_node(tabs_container_path) as HBoxContainer
@onready var _card_grid: GridContainer = get_node(card_grid_path) as GridContainer
@onready var _back_button: Button = get_node(back_button_path) as Button
@onready var _tab_buttons: Array[Button] = _get_tab_buttons()

var _current_tab_index: int = 0
var _selected_card_index: int = 0
var _cards: Array[Control] = []

func _ready() -> void:
	_back_button.pressed.connect(_on_back_button_pressed)
	_populate_dummy_data()
	_focus_current_tab()

func _get_tab_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	for child in _tabs_container.get_children():
		if child is Button:
			buttons.append(child as Button)
	return buttons

func _populate_dummy_data() -> void:
	for child in _card_grid.get_children():
		child.queue_free()
	_cards.clear()

	var tab_names: Array[String] = _get_tab_names()
	var counts: Array[int] = [8, 6, 10]
	_current_tab_index = clampi(_current_tab_index, 0, counts.size() - 1)
	var tab_name: String = tab_names[_current_tab_index]
	var card_count: int = counts[_current_tab_index]

	for index in card_count:
		var card_button := Button.new()
		card_button.text = "%s %d" % [tab_name, index + 1]
		card_button.focus_mode = Control.FOCUS_ALL
		card_button.pressed.connect(_on_card_pressed.bind(index))
		_card_grid.add_child(card_button)
		_cards.append(card_button)

	_selected_card_index = 0
	_update_card_focus()

func _focus_current_tab() -> void:
	if _tab_buttons.is_empty():
		return
	_current_tab_index = clampi(_current_tab_index, 0, _tab_buttons.size() - 1)
	_tab_buttons[_current_tab_index].grab_focus()

func _change_tab(delta: int) -> void:
	if _tab_buttons.is_empty():
		return
	_current_tab_index += delta
	_current_tab_index = clampi(_current_tab_index, 0, _tab_buttons.size() - 1)
	_populate_dummy_data()
	_focus_current_tab()

func _move_card_selection(delta: int) -> void:
	if _cards.is_empty():
		return
	_selected_card_index += delta
	_selected_card_index = clampi(_selected_card_index, 0, _cards.size() - 1)
	print("Collection: selected card index %d" % _selected_card_index)
	_update_card_focus()

func _update_card_focus() -> void:
	if _cards.is_empty():
		return
	_selected_card_index = clampi(_selected_card_index, 0, _cards.size() - 1)
	var card := _cards[_selected_card_index]
	if card:
		card.grab_focus()

func _on_card_pressed(card_index: int) -> void:
	if _cards.is_empty():
		return
	_selected_card_index = clampi(card_index, 0, _cards.size() - 1)
	_update_card_focus()
	var tab_name: String = _get_tab_name()
	print("Collection: Activated %s card %d" % [tab_name, _selected_card_index + 1])

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_change_tab(-1)
	elif event.is_action_pressed("ui_right"):
		_change_tab(1)
	elif event.is_action_pressed("ui_up"):
		_move_card_selection(-4)
	elif event.is_action_pressed("ui_down"):
		_move_card_selection(4)
	elif event.is_action_pressed("ui_accept"):
		_activate_selected_card()
	elif event.is_action_pressed("ui_cancel"):
		_go_back_to_main_menu()

func _activate_selected_card() -> void:
	if _cards.is_empty():
		return
	var tab_name: String = _get_tab_name()
	print("Collection: Activated %s card %d" % [tab_name, _selected_card_index + 1])

func _on_back_button_pressed() -> void:
	_go_back_to_main_menu()

func _go_back_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/meta/MainMenu.tscn")

func _get_tab_names() -> Array[String]:
	return ["Totems", "Sprouts", "Tiles"]

func _get_tab_name() -> String:
	var tab_names: Array[String] = _get_tab_names()
	if tab_names.is_empty():
		return ""
	_current_tab_index = clampi(_current_tab_index, 0, tab_names.size() - 1)
	return tab_names[_current_tab_index]
