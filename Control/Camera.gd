class_name Camera
extends Camera2D
const Utils = preload("res://Utils/utils.gd")

@export var move_speed : float = 750
@export var zoom_min : float = .5
@export var zoom_max : float = 4
@export var zoom_rate : float = 2
@export var zoom_lerp_rate : float = .05
@export var zoom_seconds : float = .5


var min_position : Vector2 = Vector2(0,0)
var max_position : Vector2 = Vector2(1,1)

var target_zoom = zoom_min

func _input(event):
    if event.is_action_pressed("zoom_out"):
        target_zoom = max(target_zoom / zoom_rate, zoom_min)
    if event.is_action_pressed("zoom_in"):
        target_zoom = min(target_zoom * zoom_rate, zoom_max);

func _process(_delta):
    var new_zoom = Utils.dlerps(zoom.x, target_zoom, zoom_lerp_rate, _delta, zoom_seconds)
    zoom = Vector2(new_zoom, new_zoom)

    var input_direction = Vector2(
        Input.get_action_strength("right") - Input.get_action_strength("left"),
        Input.get_action_strength("down") - Input.get_action_strength("up")
    )

    global_position += _delta * input_direction * move_speed / zoom.x
    global_position = global_position.clamp(min_position, max_position)
    # global_position.x = clamp(global_position.x, 0, max_x)
    # global_position.y = clamp(global_position.y, 0, max_y)
