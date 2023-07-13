extends Area2D
const Array2D = preload("../Utils/Array2D.gd")

@onready var sprite : Sprite2D = get_node("Sprite2D")
@onready var shape : CollisionShape2D = get_node("CollisionShape2D")
@onready var selection_rectangle : ColorRect = get_node("ColorRect")

@onready var camera = get_node("../Camera")

@export var height_min : float = 0
@export var height_max : float = 100
@export var selection_color : Color = Color(1, 1, 1, .25)
@export var selected_width : float = 1

var zero : Vector2 = Vector2(0, 0)
var bounds : Vector2
var inner_bounds : Vector2
var map : Map

class Cell:
    var position : Vector2i
    var id : int = 0
    var height : float = 0

    func _init(_position : Vector2i, _height : float):
        position = _position
        id = position.x * position.y
        height = _height


class Map:
    var grid : Array2D
    var scale : int

    func _init(_sprite : Sprite2D, _low : float, _high : float):
        var size = _sprite.texture.get_size()
        var image = _sprite.texture.get_image()
        scale = floor(_sprite.scale.x)
        grid = Array2D.new(size)

        for r in range(grid.length):
            for c in range(grid.width):
                image.get_height()
                var color : Color = image.get_pixel(r, c)
                var height_ratio = color.r  # r = g = b
                var height : float = lerp(_low, _high, height_ratio)
                var cell = Cell.new(Vector2i(r, c), height)
                var position = Vector2(r, c)
                grid.set_cell(position, cell)

    func get_height(position : Vector2i):
        var cell = grid.get_cell(position)
        return cell.height

    func get_height_raw(position : Vector2):
        var position_nearest = (position / scale).floor()
        var cell = grid.get_cell(position_nearest)
        return cell.height



func set_bounds():
    bounds = sprite.texture.get_size() * sprite.scale
    inner_bounds = bounds - Vector2(1, 1)

func set_camera_bounds():
    camera.max_position = bounds

func set_shape_bounds():
    shape.shape.set_size(bounds)
    shape.position = bounds / 2

func set_selection_rectangle():
    selection_rectangle.color = selection_color

func init_map():
    map = Map.new(sprite, height_min, height_max)

func _ready():
    set_bounds()
    set_camera_bounds()
    set_shape_bounds()
    set_selection_rectangle()
    init_map()

func _input_event(_viewport, _event, _shape_idx):
    if _event is InputEventMouseButton \
        and _event.button_index == MOUSE_BUTTON_LEFT \
        and _event.is_pressed():

        on_click()

func _process(_delta):
    var mouse_pos = get_local_mouse_position().clamp(zero, inner_bounds)
    var mouse_pos_scaled = mouse_pos / map.scale
    var pos_min : Vector2 = floor(mouse_pos_scaled) * map.scale
    var pos_max = pos_min + Vector2(1, 1) * map.scale
    var selected_rect_size = pos_max - pos_min

    selection_rectangle.set_size(selected_rect_size)
    selection_rectangle.set_position(pos_min)

func on_click():
    var mouse_pos = get_local_mouse_position()
    print(mouse_pos)
    print(map.get_height_raw(mouse_pos))
