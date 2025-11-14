extends Control
class_name MainRoot

@export var label_path: NodePath
@onready var _label: Label = get_node(label_path)

func _ready() -> void:
    _label.text = "Sprouts Prototype Loaded"
    _log_startup()

func _log_startup() -> void:
    print("Sprouts: Main scene ready")

func change_scene_to(path: String) -> void:
    print("Changing scene to: " + path)
    get_tree().change_scene_to_file(path)

func reload_main_menu() -> void:
    print("Reloading main menu")
    change_scene_to("res://scenes/meta/MainMenu.tscn")

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        print("Quit requested")
        get_tree().quit()
