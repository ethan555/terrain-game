class_name Hitbox
extends Area2D

@onready var collision_shape := $CollisionShape2D

func set_disabled(is_disabled: bool):
    collision_shape.set_deferred("disabled", is_disabled)

func get_new_areas() -> Array[Area2D]:
    var areas := get_overlapping_areas()
    return areas
