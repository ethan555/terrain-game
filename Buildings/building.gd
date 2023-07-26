class_name Building
extends Node2D

@export var faction : Faction
@export var stats : Stats
@export var actions : Array[Action]
@export var passive_actions : Array[Action]

func _ready():
    stats.connect("death", _on_death)

func _on_death() -> void:
    print("BUILDING DOWN")
    queue_free()
