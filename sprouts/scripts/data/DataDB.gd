extends Node
class_name DataDB

const TILES_PATH := "res://data/tiles.json"
const SPROUTS_PATH := "res://data/sprouts.json"
const ATTACKS_PATH := "res://data/attacks.json"
const PASSIVES_PATH := "res://data/passives.json"
const TOTEMS_PATH := "res://data/totems.json"

var tile_defs: Dictionary = {}
var sprout_defs: Dictionary = {}
var attack_defs: Dictionary = {}
var passive_defs: Dictionary = {}
var totem_defs: Dictionary = {}

func _ready() -> void:
        _load_all()
        print(
                "DataDB: ready (tiles=%d, sprouts=%d, attacks=%d, passives=%d, totems=%d)" % [
                        tile_defs.size(),
                        sprout_defs.size(),
                        attack_defs.size(),
                        passive_defs.size(),
                        totem_defs.size()
                ]
        )

func _load_all() -> void:
        tile_defs = _load_array_json_as_dict(TILES_PATH, "id")
        sprout_defs = _load_array_json_as_dict(SPROUTS_PATH, "id")
        attack_defs = _load_array_json_as_dict(ATTACKS_PATH, "id")
        passive_defs = _load_array_json_as_dict(PASSIVES_PATH, "id")
        totem_defs = _load_array_json_as_dict(TOTEMS_PATH, "id")

func _load_array_json_as_dict(path: String, key_field: String) -> Dictionary:
        var result: Dictionary = {}
        var file := FileAccess.open(path, FileAccess.READ)
        if file == null:
                push_warning("DataDB: could not open JSON at %s" % path)
                return result
        var text := file.get_as_text()
        file.close()
        var json := JSON.new()
        var parse_err := json.parse(text)
        if parse_err != OK:
                push_warning("DataDB: failed to parse JSON at %s: %s" % [path, json.get_error_message()])
                return result
        var data = json.data
        if not (data is Array):
                push_warning("DataDB: JSON at %s is not an Array" % path)
                return result
        for entry in data:
                if not (entry is Dictionary):
                        continue
                var id := str(entry.get(key_field, ""))
                if id == "":
                        continue
                result[id] = entry
        return result

func get_tile_def(id: String) -> Dictionary:
        return tile_defs.get(id, null)

func get_sprout_def(id: String) -> Dictionary:
        return sprout_defs.get(id, null)

func get_attack_def(id: String) -> Dictionary:
        return attack_defs.get(id, null)

func get_passive_def(id: String) -> Dictionary:
        return passive_defs.get(id, null)

func get_totem_def(id: String) -> Dictionary:
        return totem_defs.get(id, null)
