extends Node

var _base_category_weights: Dictionary = {
	"default": {
		"Nature": 1.0,
		"Earth": 1.0,
		"Water": 1.0,
		"Nest": 0.5,
		"Mystic": 0.5,
		"Aggression": 0.5
	},
	"totem.heartseed": {
		"Nature": 1.8,
		"Earth": 1.0,
		"Water": 1.0,
		"Nest": 0.7,
		"Mystic": 1.3,
		"Aggression": 0.6
	},
	"totem.stoneward": {
		"Nature": 1.0,
		"Earth": 1.8,
		"Water": 1.0,
		"Nest": 1.3,
		"Mystic": 0.7,
		"Aggression": 1.3
	},
	"totem.wavecall": {
		"Nature": 1.2,
		"Earth": 0.9,
		"Water": 1.8,
		"Nest": 0.7,
		"Mystic": 1.2,
		"Aggression": 0.8
	},
	"totem.bloomspire": {
		"Nature": 2.0,
		"Earth": 0.9,
		"Water": 1.0,
		"Nest": 0.7,
		"Mystic": 1.5,
		"Aggression": 0.7
	}
}

var _difficulty_multipliers: Dictionary = {
	"easy": {
		"Aggression": 0.6,
		"Nest": 1.1,
		"Mystic": 1.0,
		"Nature": 1.0,
		"Earth": 1.0,
		"Water": 1.0
	},
	"medium": {
		"Aggression": 1.0,
		"Nest": 1.0,
		"Mystic": 1.0,
		"Nature": 1.0,
		"Earth": 1.0,
		"Water": 1.0
	},
	"hard": {
		"Aggression": 1.3,
		"Nest": 1.0,
		"Mystic": 1.0,
		"Nature": 1.0,
		"Earth": 1.0,
		"Water": 1.0
	}
}

func _ready() -> void:
	print("CommuneManager: ready")

func _get_category_weight_for(totem_id: String, difficulty: String, category: String) -> float:
	var base_map: Dictionary = _base_category_weights.get(totem_id, _base_category_weights.get("default", {}))
	var base_weight: float = float(base_map.get(category, 1.0))
	var diff_map: Dictionary = _difficulty_multipliers.get(difficulty, _difficulty_multipliers.get("medium", {}))
	var diff_mult: float = float(diff_map.get(category, 1.0))
	return base_weight * diff_mult

func _compute_tile_weight(tile_def: Dictionary, totem_id: String, difficulty: String) -> float:
	var category: String = String(tile_def.get("category", ""))
	if category.is_empty():
		return 0.0

	var weight: float = _get_category_weight_for(totem_id, difficulty, category)
	if weight <= 0.0:
		return 0.0

	var tags_data: Variant = tile_def.get("tags", [])
	if tags_data is Array:
		var tags: Array = tags_data
		if "unique" in tags:
			weight *= 0.7

	return weight


func _weighted_pick_indices(weights: Array[float], count: int) -> Array[int]:
	var indices: Array[int] = []
	var available: Array[int] = []
	for i in range(weights.size()):
		if weights[i] > 0.0:
			available.append(i)
	var remaining: int = count
	while remaining > 0 and not available.is_empty():
		var total_weight: float = 0.0
		for idx in available:
			total_weight += weights[idx]
		if total_weight <= 0.0:
			break
		var roll: float = randf() * total_weight
		var chosen_idx: int = -1
		var accum: float = 0.0
		for idx in available:
			accum += weights[idx]
			if roll <= accum:
				chosen_idx = idx
				break
		if chosen_idx == -1:
			chosen_idx = available[available.size() - 1]
		indices.append(chosen_idx)
		available.erase(chosen_idx)
		remaining -= 1
	return indices

func generate_offers(
	tile_defs: Dictionary,
	unlocked_tile_entries: Array,
	totem_id: String,
	difficulty: String,
	offer_count: int
) -> Array:
	var candidates: Array[Dictionary] = []
	var weights: Array[float] = []

	for entry in unlocked_tile_entries:
		if not (entry is Dictionary):
			continue
		if not bool(entry.get("unlocked", false)):
			continue

		var tile_id: String = String(entry.get("id", ""))
		if tile_id.is_empty():
			continue
		if not tile_defs.has(tile_id):
			continue

		var def: Dictionary = tile_defs[tile_id]
		var weight: float = _compute_tile_weight(def, totem_id, difficulty)
		if weight <= 0.0:
			continue

		candidates.append(entry)
		weights.append(weight)

	if candidates.is_empty():
		print("CommuneManager: no candidates for offers")
		return []

	var indices: Array[int] = _weighted_pick_indices(weights, offer_count)
	var offers: Array = []

	for idx in indices:
		if idx < 0 or idx >= candidates.size():
			continue

		var entry: Dictionary = candidates[idx]
		var tile_id: String = String(entry.get("id", ""))
		if tile_id.is_empty():
			continue

		var tile_name: String = String(entry.get("name", tile_id))
		var category: String = ""
		var description: String = ""

		if tile_defs.has(tile_id):
			var def: Dictionary = tile_defs[tile_id]
			tile_name = String(def.get("name", tile_name))
			category = String(def.get("category", ""))
			description = String(def.get("description", ""))

		offers.append({
			"id": tile_id,
			"name": tile_name,
			"category": category,
			"description": description,
		})

	return offers
