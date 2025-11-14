extends Node
class_name BattleContext

# NOTE: This script should be added as an AutoLoad singleton named "BattleContext" in Project Settings.

var player_team: Array = []
var enemy_team: Array = []

func reset() -> void:
    player_team.clear()
    enemy_team.clear()

func debug_print() -> void:
    print("BattleContext: player_team size = ", player_team.size())
    for u in player_team:
        print("  P: ", u)
    print("BattleContext: enemy_team size = ", enemy_team.size())
    for u in enemy_team:
        print("  E: ", u)
