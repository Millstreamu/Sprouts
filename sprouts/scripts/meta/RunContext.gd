# NOTE: This script should be added as an AutoLoad singleton named "RunContext" in Project Settings.
extends Node
class_name RunContext

var selected_totem_id: String = ""
var selected_difficulty: int = -1
var selected_sprout_ids: Array[String] = []

func reset() -> void:
    selected_totem_id = ""
    selected_difficulty = -1
    selected_sprout_ids.clear()

func debug_print() -> void:
    print(
        "RunContext: totem_id=",
        selected_totem_id,
        " difficulty=",
        selected_difficulty,
        " sprouts=",
        selected_sprout_ids
    )
