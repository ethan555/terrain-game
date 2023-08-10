extends Node2D

@onready var area : Area2D = $Area2D
@onready var terrain : Terrain = get_node("/root/Level/Terrain")
@onready var controller := get_node("/root/Level/Controller")

@export var charges := -1
@export var unit_rows := 1
@export var unit_columns := 1
@export var unit_type : PackedScene

var instanced = false
var placed = false
var placed_position : Vector2


func init_spawn_area():
    var unit_collision : CollisionShape2D = unit_type.get_node("CollisionShape2D")
    var unit_shape : CircleShape2D = unit_collision.shape
    var unit_size : float = unit_shape.get_radius() * 2

    var spawn_length = unit_size * unit_columns
    var spawn_width = unit_size * unit_rows * unit_columns

    var area_collision_shape : CollisionShape2D = area.get_node("CollisionShape2D")
    var area_shape : RectangleShape2D = area_collision_shape.shape
    var area_size := Vector2(spawn_length, spawn_width)

    area_shape.set_size(area_size)


func _ready():
    init_spawn_area()

func on_select_click():
    if placed:
        controller.set_selected(self)
        placed = false
    else:
        controller.reset_selected()
        placed_position = global_position
        placed = true
        instanced = true

func on_cancel_click():
    controller.reset_selected()
    if instanced:
        global_position = placed_position
    else:
        # Never got placed, cancel creation
        queue_free()

func on_click(event: InputEventMouseButton):
    if event.button_index == MOUSE_BUTTON_LEFT:
        on_select_click()
    if event.button_index == MOUSE_BUTTON_RIGHT:
        on_cancel_click()

func _input(event):
    if event is InputEventMouseButton and event.is_pressed():
        on_click(event)

func _process(_delta):
    if placed:
        return

    var mouse_pos := get_global_mouse_position()
    var grid_pos := terrain.map.snap_world_position(mouse_pos)
    global_position = grid_pos
