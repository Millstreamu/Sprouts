extends Control
class_name WorldTileInfoPanel

@export var title_label_path: NodePath
@export var category_label_path: NodePath
@export var tags_label_path: NodePath
@export var cluster_label_path: NodePath
@export var state_label_path: NodePath
@export var output_label_path: NodePath
@export var description_label_path: NodePath

@onready var _title_label: Label = get_node(title_label_path) as Label
@onready var _category_label: Label = get_node(category_label_path) as Label
@onready var _tags_label: Label = get_node(tags_label_path) as Label
@onready var _cluster_label: Label = get_node(cluster_label_path) as Label
@onready var _state_label: Label = get_node(state_label_path) as Label
@onready var _output_label: Label = get_node(output_label_path) as Label
@onready var _description_label: Label = get_node(description_label_path) as Label

func _ready() -> void:
    visible = true
    show_empty()

func _set_label(label: Label, text: String) -> void:
    if not is_instance_valid(label):
        return
    label.text = text

func show_empty() -> void:
    _set_label(_title_label, "No tile")
    _set_label(_category_label, "Category: N/A")
    _set_label(_tags_label, "Tags: N/A")
    _set_label(_cluster_label, "Cluster: N/A")
    _set_label(_state_label, "State: Empty")
    _set_label(_output_label, "Output: N/A")
    _set_label(_description_label, "")

func show_tile(info: Dictionary) -> void:
    var name := str(info.get("name", "Unknown Tile"))
    var category := str(info.get("category", "Unknown"))
    var tags_value := info.get("tags", [])
    var tags_text := "N/A"
    if tags_value is Array:
        var tag_strings: Array[String] = []
        for tag in tags_value:
            tag_strings.append(str(tag))
        if not tag_strings.is_empty():
            tags_text = ", ".join(tag_strings)
    elif tags_value is PackedStringArray:
        var packed_tags := tags_value as PackedStringArray
        if packed_tags.size() > 0:
            tags_text = ", ".join(packed_tags)
    var cluster_type := str(info.get("cluster_type", "N/A"))
    var cluster_size := int(info.get("cluster_size", 0))
    var state := str(info.get("state", "Unknown"))
    var output_summary := str(info.get("output_summary", "N/A"))
    var desc := str(info.get("description", ""))

    _set_label(_title_label, name)
    _set_label(_category_label, "Category: %s" % category)
    _set_label(_tags_label, "Tags: %s" % tags_text)
    if cluster_type == "N/A" or cluster_size <= 0:
        _set_label(_cluster_label, "Cluster: N/A")
    else:
        _set_label(_cluster_label, "Cluster: %s (size %d)" % [cluster_type, cluster_size])
    _set_label(_state_label, "State: %s" % state)
    _set_label(_output_label, "Output: %s" % output_summary)
    _set_label(_description_label, desc)
