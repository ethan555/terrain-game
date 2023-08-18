# @tool
extends Node2D

@onready var spawn_node := get_node("/root/Level")
@onready var area : Area2D = $Area2D
@onready var area_collision_shape : CollisionShape2D = area.get_node("CollisionShape2D")
@onready var select_box : SelectBox = $SelectBox
@onready var select_box_shape : CollisionShape2D = select_box.get_node("CollisionShape2D")
@onready var terrain : Terrain = get_node("/root/Level/Terrain")
@onready var controller : Controller = get_node("/root/Level/Controller")

@export var faction : Faction
@export var charges := -1
@export var unit_rows := 1
@export var unit_columns := 1
@export var unit_scene : PackedScene
@export var unit_texture : Texture2D
@export var unit_scale : int = 1

var instanced = false
var placed = false
var placed_position : Vector2
var select_color : Color
var unit_color : Color

var valid_position := false

var building : Building = null

func init_spawn_area():
    # var unit_collision : CollisionShape2D = unit_scene.get_node("CollisionShape2D")
    # var unit_shape : CircleShape2D = unit_collision.shape
    # var unit_size : float = unit_shape.get_radius() * 2

    var spawn_length = terrain.map.scale * unit_scale * unit_rows
    var spawn_width = terrain.map.scale * unit_scale * unit_columns

    # var area_collision_shape : CollisionShape2D = area.get_node("CollisionShape2D")
    var area_shape : RectangleShape2D = area_collision_shape.shape
    var area_size := Vector2(spawn_length, spawn_width)

    area_shape.set_size(area_size)

    select_box_shape.shape.set_size(area_size)

    queue_redraw()

    controller.next_round_signal.connect(_on_next_round_signal)

func _ready():
    init_spawn_area()

    if is_instance_valid(building):
        building.stats.connect("death", _on_death)
    elif charges == -1:
        # Building spawner, can only exist with a building
        queue_free()
        return

    select_box.connect("select_click", _on_select_click)

    select_color = faction.color
    select_color.a = 0.1
    unit_color = faction.color
    unit_color.a = 0.5

func _on_select_click():
    if placed:
        controller.set_selected(self, true, false)
        placed = false
    else:
        if valid_position:
            placed_position = global_position
            placed = true
            instanced = true
            controller.reset_selected()

func deselect():
    select_box.set_selected(false)
    if instanced:
        global_position = placed_position
    else:
        # Never got placed, cancel creation
        queue_free()

# func on_click(event: InputEventMouseButton):
#     if event.button_index == MOUSE_BUTTON_LEFT:
#         on_select_click()
#     if event.button_index == MOUSE_BUTTON_RIGHT:
#         on_cancel_click()

# func _input(event):
#     if event is InputEventMouseButton and event.is_pressed():
#         on_click(event)

func _on_selected_input(event):
    pass

func spawn_unit(spawn_position: Vector2):
# func spawn_unit(unit: PackedScene, total: int, index: int) -> void:
    var inst := unit_scene.instantiate()
    var tdir = rotation
    inst.rotation = tdir
    inst.faction = faction
    inst.set_as_top_level(true)
    inst.global_position = global_position + spawn_position
    spawn_node.add_child(inst)

func _on_next_round_signal(_round_counter: int, spawning_round: bool):
    if not spawning_round:
        return
    # Spawn units
    # var unit_center_vector = -unit_texture.get_size() / 2.0
    var unit_spacing = unit_scale * 16  # terrain.map.scale
    var grid_x = -unit_spacing * unit_rows / 2.0 + 8
    var grid_y = -unit_spacing * unit_columns / 2.0 + 8
    for r in range(unit_rows):
        var gx = grid_x + r * unit_spacing
        for c in range(unit_columns):
            var gy = grid_y + c * unit_spacing
            var placement_vector = Vector2(gx, gy)
            spawn_unit(placement_vector)

func _process(_delta):
    if placed:
        return

    if not is_instance_valid(terrain):
        return
    var mouse_pos := get_global_mouse_position()
    var offset_x = unit_rows % 2 == 1
    var offset_y = unit_columns % 2 == 1
    var grid_pos := terrain.map.snap_world_position(mouse_pos, offset_x, offset_y)
    global_position = grid_pos

    var building_distance := (building.global_position - global_position).length()
    valid_position = building_distance <= building.spawn_radius

func _draw():
    var area_shape : RectangleShape2D = area_collision_shape.shape
    var area_rect := area_shape.get_rect()
    draw_rect(area_rect, select_color, true)

    # var unit_texture : Sprite2D = unit_scene.get_node("Sprite2D")
    # var unit_texture := unit_texture
    var unit_center_vector = -unit_texture.get_size() / 2.0
    var unit_spacing = unit_scale * 16  # terrain.map.scale
    var grid_x = -unit_spacing * unit_rows / 2.0 + 8
    var grid_y = -unit_spacing * unit_columns / 2.0 + 8
    for r in range(unit_rows):
        var gx = grid_x + r * unit_spacing
        for c in range(unit_columns):
            var gy = grid_y + c * unit_spacing
            var placement_vector = Vector2(gx, gy)
            draw_texture(unit_texture, unit_center_vector + placement_vector, unit_color)

func _on_death():
    queue_free()
