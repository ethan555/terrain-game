class_name Unit
extends CharacterBody2D
const Utils = preload("res://Utils/utils.gd")

signal projectile_created(Projectile)

@onready var camera = get_node("../Camera")
@onready var terrain = get_node("../Terrain")

@onready var sprite : Sprite2D = get_node("Sprite2D")
@onready var collider : CollisionShape2D = get_node("CollisionShape2D")
@onready var collision_radius : float = collider.shape.radius

@onready var hurtbox := $Hurtbox
@onready var vision := $Vision
@onready var primary_timer : Timer = $PrimaryTimer

@export_category("Stats")
@export var faction : Faction
@export var stats : Stats
@export var collision_moving_scale : float = .5
@export var move_speed : float = 300
@export var lax : float = 1.0
@export var rotation_speed : float = 3 * PI

@export var mobile : bool = false
@export var ground : bool = true

@export var vision_radius : float = 140
@export var primary := preload("res://Projectiles/bullet.tscn")
@export var primary_time : float = 1

var target_angle = (-Vector2.UP).angle()

var target : Unit
var primary_ready = true


func _ready():
    vision.update_vision_radius(vision_radius)
    vision.enemy_in_range.connect(_on_enemy_in_range)
    vision.enemy_left_range.connect(_on_enemy_left_range)

    primary_timer.connect("timeout", _on_primary_timeout)

    stats.connect("death", _on_death)

func _on_death() -> void:
    print("I DIED")
    queue_free()

func _on_enemy_in_range(unit: Unit) -> void:
    if verify_target(false):
        return
    if faction.check_enemy(unit.faction.faction_name):
        print("ENEMY IN RANGE")
        target = unit
    else:
        print("FRIENDLIES OVER HERE")

func _on_primary_timeout():
    if not verify_target(true):
        return
    primary_ready = true

func _on_enemy_left_range(unit: Unit) -> void:
    if unit == target:
        print("HE GOT AWAY")
        reset_target(true)

func reset_target(get_new: bool) -> bool:
    target = null
    if not get_new:
        return false
    var potential_target_areas : Array[Area2D] = vision.get_new_areas()
    if potential_target_areas.size() < 1:
        return false
    for area in potential_target_areas:
        if not area is Hurtbox:
            continue
        var unit = area.owner
        if faction.check_enemy(unit.faction.faction_name):
            print("ENEMY IN RANGE")
            target = unit
            return true
    return false

func get_target_distance() -> float:
    return (target.global_position - global_position).length()

func verify_target(get_new_if_false: bool) -> bool:
    if target == null:
        return false
    if !is_instance_valid(target):
        print("LOST HIM " + str(get_target_distance()) + " > " + str(vision_radius))
        return reset_target(get_new_if_false)
    return true

func ai_target() -> void:
    if not verify_target(true):
        return
    # Shoot at target
    if not primary_ready:
        return
    print("FIRING")
    shoot(primary)
    primary_ready = false
    primary_timer.start(primary_time)
    # if primary_timer.time_left > 0:
    #     return
    # shoot(primary)
    # primary_timer.start(primary_time)


func _process(_delta):
    sprite.scale = Vector2(1.0, 1.0) * max(1.0, 1.0 / camera.zoom.x)
    ai_target()

func get_move(delta):
    var input_direction : Vector2 = terrain.get_unit_move(position)
    velocity = move_speed * input_direction
    var speed = velocity.length()
    if speed > 0:

        # var angle_to = sprite.transform.x.angle_to(input_direction)
        # var angle_rotate = input_direction.angle_to( sprite.rotation
        target_angle = input_direction.angle()
        sprite.rotation = Utils.approach_angle(sprite.rotation, target_angle, rotation_speed * delta)
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
    update_velocity(_delta)
    move_and_slide()

# func init_projectile(projectile):
#     print("INITIALIZING PROJECTILE")
#     projectile.target_faction = target.faction
#     projectile.target = target
#     projectile.set_as_toplevel()

func shoot(projectile: PackedScene) -> void:
    var projectile_instance := projectile.instantiate()
    var tdir = (target.global_position - global_position).angle()
    projectile_instance.initialize(global_position, tdir, target, target.faction, target.global_position)
    # projectile_instance.connect("ready", init_projectile)
    # projectile_instance.global_position = global_position
    # projectile_instance.rotation = sprite.rotation
    # emit_signal("projectile_created", projectile_instance)
    add_child(projectile_instance)
    # projectile_instance.
