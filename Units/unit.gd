class_name Unit
extends CharacterBody2D
const Utils = preload("res://Utils/utils.gd")

signal projectile_created(Projectile)

@onready var spawn_node := get_node("/root/Level")
@onready var camera := get_node("/root/Level/Camera")
@onready var terrain : Terrain = get_node("/root/Level/Terrain")
@onready var controller := get_node("/root/Level/Controller")

@onready var sprite : Sprite2D = get_node("Sprite2D")
@onready var collider : CollisionShape2D = get_node("CollisionShape2D")
@onready var collision_radius : float = collider.shape.radius

@onready var stats : Stats = $Stats
@onready var hurtbox := $Hurtbox
@onready var vision := $Vision
@onready var primary_timer : Timer = $PrimaryTimer

@export_category("Stats")
@export var faction : Faction
@export var collision_moving_scale : float = .5
@export var move_speed : float = 300
@export var acceleration : float = 100
@export var push : float = 10
@export var lax : float = 1.0
@export var rotation_speed : float = 3 * PI

@export var mobile : bool = false
@export var ground : bool = true

@export var vision_radius : float = 140
@export var primary := preload("res://Projectiles/bullet.tscn")
@export var primary_time : float = 1
@export var primary_offset : Vector2 = Vector2(0, 0)

@export var statuses : Dictionary

var target_angle := rotation

var target : Node2D
var primary_ready = true


func _ready():
    vision.update_vision_radius(vision_radius)
    vision.enemy_in_range.connect(_on_enemy_in_range)
    vision.enemy_left_range.connect(_on_enemy_left_range)

    hurtbox.aura_entered.connect(_on_aura_entered)

    primary_timer.connect("timeout", _on_primary_timeout)

    stats.connect("death", _on_death)

func _on_death() -> void:
    queue_free()

func _on_aura_entered(aura: Aura) -> void:
    pass

func _on_enemy_in_range(unit: Node2D) -> void:
    if verify_target(true):
        return
    if faction.check_enemy(unit.faction.faction_name):
        target = unit
    # else:
    #     print("FRIENDLIES OVER HERE")

func _on_primary_timeout():
    primary_ready = true
    # if not verify_target(true):
    #     return
    

func _on_enemy_left_range(unit: Node2D) -> void:
    if unit == target:
        reset_target(true)

func reset_target(get_new: bool) -> bool:
    target = null
    if not get_new:
        return false
    var potential_target_areas : Array[Area2D] = vision.get_new_areas()
    print("New targets: " + str(len(potential_target_areas)))
    if len(potential_target_areas) < 1:
        return false
    for area in potential_target_areas:
        if not area is Hurtbox:
            continue
        var unit = area.get_parent()
        if faction.check_enemy(unit.faction.faction_name):
            print("Found new target: ")
            target = unit
            return true
    return false

func get_target_distance() -> float:
    return (target.global_position - global_position).length()

func verify_target(get_new_if_false: bool) -> bool:
    if target == null:
        return false
    if !is_instance_valid(target):
        return reset_target(get_new_if_false)
    return true

func ai_target(delta) -> void:
    if not verify_target(true):
        return
    # Aim at target
    target_angle = (target.global_position - global_position).angle()
    if not primary_ready or Utils.angle_distance(rotation, target_angle) > rotation_speed * delta:
        return
    shoot(primary)
    primary_ready = false
    primary_timer.start(primary_time)
    # if primary_timer.time_left > 0:
    #     return
    # shoot(primary)
    # primary_timer.start(primary_time)


func _process(_delta):
    sprite.scale = Vector2(1.0, 1.0) * max(1.0, 1.0 / camera.zoom.x)

    # Only move and target during play state
    var play_paused = controller.current_state != controller.State.Play
    primary_timer.paused = play_paused
    if play_paused:
        return

func get_move(_delta):
    var input_direction : Vector2 = terrain.get_unit_move(position, faction)
    var new_velocity = move_speed * input_direction
    velocity = Utils.approach_vector(velocity, new_velocity, acceleration)
    var speed = velocity.length()
    if speed > 0 and not verify_target(true):
        # var angle_to = sprite.transform.x.angle_to(input_direction)
        # var angle_rotate = input_direction.angle_to( sprite.rotation
        target_angle = input_direction.angle()
        # sprite.rotation = Utils.approach_angle(sprite.rotation, target_angle, rotation_speed * delta)
    # else:
        # collider.shape.radius = collision_radius
    set_moving(speed > 0)

func set_moving(is_moving: bool) -> void:
    if is_moving:
        collider.shape.radius = collision_moving_scale * collision_radius
    else:
        velocity = Vector2.ZERO
        collider.shape.radius = collision_radius

func update_velocity(delta) -> void:
    if not mobile and verify_target(true):
        return set_moving(false)

    var destination_distance = terrain.get_unit_destination_distance(0, position)
    if destination_distance < lax:
        return set_moving(false)

    get_move(delta)

func _physics_process(_delta):
    # Only move and target during play state
    if controller.current_state != controller.State.Play:
        return
    update_velocity(_delta)
    ai_target(_delta)
    rotation = Utils.approach_angle(rotation, target_angle, rotation_speed * _delta)
    # var collision := move_and_collide(velocity * _delta)
    # if collision:
    #     var collision_vector : Vector2 = collision.get_collider().global_position - global_position
    #     var collision_distance : float = max(collision_vector.length(), .1)
    #     var push_acceleration = push / pow(collision_distance, 2)
    #     var push_force = collision.get_normal().normalized() * push_acceleration
    #     print("V: " + str(velocity) + " Pushing: " + str(push_force) + " New: " + str(velocity + push_force))
    #     velocity += push_force

    move_and_slide()

# func init_projectile(projectile):
#     print("INITIALIZING PROJECTILE")
#     projectile.target_faction = target.faction
#     projectile.target = target
#     projectile.set_as_toplevel()

func shoot(projectile: PackedScene) -> void:
    var projectile_instance := projectile.instantiate()
    var tdir = (target.global_position - global_position).angle()
    var projectile_sprite = projectile_instance.get_node("Sprite2D")
    var projectile_size = projectile_sprite.texture.get_size()
    var projectile_scale = projectile_sprite.scale.x
    var gun_offset = primary_offset.rotated(tdir)
    var spawn_offset = gun_offset + Vector2.from_angle(tdir) * projectile_size.x * projectile_scale / 2.0

    var spawn_pos = global_position + spawn_offset

    projectile_instance.initialize(spawn_pos, tdir, target, faction, target.global_position)
    # projectile_instance.connect("ready", init_projectile)
    # projectile_instance.global_position = global_position
    # projectile_instance.rotation = sprite.rotation
    # emit_signal("projectile_created", projectile_instance)
    spawn_node.add_child(projectile_instance)
    # projectile_instance.
