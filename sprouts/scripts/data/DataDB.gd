extends Node

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
	_log_info("data.ready", "DataDB ready", {
		"tiles": tile_defs.size(),
		"sprouts": sprout_defs.size(),
		"attacks": attack_defs.size(),
		"passives": passive_defs.size(),
		"totems": totem_defs.size()
	})

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
		_emit_load_error("data.file_open_failed", "Could not open JSON", {
			"path": path,
			"key_field": key_field
		})
		return result
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var parse_err := json.parse(text)
	if parse_err != OK:
		_emit_load_error("data.parse_failed", "JSON parse failed", {
			"path": path,
			"parser_error": json.get_error_message()
		})
		return result
	var data = json.data
	if not (data is Array):
		_emit_load_error("data.invalid_shape", "JSON root is not an Array", {"path": path})
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

func _emit_load_error(event: String, message: String, context: Dictionary) -> void:
	if Engine.has_singleton("Observability"):
		var envelope := Observability.error_response(event, message, "", context)
		Observability.log_error(event, message, envelope)
	else:
		push_warning("DataDB: %s %s" % [message, context])

func _log_info(event: String, message: String, context: Dictionary) -> void:
	if Engine.has_singleton("Observability"):
		Observability.log_info(event, message, context)
	else:
		print("DataDB: %s %s" % [event, context])
