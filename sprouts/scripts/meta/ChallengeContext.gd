extends Node
class_name ChallengeContext

var challenges: Dictionary = {}

func _ready() -> void:
    _init_default_challenges()

func _init_default_challenges() -> void:
    challenges.clear()

    challenges["challenge.first_victory"] = {
        "id": "challenge.first_victory",
        "name": "First Victory",
        "description": "Win a run once.",
        "progress": 0,
        "target": 1,
        "completed": false
    }

    challenges["challenge.destroy_totems_3"] = {
        "id": "challenge.destroy_totems_3",
        "name": "Totem Breaker",
        "description": "Destroy 3 Decay Totems across all runs.",
        "progress": 0,
        "target": 3,
        "completed": false
    }

    challenges["challenge.spawn_sprouts_20"] = {
        "id": "challenge.spawn_sprouts_20",
        "name": "Gardener",
        "description": "Spawn 20 Sprouts across all runs.",
        "progress": 0,
        "target": 20,
        "completed": false
    }

    print("ChallengeContext: initialized %d challenges" % challenges.size())

func get_all_challenges() -> Array:
    var arr: Array = []
    for key in challenges.keys():
        arr.append(challenges[key])
    arr.sort_custom(self, "_sort_challenge_dicts")
    return arr

func _sort_challenge_dicts(a: Dictionary, b: Dictionary) -> bool:
    return str(a.get("id", "")) < str(b.get("id", ""))

func _ensure_entry(id: String) -> void:
    if not challenges.has(id):
        challenges[id] = {
            "id": id,
            "name": id,
            "description": "",
            "progress": 0,
            "target": 1,
            "completed": false
        }

func _update_progress(id: String, delta: int) -> void:
    _ensure_entry(id)
    var ch := challenges[id]
    if ch.get("completed", false):
        return

    var progress := int(ch.get("progress", 0))
    var target := int(ch.get("target", 1))

    progress += delta
    if progress < 0:
        progress = 0

    ch["progress"] = progress
    var just_completed := false
    if progress >= target:
        ch["completed"] = true
        just_completed = true

    challenges[id] = ch
    print("ChallengeContext: %s progress = %d / %d (completed=%s)" % [
        id,
        progress,
        target,
        str(ch["completed"])
    ])

    if just_completed:
        _on_challenge_completed(id)

func update_after_run(result: String, run_stats: Dictionary) -> void:
    if result == "victory":
        _update_progress("challenge.first_victory", 1)

    var spawned := int(run_stats.get("sprouts_spawned", 0))
    if spawned > 0:
        _update_progress("challenge.spawn_sprouts_20", spawned)

    var totems_destroyed := int(run_stats.get("decay_totems_destroyed", 0))
    if totems_destroyed > 0:
        _update_progress("challenge.destroy_totems_3", totems_destroyed)

func _on_challenge_completed(id: String) -> void:
    print("ChallengeContext: challenge completed -> %s" % id)

    if not Engine.has_singleton("MetaProgress"):
        print("ChallengeContext: MetaProgress not available, cannot grant unlocks")
        return

    var meta := MetaProgress

    match id:
        "challenge.first_victory":
            meta.unlock_totem("totem.stoneward")
        "challenge.destroy_totems_3":
            meta.unlock_tile("tile.mystic.soul_bloom")
        "challenge.spawn_sprouts_20":
            meta.unlock_sprout("sprout.moss_golem")
        _:
            pass
