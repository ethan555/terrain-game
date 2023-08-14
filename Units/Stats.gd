extends Node

class_name Stats

@export var MAX_HEALTH := 10.0
@export var armor := 0.0

signal death

var health : float

func _ready():
    health = MAX_HEALTH

func damage(attack : Attack, delta := 1.0):
    health -= attack.get_damage(armor) * delta

    if health <= 0:
        death.emit()
