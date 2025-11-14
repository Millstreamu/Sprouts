extends Control
class_name ChallengesScreen

@export var challenges_list_path: NodePath
@export var back_button_path: NodePath

@onready var _challenges_list: VBoxContainer = get_node(challenges_list_path) as VBoxContainer
@onready var _back_button: Button = get_node(back_button_path) as Button

var _selected_index: int = 0
var _challenge_entries: Array[Control] = []

func _ready() -> void:
	_back_button.pressed.connect(_on_back_button_pressed)
	_populate_dummy_challenges()
	_update_selection()

func _populate_dummy_challenges() -> void:
	for child in _challenges_list.get_children():
		child.queue_free()
	_challenge_entries.clear()

	var challenges: Array[Dictionary] = [
		{"name": "Win a run with only Earth Sprouts", "reward": "Reward: Unlock Earth Totem"},
		{"name": "Complete a run without damage", "reward": "Reward: 100 Crystals"},
		{"name": "Defeat the Forest Guardian", "reward": "Reward: Forest Tile"},
		{"name": "Harvest 50 resources in one run", "reward": "Reward: Resource Booster"},
		{"name": "Unlock all basic Sprouts", "reward": "Reward: Mystery Seed"},
		{"name": "Win on Hard difficulty", "reward": "Reward: Golden Totem"},
		{"name": "Complete 5 daily challenges", "reward": "Reward: Challenge Banner"},
	]

	for challenge in challenges:
		var entry := HBoxContainer.new()
		entry.focus_mode = Control.FOCUS_NONE

		var name_label := Label.new()
		name_label.text = challenge["name"]
		entry.add_child(name_label)

		var reward_label := Label.new()
		reward_label.text = challenge["reward"]
		entry.add_child(reward_label)

		_challenges_list.add_child(entry)
		_challenge_entries.append(entry)

func _update_selection() -> void:
	if _challenge_entries.is_empty():
		_selected_index = 0
		return
	_selected_index = clampi(_selected_index, 0, _challenge_entries.size() - 1)
	print("Challenges: selected index %d" % _selected_index)

func _move_selection(delta: int) -> void:
	if _challenge_entries.is_empty():
		return
	_selected_index += delta
	_selected_index = clampi(_selected_index, 0, _challenge_entries.size() - 1)
	_update_selection()

func _activate_selected() -> void:
	if _challenge_entries.is_empty():
		return
	print("Challenges: activated challenge index %d" % _selected_index)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		_move_selection(-1)
	elif event.is_action_pressed("ui_down"):
		_move_selection(1)
	elif event.is_action_pressed("ui_accept"):
		_activate_selected()
	elif event.is_action_pressed("ui_cancel"):
		_go_back_to_main_menu()

func _on_back_button_pressed() -> void:
	_go_back_to_main_menu()

func _go_back_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/meta/MainMenu.tscn")
