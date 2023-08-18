class_name Terrain
extends Area2D
const Array2D = preload("res://Utils/Array2D.gd")
const font : Font = preload("terrain.tres")

@onready var sprite : Sprite2D = get_node("Sprite2D")
# @onready var destinations_uniform = sprite.material.get_shader_parameter("destinations")
@onready var shape : CollisionShape2D = get_node("CollisionShape2D")
@onready var selection_rectangle : ColorRect = get_node("ColorRect")
@onready var particles : GPUParticles2D = get_node("GPUParticles2D")

@onready var camera = get_node("/root/Level/Camera")
@onready var controller := get_node("/root/Level/Controller")

@export var height_min : float = 0
@export var height_max : float = 100
@export var debug_color : Color = Color(1, 1, 1, .9)
@export var selection_color : Color = Color(1, 1, 1, .25)
@export var selected_width : float = 1

var bounds : Vector2
var inner_bounds : Vector2
var map : Map

class Cell:
    var position : Vector2i
    var id : int = 0
    var height : float = 0
    var cost : float = 0
    var direction : Vector2 = Vector2.ZERO

    func _init(_position : Vector2i, _size : Vector2i, _height : float):
        position = _position
        id = position.x * _size.x + position.y
        height = _height

class MapLevels:
    var id : int;
    var destination : Cell;
    var queue : Array;
    var visited : Array;
    var alpha : float = 0.0;

