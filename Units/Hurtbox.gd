class_name Hurtbox
extends Area2D

@onready var collision_shape := $CollisionShape2D


func set_disabled(is_disabled: bool):
    collision_shape.set_deferred("disabled", is_disabled)
