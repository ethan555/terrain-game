class_name Building
extends Node2D

@onready var spawn_node := get_node("/root/Level")
@onready var stats : Stats = $Stats
@onready var controller : Controller = get_node("/root/Level/Controller")

@onready var select_box : SelectBox = $SelectBox
@onready var hurtbox : Hurtbox = $Hurtbox
@onready var hurtbox_radius : float = hurtbox.collision_radius

@export var faction : Faction
@export var actions : Array[Action]
@export var passive_actions : Array[Action]

@export var build_actions : Array[BuildAction]
@export var spawn_areas : Array[PackedScene]
@export var spawn_radius : float

var radius_color : Color

# @export var spawnable_units : Array[PackedScene]

# var spawning_units : Array

func _ready():
    # spawning_units.resize(len(spawnable_units))
    # spawning_units.fill(0)

    stats.connect("death", _on_death)

    select_box.connect("select_click", _on_select_click)

    radius_color = faction.color
    radius_color.a = 0.2

    # controller.next_round_signal.connect(_on_next_round_signal)

# func spawn_units():
#     for i in range(len(spawning_units)):
#         var unit_number = spawning_units[i]
#         if unit_number < 1:
#             continue
#         for u in range(unit_number):
#             spawn_unit(spawnable_units[i], unit_number, u)

# func spawn_unit(unit: PackedScene, total: int, index: int) -> void:
#     var inst := unit.instantiate()
#     var tdir = 2 * PI * index / total
#     inst.rotation = tdir
#     inst.faction = faction
#     inst.set_as_top_level(true)
#     inst.global_position = global_position + Vector2.from_angle(tdir) * total
#     spawn_node.add_child(inst)

# func _on_next_round_signal():
#     spawn_units()

# func add_spawning_unit(index: int):
#     if index >= len(spawning_units):
#         return
#     spawning_units[index] += 1

func create_spawn_area(index: int):
    var spawn_area = spawn_areas[index]
    var inst := spawn_area.instantiate()
    var tdir = 0
    inst.rotation = tdir
    inst.faction = faction
    inst.set_as_top_level(true)
    inst.global_position = global_position
    inst.building = self
    spawn_node.add_child(inst)

    controller.set_selected(inst, false, true)

func add_spawning_area(index: int):
    if index >= len(build_actions):
        return
    var action := build_actions[index]
    if not action.attempt(controller, faction):
        return
    # Successfully paid
    create_spawn_area(index)

func _on_select_click():
    controller.set_selected(self, true, false)
    var selected = controller.selected == self
    select_box.set_selected(selected)

func deselect():
    select_box.set_selected(false)

func _on_selected_input(event):
# func _input(event):
    if event.is_action_pressed("spawn_unit_0"):
        add_spawning_area(0)
    if event.is_action_pressed("spawn_unit_1"):
        add_spawning_area(1)
    if event.is_action_pressed("spawn_unit_2"):
        add_spawning_area(2)
    if event.is_action_pressed("spawn_unit_3"):
        add_spawning_area(3)
    if event.is_action_pressed("spawn_unit_4"):
        add_spawning_area(4)
    if event.is_action_pressed("spawn_unit_5"):
        add_spawning_area(5)

# func _process(delta):


func _on_death() -> void:
    queue_free()

func _draw():
    var center = Vector2.ZERO
    var radius = spawn_radius
    var angle_from = 0
    var angle_to = 360
    var color = radius_color
    draw_arc(center, radius, angle_from, angle_to, 64, color)
