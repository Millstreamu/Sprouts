# NOTE: This script should be added as an AutoLoad singleton named "RunContext" in Project Settings.
extends Node
class_name RunContext

var selected_totem_id: String = ""
var selected_difficulty: int = -1
var selected_sprout_ids: Array[String] = []
var trace_id: String = ""

func reset() -> void:
	selected_totem_id = ""
	selected_difficulty = -1
	selected_sprout_ids.clear()
	trace_id = ""
	_log_info("run_context.reset", "Run context reset", {})

func ensure_trace_id() -> String:
	if not trace_id.is_empty():
		return trace_id
	if Engine.has_singleton("Observability"):
		trace_id = Observability.new_trace_id("run")
	else:
		trace_id = "run_%d" % Time.get_unix_time_from_system()
	return trace_id

func debug_print() -> void:
	var context := {
		"totem_id": selected_totem_id,
		"difficulty": selected_difficulty,
		"sprouts": selected_sprout_ids,
		"trace_id": ensure_trace_id()
	}
	_log_info("run_context.snapshot", "Run context snapshot", context)

func _log_info(event: String, message: String, context: Dictionary) -> void:
	if Engine.has_singleton("Observability"):
		Observability.log_info(event, message, context, trace_id)
	else:
		print("RunContext: %s %s" % [event, context])
