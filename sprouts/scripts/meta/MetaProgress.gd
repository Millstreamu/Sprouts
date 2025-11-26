extends Node
class_name MetaProgress

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
    print("MetaProgress: ready (totems=%d, sprouts=%d, tiles=%d)" % [
        all_totem_defs.size(),
        all_sprout_defs.size(),
        all_tile_defs.size()
    ])

func _init_defaults() -> void:
    unlocked_totems.clear()
    unlocked_sprouts.clear()
    unlocked_tiles.clear()

    unlocked_totems["totem.heartseed"] = true

    unlocked_sprouts["sprout.grumbler"] = true
    unlocked_sprouts["sprout.amber_knight"] = true

    unlocked_tiles["tile.nature.whispering_pine_forest"] = true
    unlocked_tiles["tile.water.mirror_pool"] = true
    unlocked_tiles["tile.earth.stone_vein"] = true
    print("MetaProgress: unlocked_totems =", unlocked_totems)

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
    if not unlocked_totems.get(id, false):
        unlocked_totems[id] = true
        print("MetaProgress: unlocked totem %s" % id)

func unlock_sprout(id: String) -> void:
    if not unlocked_sprouts.get(id, false):
        unlocked_sprouts[id] = true
        print("MetaProgress: unlocked sprout %s" % id)

func unlock_tile(id: String) -> void:
    if not unlocked_tiles.get(id, false):
        unlocked_tiles[id] = true
        print("MetaProgress: unlocked tile %s" % id)

func is_totem_unlocked(id: String) -> bool:
    return bool(unlocked_totems.get(id, false))

func is_sprout_unlocked(id: String) -> bool:
    return bool(unlocked_sprouts.get(id, false))

func is_tile_unlocked(id: String) -> bool:
    return bool(unlocked_tiles.get(id, false))