class Map:
    var size : Vector2i
    var grid : Array2D
    var scale : int

    # 0 - 10 [{
    #   destination,
    #   paths {
    #       cell_id : Vector2 direction
    #   }
    # }]
    var heat_maps : Array = []
    var destinations : Dictionary = {}
    var cell_queues : Dictionary = {}
    var cell_visited : Dictionary = {}
    var alphas : Dictionary = {}
    var max_distances : Dictionary = {} 
    var neighbor_array = [
        Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(-1, 1),
        Vector2i(0, -1), Vector2i(0, 1),
        Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1)
    ]

    func _init(_sprite : Sprite2D, _low : float, _high : float):
        size = _sprite.texture.get_size()
        var image = _sprite.texture.get_image()
        scale = floor(_sprite.scale.x)
        grid = Array2D.new(size)
        heat_maps.resize(11)

        for r in range(grid.length):
            for c in range(grid.width):
                image.get_height()
                var color : Color = image.get_pixel(r, c)
                var height_ratio = color.r  # r = g = b
                var height : float = lerp(_low, _high, height_ratio)
                var cell = Cell.new(Vector2i(r, c), size, height)
                var position = Vector2(r, c)
                grid.set_cell(position, cell)

    ## Scale a world position to the map scale, top left of cells
    func scale_position(position : Vector2) -> Vector2:
        return floor(position / scale)

    func snap_position(position: Vector2) -> Vector2:
        return floor(position / scale)

    ## Snap a world position to the map scale grid, in world coordinates
    func snap_world_position(position : Vector2, offset_x := false, offset_y := false) -> Vector2:
        var result = snap_position(position) * scale
        var offset = Vector2.RIGHT * int(offset_x) + Vector2.DOWN * int(offset_y)
        offset = offset * scale / 2
        return result + offset

    ## Scale a world position to the map scale, centered on cells
    func world_to_map(position : Vector2) -> Vector2:
        return scale_position(position) + Vector2(.5, .5)

    ## Check if a local position on the map is within the map bounds
    func check_cell(position : Vector2i) -> bool:
        return position.x >= 0 \
            and position.x < size.x \
            and position.y >= 0 \
            and position.y < size.y

    func get_cell(position : Vector2i) -> Cell:
        var cell = grid.get_cell(position)
        return cell

    func get_cell_position_world(cell: Cell) -> Vector2:
        var position_world = (Vector2(cell.position) + Vector2(.5, .5)) * scale
        return position_world

    func get_height(position : Vector2i) -> float:
        var cell = grid.get_cell(position)
        return cell.height

    func get_height_raw(position : Vector2) -> float:
        var position_nearest = (position / scale).floor()
        var cell = grid.get_cell(position_nearest)
        return cell.height

    func get_destination(id) -> Variant:
        if id not in destinations:
            return null
        return destinations[id].position

    func get_max_distance(id) -> float:
        if id not in destinations:
            return 0
        return max_distances[id]

    func set_destination(id, position, particles) -> void:
        var selected_position = scale_position(position)
        if not check_cell(selected_position):
            return
        var destination = get_cell(selected_position)
        destinations[id] = destination
        destination.direction = Vector2.ZERO
        if id not in cell_queues:
            cell_queues[id] = []
        cell_queues[id].clear()
        if id not in cell_visited:
            cell_visited[id] = {}
        cell_visited[id].clear()
        alphas[id] = 1.0
        max_distances[id] = 0.0
        make_paths(id, particles)

    func get_neighbors(cell : Cell) -> Array[Cell]:
        var neighbors = []
        for n in neighbor_array:
            var neighbor_pos = cell.position + n
            if not check_cell(neighbor_pos):
                continue
            var neighbor : Cell = get_cell(neighbor_pos)
            neighbors.append(neighbor)
        return neighbors

    func make_paths(id, _particles : GPUParticles2D) -> bool:
        var destination : Cell = destinations[id]
        destination.cost = 0
        var cell_queue = cell_queues[id]
        # cell_queue.clear()
        if cell_queue.size() < 1:
            cell_queue.push_back(destination)

        var visited : Dictionary = cell_visited[id]
        visited[destination.id] = true
        var operations = 0
        while cell_queue.size() > 0:
            operations += 1
            if operations > 256:
                return false
            var current_cell : Cell = cell_queue.pop_front()
            # var cell_position_world = get_cell_position_world(current_cell)
            # particles.emit_particle(Transform2D(cell_position_world, cell_position_world, cell_position_world), Vector2.ZERO, Color(), Color(), 1)
            # var neighbors = get_neighbors(current_cell)
            for n in neighbor_array:
                var neighbor_pos = current_cell.position + n
                if not check_cell(neighbor_pos):
                    continue
                var neighbor = get_cell(neighbor_pos)
                var neighbor_dir : Vector2 = current_cell.position - neighbor.position
                var length_cost : float = neighbor_dir.length()
                var height_diff = max(0, current_cell.height - neighbor.height) # max(0, neighbor.height - current_cell.height)
                var height_cost = height_diff #pow(height_diff, 2.0)
                var cost = current_cell.cost + length_cost + height_cost
                if neighbor.id in visited:
                    if neighbor.cost > cost:
                        neighbor.cost = cost
                        neighbor.direction = neighbor_dir
                else:
                    neighbor.cost = cost
                    neighbor.direction = neighbor_dir
                    cell_queue.push_back(neighbor)
                    visited[neighbor.id] = true

            var destination_distance = max(abs(destination.position.x - current_cell.position.x), abs(destination.position.y - current_cell.position.y)) #(destination.position - current_cell.position).length()
            var max_distance = max_distances[id]
            max_distances[id] = max(max_distance, destination_distance)
            # current_cell.direction = current_cell.direction.normalized()
        cell_queue.clear()
        visited.clear()
        max_distances[id] = size.x * size.y
        return true

    func process(particles : GPUParticles2D, sprite : Sprite2D, delta) -> bool:
        # var should_redraw = false
        var dest_values = []
        var should_redraw = false
        dest_values.resize(11)
        for id in cell_queues:
            var cell_queue = cell_queues[id]
            var destination = destinations[id]
            if not cell_queue.size() < 1:
                var finished = make_paths(id, particles)
                var destination_pos : Vector2 = Vector2(destination.position)
                var destinations_uniform = sprite.material.get_shader_parameter("destinations")
                if not finished:
                    var alpha = alphas[id]
                    var max_distance = max_distances[id]
                    # var destinations_value = destinations_uniform[0]
                    # print(destinations_uniform[0])
                    # var destination_why = 0.0
                    # Godot is actual garbage. This shouldn't be necessary.
                    # if destinations_value.x > 0:
                    #     destination_why = destinations_value.z
                    var destination_dist = max_distance
                    destinations_uniform[id] = Vector3(destination_pos.x, destination_pos.y, destination_dist) #, alpha)
                    alphas[id] = max(alpha - delta, 0)
                    sprite.material.set_shader_parameter("destinations", destinations_uniform)
                    should_redraw = true
                else:
                    should_redraw = true
                    destinations_uniform[id] = Vector3(destination_pos.x, destination_pos.y, 0)
                    sprite.material.set_shader_parameter("destinations", destinations_uniform)
        return should_redraw


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

