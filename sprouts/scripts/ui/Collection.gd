extends Control
class_name CollectionScreen

@export var tabs_container_path: NodePath
@export var scroll_container_path: NodePath
@export var card_grid_path: NodePath
@export var back_button_path: NodePath
@export var card_scene: PackedScene

@onready var _tabs_container: HBoxContainer = get_node(tabs_container_path) as HBoxContainer
@onready var _scroll: ScrollContainer = get_node(scroll_container_path) as ScrollContainer
@onready var _card_grid: GridContainer = get_node(card_grid_path) as GridContainer
@onready var _back_button: Button = get_node(back_button_path) as Button
@onready var _tab_buttons: Array[Button] = []

const TAB_TOTEMS: int = 0
const TAB_SPROUTS: int = 1
const TAB_TILES: int = 2

var _current_tab_index: int = TAB_TOTEMS
var _selected_card_index: int = 0
var _cards: Array[Control] = []
var _in_tab_mode: bool = true

func _ready() -> void:
    _in_tab_mode = true
    _tab_buttons = _collect_tab_buttons()
    _back_button.pressed.connect(_go_back_to_main_menu)
    _current_tab_index = TAB_TOTEMS
    _refresh_tab_visuals()
    _populate_cards_for_current_tab()
    print("Collection: ready")

func _enter_tab_mode() -> void:
    _in_tab_mode = true
    _selected_card_index = 0
    _refresh_tab_visuals()
    print("Collection: entered TAB mode")

func _enter_card_mode() -> void:
    if _cards.is_empty():
        return
    _in_tab_mode = false
    _selected_card_index = 0
    _update_card_selection()
    print("Collection: entered CARD mode")

func _collect_tab_buttons() -> Array[Button]:
    var buttons: Array[Button] = []
    for child in _tabs_container.get_children():
        if child is Button:
            buttons.append(child as Button)
    return buttons

func _refresh_tab_visuals() -> void:
    if _tab_buttons.is_empty():
        return

    for i in _tab_buttons.size():
        var button: Button = _tab_buttons[i]
        if _in_tab_mode and i == _current_tab_index:
            button.grab_focus()

func _get_current_tab_data() -> Array:
    if not Engine.has_singleton("MetaProgress"):
        return []
    var meta := MetaProgress
    if _current_tab_index == TAB_TOTEMS:
        return meta.get_all_totem_entries()
    if _current_tab_index == TAB_SPROUTS:
        return meta.get_all_sprout_entries()
    return meta.get_all_tile_entries()

func _clear_cards() -> void:
    for child in _card_grid.get_children():
        child.queue_free()
    _cards.clear()
    _selected_card_index = 0

func _populate_cards_for_current_tab() -> void:
    _clear_cards()
    if card_scene == null:
        print("Collection: card_scene is NULL, no cards will be created")
        return
    var data: Array = _get_current_tab_data()
    print("Collection: cards populated = %d" % data.size())
    for entry in data:
        var card := card_scene.instantiate() as Control
        _card_grid.add_child(card)
        _cards.append(card)
        if card.has_node("NameLabel"):
            var label := card.get_node("NameLabel") as Label
            if entry.get("unlocked", false):
                label.text = str(entry.get("name", ""))
            else:
                label.text = "Locked"
        card.set_meta("card_id", entry.get("id", ""))
    _update_card_selection()

func _update_card_selection() -> void:
    if _cards.is_empty():
        _selected_card_index = 0
        return
    _selected_card_index = clampi(_selected_card_index, 0, _cards.size() - 1)
    var card := _cards[_selected_card_index]
    if is_instance_valid(_scroll) and is_instance_valid(card):
        _scroll.ensure_control_visible(card)
    print("Collection: selected card index = %d" % _selected_card_index)

func _move_card_selection(delta: int) -> void:
    if _cards.is_empty():
        return
    _selected_card_index += delta
    _selected_card_index = clampi(_selected_card_index, 0, _cards.size() - 1)
    _update_card_selection()

func _change_tab(delta: int) -> void:
    _current_tab_index += delta
    _current_tab_index = clampi(_current_tab_index, TAB_TOTEMS, TAB_TILES)
    var tab_names := ["Totems", "Sprouts", "Tiles"]
    print("Collection: active tab = %s" % tab_names[_current_tab_index])
    _refresh_tab_visuals()
    _populate_cards_for_current_tab()

func _activate_current_card() -> void:
    if _cards.is_empty():
        return
    _selected_card_index = clampi(_selected_card_index, 0, _cards.size() - 1)
    var card: Control = _cards[_selected_card_index]
    var id: String = str(card.get_meta("card_id", ""))
    print("Collection: activated card %s on tab %d" % [id, _current_tab_index])

func _go_back_to_main_menu() -> void:
    print("Collection: back to main menu")
    get_tree().change_scene_to_file("res://scenes/meta/MainMenu.tscn")

func _input(_event: InputEvent) -> void:
    if Input.is_action_just_pressed("ui_cancel"):
        if _in_tab_mode:
            _go_back_to_main_menu()
        else:
            _enter_tab_mode()
        accept_event()
        return

    if _in_tab_mode:
        if Input.is_action_just_pressed("ui_left"):
            _change_tab(-1)
            accept_event()
        elif Input.is_action_just_pressed("ui_right"):
            _change_tab(1)
            accept_event()
        elif Input.is_action_just_pressed("ui_accept"):
            _enter_card_mode()
            accept_event()
    else:
        if Input.is_action_just_pressed("ui_left"):
            _move_card_selection(-1)
            accept_event()
        elif Input.is_action_just_pressed("ui_right"):
            _move_card_selection(1)
            accept_event()
        elif Input.is_action_just_pressed("ui_up"):
            _move_card_selection(-4)
            accept_event()
        elif Input.is_action_just_pressed("ui_down"):
            _move_card_selection(4)
            accept_event()
        elif Input.is_action_just_pressed("ui_accept"):
            _activate_current_card()
            accept_event()
