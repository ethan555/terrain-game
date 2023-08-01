class_name Projectile
extends Node2D

@onready var spawn_node := get_node("/root/Level")
@onready var controller := get_node("/root/Level/Controller")

@export var speed := 800.0
@export var lifespan := 4.0

@export var homing := true
@export var attack : Attack

@export var explosion := preload("res://Projectiles/explosion.tscn")

@onready var hitbox : Hitbox = $Hitbox
@onready var timer := $Timer

var target: Node2D
var target_location: Vector2
var faction: Faction

var velocity := Vector2(0, 0)

func initialize(_position: Vector2, _rotation: float, _target: Node2D, _faction: Faction, _target_location: Vector2):
    global_position = _position
    rotation = _rotation
    target = _target
    faction = _faction
    if homing:
        target_location = target.global_position
    else:
        target_location = _target_location
    set_as_top_level(true)


func _ready():
    timer.connect("timeout", queue_free)
    timer.start(lifespan)

    # hitbox.connect("body_entered", _on_impact)
    if not is_instance_valid(target):
        target = null
    if homing:
        if target != null:
            # Home in on target
            var tdir = (target.global_position - global_position).normalized()
            velocity = speed * tdir
        else:
            # Home in on location
            var tdir = (target_location - global_position).normalized()
            velocity = speed * tdir
    else:
        # Home in on location
        var tdir = (target_location - global_position).normalized()
        velocity = speed * tdir

# func damage_targets(areas: Array[Area2D]):
#     for area in areas:
#         if not area is Hurtbox:
#             continue
#         var unit = area.get_parent()
#         var target_faction : Faction = unit.faction
#         if faction.check_ally(target_faction.faction_name):
#             continue
#         unit.stats.damage(attack)

func create_explosion(explosion_position: Vector2):
    var explosion_instance := explosion.instantiate()
    explosion_instance.attack = attack
    explosion_instance.faction = faction
    explosion_instance.set_as_top_level(true)
    explosion_instance.global_position = explosion_position
    spawn_node.add_child(explosion_instance)


func hit_target() -> void:
    if attack.radius > 0:
        create_explosion(target_location)
        # Damage radius, create explosion
        # hitbox.
        # hitbox.collision_shape.shape.radius = attack.radius
        # var areas = hitbox.get_new_areas()
        # damage_targets(areas)
    elif is_instance_valid(target):
        target.stats.damage(attack)
    queue_free()

func _process(_delta):
    var play_paused = controller.current_state != controller.State.Play
    timer.paused = play_paused
    if play_paused:
        return

    if not homing:
        return
    if not is_instance_valid(target):
        target = null
    if target != null:
        target_location = target.global_position
    else:
        if target_location == null:
            return
    var tdist = (target_location - global_position).length()
    if tdist < speed * _delta:
        # Hit the target
        hit_target()
        return
    var tdir = (target_location - global_position).normalized()
    velocity = speed * tdir

func _physics_process(_delta):
    var play_paused = controller.current_state != controller.State.Play
    if play_paused:
        return
    position += velocity * _delta

func _on_impact(_body: Node) -> void:
    pass
