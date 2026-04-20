extends Node
class_name Observability

const MAX_AUDIT_RECORDS := 200
const SENSITIVE_KEYWORDS := ["password", "secret", "token", "auth", "cookie", "apikey", "api_key", "session"]

var _session_id: String = ""
var _event_sequence: int = 0
var _audit_records: Array[Dictionary] = []

func _ready() -> void:
	_session_id = _generate_id("session")
	log_info("observability.ready", "Observability initialized", {"session_id": _session_id})

func new_trace_id(prefix: String = "trace") -> String:
	return _generate_id(prefix)

func current_session_id() -> String:
	return _session_id

func log_debug(event: String, message: String, context: Dictionary = {}, trace_id: String = "") -> void:
	_emit_log("DEBUG", event, message, context, trace_id)

func log_info(event: String, message: String, context: Dictionary = {}, trace_id: String = "") -> void:
	_emit_log("INFO", event, message, context, trace_id)

func log_warn(event: String, message: String, context: Dictionary = {}, trace_id: String = "") -> void:
	_emit_log("WARN", event, message, context, trace_id)

func log_error(event: String, message: String, context: Dictionary = {}, trace_id: String = "") -> void:
	_emit_log("ERROR", event, message, context, trace_id)

func log_agent_action(agent: String, action: String, outcome: String, context: Dictionary = {}, trace_id: String = "") -> void:
	_emit_log("INFO", "agent.action", "Agent action recorded", {
		"agent": agent,
		"action": action,
		"outcome": outcome,
		"details": context
	}, trace_id)

func audit(event_type: String, actor: String, outcome: String, target: String, context: Dictionary = {}, trace_id: String = "") -> Dictionary:
	var record := {
		"timestamp": Time.get_datetime_string_from_system(true),
		"record_id": _generate_id("audit"),
		"event_type": event_type,
		"actor": actor,
		"outcome": outcome,
		"target": target,
		"trace_id": trace_id,
		"context": _sanitize_context(context)
	}
	_audit_records.append(record)
	if _audit_records.size() > MAX_AUDIT_RECORDS:
		_audit_records.pop_front()
	_emit_log("INFO", "audit.recorded", "Audit record captured", record, trace_id)
	return record

func list_audit_records() -> Array[Dictionary]:
	return _audit_records.duplicate(true)

func error_response(code: String, message: String, request_id: String = "", details: Dictionary = {}) -> Dictionary:
	var resolved_request_id := request_id
	if resolved_request_id.is_empty():
		resolved_request_id = _generate_id("req")
	return {
		"ok": false,
		"error": {
			"code": code,
			"message": message,
			"request_id": resolved_request_id,
			"details": _sanitize_context(details)
		}
	}

func _emit_log(level: String, event: String, message: String, context: Dictionary, trace_id: String) -> void:
	_event_sequence += 1
	var payload := {
		"timestamp": Time.get_datetime_string_from_system(true),
		"level": level,
		"event": event,
		"message": message,
		"session_id": _session_id,
		"trace_id": trace_id,
		"event_sequence": _event_sequence,
		"context": _sanitize_context(context)
	}
	print(JSON.stringify(payload))

func _sanitize_context(value: Variant) -> Variant:
	if value is Dictionary:
		var source: Dictionary = value
		var sanitized: Dictionary = {}
		for key in source.keys():
			var key_text := str(key)
			if _is_sensitive_key(key_text):
				sanitized[key_text] = "[REDACTED]"
			else:
				sanitized[key_text] = _sanitize_context(source[key])
		return sanitized
	if value is Array:
		var source_array: Array = value
		var sanitized_array: Array = []
		for item in source_array:
			sanitized_array.append(_sanitize_context(item))
		return sanitized_array
	return value

func _is_sensitive_key(key: String) -> bool:
	var lowered := key.to_lower()
	for marker in SENSITIVE_KEYWORDS:
		if lowered.find(marker) != -1:
			return true
	return false

func _generate_id(prefix: String) -> String:
	return "%s_%d_%d" % [prefix, Time.get_unix_time_from_system(), randi() % 1000000]
