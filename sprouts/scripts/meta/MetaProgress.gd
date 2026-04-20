extends Node

var unlocked_totems: Dictionary = {}
var unlocked_sprouts: Dictionary = {}
var unlocked_tiles: Dictionary = {}

var all_totem_defs: Array = [
	{"id": "totem.heartseed", "name": "Heartseed Totem"},
	{"id": "totem.stoneward", "name": "Stoneward Totem"},
	{"id": "totem.wavecall", "name": "Wavecall Totem"},
	{"id": "totem.bloomspire", "name": "Bloomspire Totem"}
]

var all_sprout_defs: Array = [
	{"id": "sprout.grumbler", "name": "Grumbler"},
	{"id": "sprout.amber_knight", "name": "Amber Knight"},
	{"id": "sprout.moss_golem", "name": "Moss Golem"}
]

var all_tile_defs: Array = [
	{"id": "tile.nature.whispering_pine_forest", "name": "Whispering Pine Forest"},
	{"id": "tile.water.mirror_pool", "name": "Mirror Pool"},
	{"id": "tile.earth.stone_vein", "name": "Stone Vein"},
	{"id": "tile.mystic.soul_bloom", "name": "Soul Bloom"},
	{"id": "tile.aggression.thorn_watch", "name": "Thorn Watch"}
]

func _ready() -> void:
	_init_defaults()
	_log_info("meta.ready", "MetaProgress ready", {
		"totems": all_totem_defs.size(),
		"sprouts": all_sprout_defs.size(),
		"tiles": all_tile_defs.size()
	})

func _init_defaults() -> void:
	unlocked_totems.clear()
	unlocked_sprouts.clear()
	unlocked_tiles.clear()

	for def in all_totem_defs:
		var id := str(def.get("id", ""))
		if not id.is_empty():
			unlocked_totems[id] = true

	for def in all_sprout_defs:
		var id := str(def.get("id", ""))
		if not id.is_empty():
			unlocked_sprouts[id] = true

	for def in all_tile_defs:
		var id := str(def.get("id", ""))
		if not id.is_empty():
			unlocked_tiles[id] = true

	_log_info("meta.bootstrap_unlocks", "Initialized default unlock state", {
		"totem_count": unlocked_totems.size(),
		"sprout_count": unlocked_sprouts.size(),
		"tile_count": unlocked_tiles.size()
	})

func get_all_totem_entries() -> Array:
	var arr: Array = []
	for def in all_totem_defs:
		var id := str(def.get("id", ""))
		var entry_name := str(def.get("name", id))
		var unlocked := bool(unlocked_totems.get(id, false))
		arr.append({
			"id": id,
			"name": entry_name,
			"unlocked": unlocked
		})
	return arr

func get_all_sprout_entries() -> Array:
	var arr: Array = []
	for def in all_sprout_defs:
		var id := str(def.get("id", ""))
		var entry_name := str(def.get("name", id))
		var unlocked := bool(unlocked_sprouts.get(id, false))
		arr.append({
			"id": id,
			"name": entry_name,
			"unlocked": unlocked
		})
	return arr

func get_all_tile_entries() -> Array:
	var arr: Array = []
	for def in all_tile_defs:
		var id := str(def.get("id", ""))
		var entry_name := str(def.get("name", id))
		var unlocked := bool(unlocked_tiles.get(id, false))
		arr.append({
			"id": id,
			"name": entry_name,
			"unlocked": unlocked
		})
	return arr

func unlock_totem(id: String) -> void:
	_unlock_entry(unlocked_totems, id, "totem")

func unlock_sprout(id: String) -> void:
	_unlock_entry(unlocked_sprouts, id, "sprout")

func unlock_tile(id: String) -> void:
	_unlock_entry(unlocked_tiles, id, "tile")

func _unlock_entry(pool: Dictionary, id: String, item_type: String) -> void:
	if id.is_empty():
		return
	if bool(pool.get(id, false)):
		_log_debug("meta.unlock_skipped", "Unlock skipped; already unlocked", {"id": id, "item_type": item_type})
		return
	pool[id] = true
	_log_info("meta.unlock", "Unlock granted", {"id": id, "item_type": item_type})
	_audit("inventory_change", "system", "approved", id, {
		"item_type": item_type,
		"change": "unlock"
	})

func is_totem_unlocked(id: String) -> bool:
	return bool(unlocked_totems.get(id, false))

func is_sprout_unlocked(id: String) -> bool:
	return bool(unlocked_sprouts.get(id, false))

func is_tile_unlocked(id: String) -> bool:
	return bool(unlocked_tiles.get(id, false))

func _log_info(event: String, message: String, context: Dictionary) -> void:
	if Engine.has_singleton("Observability"):
		Observability.log_info(event, message, context)
	else:
		print("MetaProgress: %s %s" % [event, context])

func _log_debug(event: String, message: String, context: Dictionary) -> void:
	if Engine.has_singleton("Observability"):
		Observability.log_debug(event, message, context)
	else:
		print("MetaProgress: %s %s" % [event, context])

func _audit(event_type: String, actor: String, outcome: String, target: String, context: Dictionary) -> void:
	if Engine.has_singleton("Observability"):
		Observability.audit(event_type, actor, outcome, target, context)
