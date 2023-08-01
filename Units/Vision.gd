class_name Vision
extends Area2D

const Utils = preload("res://Utils/utils.gd")

@onready var collision_shape := $CollisionShape2D

var radius : float

signal enemy_in_range
signal enemy_left_range

func _ready():
    update_vision_radius(radius)
    area_entered.connect(_on_area_entered)
    area_exited.connect(_on_area_exited)

# GET OVERLAPPING AREAS
func get_new_areas() -> Array[Area2D]:
    var areas := Utils.get_overlapping_areas_godot_sucks(self, collision_shape)
    return areas

func update_vision_radius(new_radius) -> void:
    radius = new_radius
    collision_shape.shape.radius = radius

func _on_area_entered(area: Area2D) -> void: #hurtbox: Hurtbox) -> void:
    if not area is Hurtbox:
        return
    enemy_in_range.emit(area.get_parent())

func _on_area_exited(area: Area2D) -> void: #hurtbox: Hurtbox) -> void:
    if not area is Hurtbox:
        return
    enemy_left_range.emit(area.get_parent())
