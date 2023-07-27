class_name Projectile
extends Node2D

@export var speed := 800.0
@export var lifespan := 4.0

@export var homing := true
@export var attack : Attack

@onready var hitbox := $Hitbox
@onready var timer := $Timer

var target: Node2D
var target_location: Vector2
var target_faction: Faction

var velocity := Vector2(0, 0)

func initialize(_position: Vector2, _rotation: float, _target: Node2D, _target_faction: Faction, _target_location: Vector2):
    global_position = _position
    rotation = _rotation
    target = _target
    target_faction = _target_faction
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

func hit_target() -> void:
    print("WE GOT HIM")
    if is_instance_valid(target):
        target.stats.damage(attack)
    queue_free()

func _process(_delta):
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
    position += velocity * _delta

func _on_impact(_body: Node) -> void:
    print("IMPACT")
    pass
