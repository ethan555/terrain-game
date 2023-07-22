class_name Building
extends Node2D

@export var faction : Faction
@export var stats : Stats

func _ready():
    stats.connect("death", _on_death)

func _on_death() -> void:
    print("I DIED")
    queue_free()
