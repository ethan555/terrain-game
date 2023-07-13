extends CharacterBody2D

@onready var sprite = get_node("Sprite2D")
@onready var camera = get_node("../Camera")

func _process(_delta):
    scale = Vector2(1.0, 1.0) * max(1.0, 1.0 / camera.zoom.x)

func _physics_process(_delta):
    var input_direction = Vector2()
