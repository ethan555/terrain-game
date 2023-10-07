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
@onready var hurtbox : Hurtbox = $Hurtbox
@onready var hurtbox_radius := hurtbox.collision_radius
@onready var vision : Vision = $Vision
@onready var primary_timer : Timer = $PrimaryTimer
@onready var boid : Boid = $Boid

@export_category("Stats")
@export var faction : Faction

@export var vision_radius : float = 140
@export var primary := preload("res://Projectiles/bullet.tscn")
@export var primary_time : float = 1
@export var primary_offset : Vector2 = Vector2(0, 0)

@export_category("Movement")
@export var collision_moving_scale : float = .5
@export var move_speed : float = 300
@export var acceleration : float = 100
@export var push : float = 10

@export var lax : float = 1.0
# @export var lax_rate : float = 10.0
@export var rotation_speed : float = 3 * PI
@export var FRICTION : float = 100 * 9.8

@export var mobile : bool = false
@export var ground : bool = true
@export var mass : float = 1.0

@export_category("Flocking")
@export var avoid_radius : float = 10
@export var avoid_speed : float = 50


var target_angle := rotation
var target_velocity := Vector2.ZERO
var collision_index : int = 0
var max_collisions : int = 10

var need_to_move : bool = false

var potential_targets : Dictionary = {}
var target : Node2D
var primary_ready = true

# var boids : Dictionary = {}

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
    # if verify_target(true):
    #     return
    if faction.check_enemy(unit.faction.faction_name):
        if verify_target(true):
            potential_targets[unit.name] = unit
        else:
            target = unit
    # elif unit is Unit:
    #     boids[unit.name] = unit
    # else:
    #     print("FRIENDLIES OVER HERE")

func _on_primary_timeout():
    primary_ready = true
    # if not verify_target(true):
    #     return


func _on_enemy_left_range(unit: Node2D) -> void:
    if unit == target:
        reset_target(true)
    elif potential_targets.has(unit.name):
        potential_targets.erase(unit.name)
    # elif boids.has(unit.name):
    #     boids.erase(unit.name)

func reset_target(get_new: bool) -> bool:
    target = null
    if not get_new:
        return false

    var min_dist := vision_radius + 1
    for n in potential_targets.keys():
        if !is_instance_valid(potential_targets[n]):
            potential_targets.erase(n)
            continue
        var potential_target : Node2D = potential_targets[n]
        var udiff := (potential_target.global_position - global_position)
        var udist : float = udiff.length() - (collision_radius + potential_target.collision_radius)
        if udist <= min_dist:
            min_dist = udist
            target = potential_target

    if target != null:
        return true

    # var potential_target_areas : Array[Area2D] = vision.get_new_areas()
    # print("New targets: " + str(len(potential_target_areas)))
    # if len(potential_target_areas) < 1:
    #     return false
    # for area in potential_target_areas:
    #     if not area is Hurtbox:
    #         continue
    #     var unit = area.get_parent()
    #     if faction.check_enemy(unit.faction.faction_name):
    #         print("Found new target: ")
    #         target = unit
    #         return true
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
    sprite.scale = Vector2.ONE * max(1.0, 1.0 / camera.zoom.x)

    # Only move and target during play state
    var play_paused = controller.current_state != controller.State.Play
    primary_timer.paused = play_paused
    if play_paused:
        return
    ai_target(_delta)
    lax = max(2, get_tree().get_nodes_in_group("units").size() / terrain.map.scale)
    update_target_velocity(_delta)

# func get_boid_velocity(moving: bool) -> Vector2:
#     var bv := Vector2.ZERO

#     for key in boids.keys():

#         var u : Unit = boids[key]
#         var adist := u.global_position - global_position
#         var alen := adist.length()
#         if alen > avoid_radius:
#             continue

#         var adir := -adist.normalized()

#         var avoid_amount := (avoid_radius - alen) / avoid_radius
#         bv += adir * avoid_amount

#         # Only care about other velocity if we are moving
#         if !moving:
#             continue
#         var v := u.velocity
#         var vdir := v.normalized()

#         bv += vdir * avoid_amount

