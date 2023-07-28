class_name Building
extends Node2D

@onready var stats : Stats = $Stats
@onready var controller := get_node("/root/Level/Controller")

@export var faction : Faction
@export var actions : Array[Action]
@export var passive_actions : Array[Action]

@export var spawnable_units : Array[PackedScene]

var spawning_units : Array

func _ready():
    spawning_units.resize(len(spawnable_units))
    spawning_units.fill(0)

    stats.connect("death", _on_death)

    controller.next_round_signal.connect(_on_next_round_signal)

func spawn_units():
    for i in range(len(spawning_units)):
        var unit_number = spawning_units[i]
        if unit_number < 1:
            continue
        for u in range(unit_number):
            spawn_unit(spawnable_units[i], unit_number, u)

func spawn_unit(unit: PackedScene, total: int, index: int) -> void:
    var inst := unit.instantiate()
    var tdir = 2 * PI * index / total
    inst.rotation = tdir
    inst.faction = faction
    inst.set_as_top_level(true)
    inst.global_position = global_position + Vector2.from_angle(tdir)
    add_child(inst)

func _on_next_round_signal():
    spawn_units()

func add_spawning_unit(index: int):
    if index >= len(spawning_units):
        return
    spawning_units[index] += 1

func _input(event):
    if event.is_action_pressed("spawn_unit_0"):
        add_spawning_unit(0)
    if event.is_action_pressed("spawn_unit_1"):
        add_spawning_unit(1)
    if event.is_action_pressed("spawn_unit_2"):
        add_spawning_unit(2)
    if event.is_action_pressed("spawn_unit_3"):
        add_spawning_unit(3)

# func _process(delta):


func _on_death() -> void:
    queue_free()
