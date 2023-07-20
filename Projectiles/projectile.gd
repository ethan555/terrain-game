class_name Projectile
extends Node2D

@export var speed := 100.0
@export var lifespan := 4.0

@export var homing := true
@export var attack : Attack

@onready var hitbox := $Hitbox
@onready var timer := $Timer

var target: Unit
var target_location: Vector2

var velocity := Vector2(0, 0)


func _ready():
    timer.connect("timeout", queue_free)
    timer.start(lifespan)

    hitbox.connect("body_entered", _on_impact)

func _physics_process(_delta):
    position += velocity * _delta

func _on_impact(_body: Node) -> void:
    print("IMPACT")
    pass