func init_shader():
    var destinations_uniform = []
    destinations_uniform.resize(11)
    for d in range(destinations_uniform.size()):
        destinations_uniform[d] = Vector2(-1.0, -1.0)
    sprite.material.set_shader_parameter("destinations", destinations_uniform)

func _ready():
    set_bounds()
    set_camera_bounds()
    set_shape_bounds()
    set_selection_rectangle()
    init_map()
    init_shader()

    controller.terrain_click.connect(on_click)

# func _input_event(_viewport, event, _shape_idx):
#     if event is InputEventMouseButton \
#         and event.button_index == MOUSE_BUTTON_RIGHT \
#         and event.is_pressed():

#         on_click()
        # get_tree().get_root().set_input_as_handled()

func _process(_delta):
    var mouse_pos = get_local_mouse_position().clamp(Vector2.ZERO, inner_bounds)
    var mouse_pos_scaled = map.scale_position(mouse_pos)
    var pos_min : Vector2 = mouse_pos_scaled * map.scale
    var pos_max = pos_min + Vector2(1, 1) * map.scale
    var selected_rect_size = pos_max - pos_min

    selection_rectangle.set_size(selected_rect_size)
    selection_rectangle.set_position(pos_min)

    var should_redraw = map.process(particles, sprite, _delta)
    # if should_redraw:
    #     queue_redraw()

func on_click():
    var mouse_pos = get_local_mouse_position()
    map.set_destination(0, mouse_pos, particles)
    # var scaled_position = map.scale_position(mouse_pos)
    # var destinations_uniform = sprite.material.get_shader_parameter("destinations")
    # print(destinations_uniform)
    # destinations_uniform[0] = scaled_position
    # sprite.material.set_shader_parameter("destinations", destinations_uniform)
    # queue_redraw()

func get_unit_destination_distance(id, unit_position):
    var destination = map.get_destination(id)
    if destination == null:
        return 0
    var scaled_position = map.world_to_map(unit_position)
    var destination_distance = (Vector2(destination) - scaled_position).length()
    if destination_distance > map.get_max_distance(id):
        return 0
    return destination_distance

func get_unit_destination(id):
    var destination = map.get_destination(id)
    return destination

func get_unit_move(unit_position : Vector2, faction: Faction):
    if faction.id != 0:
        return Vector2.ZERO
    var scaled_position = map.world_to_map(unit_position)
    var unit_cell : Cell = map.get_cell(scaled_position)
    return unit_cell.direction


func _draw():
    pass
    # var line_length = (float(map.scale)) / 2
    # for r in range(map.size.x):
    #     for c in range(map.size.y):
    #         var cell = map.get_cell(Vector2i(r, c))
    #         # if cell.cost == 0:
    #         #     continue
    #         var cell_position = map.get_cell_position_world(cell)
    #         draw_line(cell_position, cell_position + cell.direction * line_length, debug_color, 1.0)
            # draw_string(font, cell_position, str(round(cell.cost)))
