extends Control
class_name WorldHUD

@export var nature_label_path: NodePath
@export var earth_label_path: NodePath
@export var water_label_path: NodePath
@export var souls_label_path: NodePath
@export var next_turn_button_path: NodePath

@onready var _nature_label: Label = get_node(nature_label_path) as Label
@onready var _earth_label: Label = get_node(earth_label_path) as Label
@onready var _water_label: Label = get_node(water_label_path) as Label
@onready var _souls_label: Label = get_node(souls_label_path) as Label
@onready var _next_turn_button: Button = get_node(next_turn_button_path) as Button

signal next_turn_requested

func _ready() -> void:
    if is_instance_valid(_next_turn_button):
        _next_turn_button.text = "RL - Next Turn"
        _next_turn_button.pressed.connect(_on_next_turn_pressed)
    _update_all_resources(0, 0, 0, 0)

func _on_next_turn_pressed() -> void:
    emit_signal("next_turn_requested")

func _update_label(label: Label, prefix: String, value: int) -> void:
    if not is_instance_valid(label):
        return
    label.text = "%s: %d" % [prefix, value]

func _update_all_resources(nature_value: int, earth_value: int, water_value: int, souls_value: int) -> void:
    _update_label(_nature_label, "Nature", nature_value)
    _update_label(_earth_label, "Earth", earth_value)
    _update_label(_water_label, "Water", water_value)
    _update_label(_souls_label, "Soul Seeds", souls_value)

func set_resources(nature_value: int, earth_value: int, water_value: int, souls_value: int) -> void:
    _update_all_resources(nature_value, earth_value, water_value, souls_value)
