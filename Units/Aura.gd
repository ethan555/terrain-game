class_name Aura
extends Area2D

enum TargetType {
    Ally = 0,
    Enemy = 1
}

@export var target_type : TargetType
@export var statuses : Array[Status]

func _on_area_entered(area: Area2D) -> void: #hurtbox: Hurtbox) -> void:
    if not area is Hurtbox:
        return
    var unit = area.owner
    if not unit.has_node("Stats"):
        return
    var unit_stats : Stats = unit.get_node("Stats")
    for status in statuses:
        unit_stats.add_status(status)

func _on_area_exited(area: Area2D) -> void: #hurtbox: Hurtbox) -> void:
    if not area is Hurtbox:
        return
    var unit = area.owner
    if not unit.has_node("Stats"):
        return
    var unit_stats : Stats = unit.get_node("Stats")
    for status in statuses:
        unit_stats.remove_status(status.name)