#     bv = bv.normalized()

#     return bv

func get_move(_delta : float, boid_dir: Vector2) -> Vector2:
    var input_direction : Vector2 = terrain.get_unit_move(position, faction) + boid_dir
    var new_velocity = stats.speed * input_direction.normalized()
    return new_velocity
    # var new_velocity = Utils.approach_vector(velocity, target_velocity, acceleration)
    # return new_velocity

func set_moving(is_moving: bool) -> void:
    if is_moving:
        collider.shape.radius = collision_moving_scale * collision_radius
    else:
        collider.shape.radius = collision_radius

func update_target_velocity(delta) -> void:
    var moving = true
    if not mobile and verify_target(true):
        moving = false
        # return set_moving(false)

    if moving:
        var destination_distance = terrain.get_unit_destination_distance(0, position)
        if !need_to_move:
            moving = destination_distance > lax * 2
            need_to_move = moving
        elif destination_distance < lax:
            need_to_move = false
            moving = false
        # return set_moving(false)

    var boid_dir := boid.get_boid_direction(moving)
    # if boid_v.length() > 0:
    #     moving = true

    if moving:
        target_velocity = get_move(delta, boid_dir)
        # velocity = Utils.approach_vector(velocity, target_velocity, acceleration)
    else:
        target_velocity = avoid_speed * boid_dir

    var speed = target_velocity.length()
    if speed > 0 and not verify_target(true):
        target_angle = target_velocity.angle()

    set_moving(speed > 0)

func _physics_process(_delta):
    # Only move and target during play state
    if controller.current_state != controller.State.Play:
        return
    # update_target_velocity(_delta)

    if target_velocity.length() > 0:
        velocity = Utils.approach_vector(velocity, target_velocity, acceleration)
    else:
        velocity = Utils.approach_vector(velocity, target_velocity, FRICTION * _delta)

    # ai_target(_delta)
    rotation = Utils.approach_angle(rotation, target_angle, rotation_speed * _delta)
    # var collision := move_and_collide(velocity * _delta)
    # if collision:
    #     var collision_vector : Vector2 = collision.get_collider().global_position - global_position
    #     var collision_distance : float = max(collision_vector.length(), .1)
    #     var push_acceleration = push / pow(collision_distance, 2)
    #     var push_force = collision.get_normal().normalized() * push_acceleration
    #     print("V: " + str(velocity) + " Pushing: " + str(push_force) + " New: " + str(velocity + push_force))
    #     velocity += push_force

    # var old_pos := global_position
    if velocity.length() > 0:
        var _collided := move_and_slide()



    # if _collided:
    #     var collision_count := get_slide_collision_count()
    #     # if collision_count <= max_collisions:
    #     #     collision_index = 0
    #     var collision_check_count : int = min(collision_count, max_collisions)
    #     # var unit_collisions : int = 0
    #     for i in range(collision_check_count):
    #         # Only check a maximum of 10 collisions
    #         # var ci = Utils.modulo(collision_index + i, collision_count)
    #         # collision_index += max_collisions
    #         var collision := get_slide_collision(i)
    #         var unit := collision.get_collider()
    #         if !is_instance_of(unit, Unit):
    #             continue
    #         # unit_collisions += 1
    #         # var cdir := Vector2.from_angle(collision.get_angle(Vector2.RIGHT))
    #         # print(cdir)
    #         # global_position -= cdir * 2 * (mass / (mass + unit.mass))
    #         var cpos : Vector2 = unit.global_position
    #         var cdist = cpos - old_pos #collision.get_position() - global_position
    #         # print(str(cdist) + ", " + str(old_pos) + ", " + str(cpos))
    #         if cdist.length() < .1:
    #             # print("FUCK YOU")
    #             cdist = Vector2.RIGHT
    #         global_position -= cdist.normalized() * 2 * (mass / (mass + unit.mass))
    #     # lax += _delta * unit_collisions * lax_rate
    # # else:
    # #     lax = max(lax - _delta * lax_rate, 1)
    # global_position = global_position.clamp(Vector2.ZERO, terrain.inner_bounds)

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
