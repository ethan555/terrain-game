extends Resource
class_name Attack

@export var damage : float = 1.0
@export var radius : float = 0

@export var multiplier : float = 1.0

func get_damage():
    return damage * multiplier
