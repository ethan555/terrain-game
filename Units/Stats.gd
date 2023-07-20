extends Node2D

class_name Stats

@export var MAX_HEALTH := 10.0
@export var faction : Faction

signal death

var health : float

func _ready():
    health = MAX_HEALTH

func damage(attack : Attack):
    health -= attack.damage

    if health <= 0:
        death.emit()