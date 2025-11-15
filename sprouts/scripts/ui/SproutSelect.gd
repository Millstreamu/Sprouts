extends Control
class_name SproutSelectScreen

@export var scroll_container_path: NodePath
@export var sprout_grid_path: NodePath
@export var selected_list_path: NodePath
@export var back_button_path: NodePath
@export var continue_button_path: NodePath
@export var status_label_path: NodePath
@export var card_scene: PackedScene

@onready var _scroll: ScrollContainer = get_node(scroll_container_path) as ScrollContainer
@onready var _sprout_grid: GridContainer = get_node(sprout_grid_path) as GridContainer
@onready var _selected_list: VBoxContainer = get_node(selected_list_path) as VBoxContainer
@onready var _back_button: Button = get_node(back_button_path) as Button
@onready var _continue_button: Button = get_node(continue_button_path) as Button
@onready var _status_label: Label = get_node(status_label_path) as Label

const MAX_SELECTED_SPROUTS: int = 3

var _sprout_data: Array = []
var _cards: Array[Control] = []
var _selected_index: int = 0
var _selected_sprout_ids: Array[String] = []

var _dummy_sprouts: Array = [
	{
		"id": "sprout.grumbler",
		"name": "Grumbler",
		"unlocked": true
	},
	{
		"id": "sprout.amber_knight",
		"name": "Amber Knight",
		"unlocked": true
	},
	{
		"id": "sprout.moss_golem",
		"name": "Moss Golem",
		"unlocked": true
	},
	{
		"id": "sprout.wistock",
		"name": "Wistock",
		"unlocked": false
	},
	{
		"id": "sprout.mirefen",
		"name": "Mirefen",
		"unlocked": false
	},
	{
		"id": "sprout.ember_frog",
		"name": "Ember Frog",
		"unlocked": true
	}
]

func _ready() -> void:
	_sprout_data = _dummy_sprouts
	_back_button.pressed.connect(_go_back_to_totem_select)
	_continue_button.pressed.connect(_continue_if_ready)
	_continue_button.disabled = true
	_populate_sprouts()
	_update_selected_list()
	_update_status_label()
	print("SproutSelect: ready")

func _populate_sprouts() -> void:
	for child in _sprout_grid.get_children():
		child.queue_free()
	_cards.clear()
	_selected_index = 0

	if card_scene == null:
		print("SproutSelect: card_scene is NULL, no cards will be created")
		return

	for entry in _sprout_data:
		var card := card_scene.instantiate() as Control
		_sprout_grid.add_child(card)
		_cards.append(card)

		var name_label: Label = null
		if card.has_node("NameLabel"):
			name_label = card.get_node("NameLabel") as Label

		var sprout_name := str(entry.get("name", ""))
		var unlocked := entry.get("unlocked", false)
		var id := str(entry.get("id", ""))

		if name_label:
			if unlocked:
				name_label.text = sprout_name
			else:
				name_label.text = sprout_name + " (Locked)"

		card.set_meta("sprout_id", id)
		card.set_meta("unlocked", unlocked)

	_update_selection()

func _update_selection() -> void:
	if _cards.is_empty():
		_selected_index = 0
		return
	_selected_index = clampi(_selected_index, 0, _cards.size() - 1)
	print("SproutSelect: selected index = %d" % _selected_index)
	_refresh_card_visuals()

func _move_selection(delta: int) -> void:
	if _cards.is_empty():
		return
	_selected_index += delta
	_selected_index = clampi(_selected_index, 0, _cards.size() - 1)
	_update_selection()

func _refresh_card_visuals() -> void:
	for card in _cards:
		var id: String = str(card.get_meta("sprout_id", ""))
		var name_label: Label = null
		if card.has_node("NameLabel"):
			name_label = card.get_node("NameLabel") as Label

		if name_label:
			var base_name := name_label.text
			if base_name.ends_with(" [SELECTED]"):
				base_name = base_name.substr(0, base_name.length() - " [SELECTED]".length())
			if id in _selected_sprout_ids:
				name_label.text = base_name + " [SELECTED]"
			else:
				name_label.text = base_name

func _toggle_selected_current() -> void:
	if _cards.is_empty():
		return
	var card: Control = _cards[_selected_index]
	var id: String = str(card.get_meta("sprout_id", ""))
	var unlocked: bool = card.get_meta("unlocked", false)

	if not unlocked:
		print("SproutSelect: cannot select locked sprout: %s" % id)
		return

	if id in _selected_sprout_ids:
		_selected_sprout_ids.erase(id)
		print("SproutSelect: deselected %s" % id)
	else:
		if _selected_sprout_ids.size() >= MAX_SELECTED_SPROUTS:
			print("SproutSelect: cannot select more than %d sprouts" % MAX_SELECTED_SPROUTS)
			return
		_selected_sprout_ids.append(id)
		print("SproutSelect: selected %s" % id)

	_refresh_card_visuals()
	_update_selected_list()
	_update_continue_state()
	_update_status_label()

func _update_selected_list() -> void:
	for child in _selected_list.get_children():
		if child != null:
			child.queue_free()

	var label := Label.new()
	label.text = "Selected Sprouts: " + ", ".join(_selected_sprout_ids)
	_selected_list.add_child(label)

func _update_continue_state() -> void:
	var can_continue := _selected_sprout_ids.size() == MAX_SELECTED_SPROUTS
	_continue_button.disabled = not can_continue

func _update_status_label() -> void:
	if _selected_sprout_ids.size() < MAX_SELECTED_SPROUTS:
		_status_label.text = "Select %d sprouts (Space to toggle, P to continue)" % MAX_SELECTED_SPROUTS
	else:
		_status_label.text = "Press P or Continue to start run"

func _continue_if_ready() -> void:
	if _selected_sprout_ids.size() != MAX_SELECTED_SPROUTS:
		print("SproutSelect: need exactly %d sprouts to continue" % MAX_SELECTED_SPROUTS)
		_update_status_label()
		return

	var run_context_path := NodePath("/root/RunContext")
	if get_tree().has_node(run_context_path):
		var ctx := get_tree().get_node(run_context_path) as RunContext
		ctx.selected_sprout_ids = _selected_sprout_ids.duplicate()
		ctx.debug_print()
	else:
		print("SproutSelect: WARNING - RunContext singleton not found")

	print("SproutSelect: CONTINUE with sprouts: %s" % ", ".join(_selected_sprout_ids))
	get_tree().change_scene_to_file("res://scenes/world/ShroudWorld.tscn")

func _go_back_to_totem_select() -> void:
	print("SproutSelect: back to TotemSelect")
	get_tree().change_scene_to_file("res://scenes/run_setup/TotemSelect.tscn")

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_go_back_to_totem_select()
		accept_event()
		return

	if Input.is_action_just_pressed("ui_accept"):
		_toggle_selected_current()
		accept_event()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == Key.KEY_P:
			_continue_if_ready()
			accept_event()
			return

	if Input.is_action_just_pressed("ui_left"):
		_move_selection(-1)
		accept_event()
	elif Input.is_action_just_pressed("ui_right"):
		_move_selection(1)
		accept_event()
	elif Input.is_action_just_pressed("ui_up"):
		_move_selection(-4)
		accept_event()
	elif Input.is_action_just_pressed("ui_down"):
		_move_selection(4)
		accept_event()
