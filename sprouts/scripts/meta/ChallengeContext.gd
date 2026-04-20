extends Node

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

	_log_info("challenge.init", "Initialized default challenges", {"count": challenges.size()})

func get_all_challenges() -> Array:
	var arr: Array = []
	for key in challenges.keys():
		arr.append(challenges[key])
	arr.sort_custom(Callable(self, "_sort_challenge_dicts"))
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
		_log_warn("challenge.missing_entry", "Created fallback challenge entry", {"id": id})

func _update_progress(id: String, delta: int) -> void:
	_ensure_entry(id)
	var ch: Dictionary = challenges[id]
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
	_log_info("challenge.progress", "Challenge progress updated", {
		"id": id,
		"progress": progress,
		"target": target,
		"completed": ch["completed"]
	})

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
	_log_info("challenge.completed", "Challenge completed", {"id": id})
	_audit("approval", "challenge_system", "approved", id, {"reason": "completion"})

	if not Engine.has_singleton("MetaProgress"):
		_log_error("challenge.unlock_failed", "MetaProgress unavailable for challenge reward", {"id": id})
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

func _log_info(event: String, message: String, context: Dictionary) -> void:
	if Engine.has_singleton("Observability"):
		Observability.log_info(event, message, context)
	else:
		print("ChallengeContext: %s %s" % [event, context])

func _log_warn(event: String, message: String, context: Dictionary) -> void:
	if Engine.has_singleton("Observability"):
		Observability.log_warn(event, message, context)
	else:
		print("ChallengeContext: %s %s" % [event, context])

func _log_error(event: String, message: String, context: Dictionary) -> void:
	if Engine.has_singleton("Observability"):
		Observability.log_error(event, message, context)
	else:
		push_warning("ChallengeContext: %s %s" % [event, context])

func _audit(event_type: String, actor: String, outcome: String, target: String, context: Dictionary) -> void:
	if Engine.has_singleton("Observability"):
		Observability.audit(event_type, actor, outcome, target, context)
