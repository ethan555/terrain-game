class_name Vision
extends Area2D

@onready var collision_shape := $CollisionShape2D

var radius : float

signal enemy_in_range
signal enemy_left_range

func _ready():
    update_vision_radius(radius)
    area_entered.connect(_on_area_entered)
    area_exited.connect(_on_area_exited)

func update_vision_radius(new_radius) -> void:
    radius = new_radius
    collision_shape.shape.radius = radius

func _on_area_entered(area: Area2D) -> void: #hurtbox: Hurtbox) -> void:
    if not area is Hurtbox:
        return
    enemy_in_range.emit(area.owner)

func _on_area_exited(area: Area2D) -> void: #hurtbox: Hurtbox) -> void:
    if not area is Hurtbox:
        return
    enemy_left_range.emit(area.owner)
