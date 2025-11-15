extends Control
class_name CommuneWindow

@export var title_label_path: NodePath
@export var hint_label_path: NodePath
@export var offer0_path: NodePath
@export var offer1_path: NodePath
@export var offer2_path: NodePath

@onready var _title_label: Label = get_node_or_null(title_label_path) as Label
@onready var _hint_label: Label = get_node_or_null(hint_label_path) as Label
@onready var _offer_panels: Array[Control] = [
    get_node_or_null(offer0_path) as Control,
    get_node_or_null(offer1_path) as Control,
    get_node_or_null(offer2_path) as Control
]

signal offer_chosen(tile_id: String)

var _offers: Array[Dictionary] = []
var _selected_index: int = 0

func _ready() -> void:
    if is_instance_valid(_title_label):
        _title_label.text = "Commune"
    if is_instance_valid(_hint_label):
        _hint_label.text = "[←/→] Choose  •  [Space] Confirm"
    _clear_offers()
    visible = false

func open_with_offers(offers: Array) -> void:
    _clear_offers()
    _offers = offers.duplicate()
    _selected_index = 0

    for i in _offer_panels.size():
        var panel := _offer_panels[i]
        if panel == null:
            continue
        if i < _offers.size():
            var entry := _offers[i]
            var name := str(entry.get("name", "Unknown"))
            var category := str(entry.get("category", ""))
            if not category.is_empty():
                category = "Category: %s" % category
            var description := str(entry.get("description", ""))
            _set_offer_panel_data(panel, name, category, description)
        else:
            _set_offer_panel_data(panel, "", "", "")

    _refresh_visual_selection()
    visible = true

func close_commune() -> void:
    visible = false

func _clear_offers() -> void:
    _offers.clear()
    for panel in _offer_panels:
        if panel == null:
            continue
        _set_offer_panel_data(panel, "", "", "")
    _selected_index = 0
    _refresh_visual_selection()

func _set_offer_panel_data(panel: Control, name: String, category: String, description: String) -> void:
    var name_label := panel.get_node_or_null("OfferVBox/NameLabel") as Label
    if is_instance_valid(name_label):
        name_label.text = name
    var category_label := panel.get_node_or_null("OfferVBox/CategoryLabel") as Label
    if is_instance_valid(category_label):
        category_label.text = category
    var description_label := panel.get_node_or_null("OfferVBox/DescriptionLabel") as Label
    if is_instance_valid(description_label):
        description_label.text = description

func _refresh_visual_selection() -> void:
    for i in _offer_panels.size():
        var panel := _offer_panels[i]
        if panel == null:
            continue
        if i == _selected_index:
            panel.modulate = Color(1, 1, 1, 1)
        else:
            panel.modulate = Color(0.8, 0.8, 0.8, 1)

func _move_selection(delta: int) -> void:
    if _offers.is_empty():
        return
    _selected_index = clampi(_selected_index + delta, 0, _offers.size() - 1)
    _refresh_visual_selection()

func _confirm_selection() -> void:
    if _offers.is_empty():
        return
    _selected_index = clampi(_selected_index, 0, _offers.size() - 1)
    var entry := _offers[_selected_index]
    var tile_id := str(entry.get("id", ""))
    emit_signal("offer_chosen", tile_id)

func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    if Input.is_action_just_pressed("ui_left"):
        _move_selection(-1)
        accept_event()
        return
    if Input.is_action_just_pressed("ui_right"):
        _move_selection(1)
        accept_event()
        return
    if Input.is_action_just_pressed("ui_accept"):
        _confirm_selection()
        accept_event()
        return
