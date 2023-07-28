extends Node

class_name Stats

@export var MAX_HEALTH := 10.0

signal death

var health : float

func _ready():
    health = MAX_HEALTH

func damage(attack : Attack):
    health -= attack.get_damage()

    if health <= 0:
        death.emit()
