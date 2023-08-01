extends Area2D
const Utils = preload("res://Utils/utils.gd")

@export var faction : Faction
@export var attack : Attack
@export var lifespan := 0.0
@onready var timer := $Timer

@onready var collision_shape := $CollisionShape2D

func _ready():
    collision_shape.shape.radius = attack.radius

    if lifespan > 0:
        timer.connect("timeout", queue_free)
        timer.start(lifespan)

func damage_area(delta):
    var areas := Utils.get_overlapping_areas_godot_sucks(self, collision_shape)
    for area in areas:
        if not area is Hurtbox:
            continue
        var unit = area.get_parent()
        var target_faction : Faction = unit.faction
        if faction.check_ally(target_faction.faction_name):
            continue
        if lifespan == 0:
            unit.stats.damage(attack)
        else:
            unit.stats.damage(attack, delta)

# func get_overlapping_areas_godot_sucks() -> Array[Area2D]:
#     var space := get_world_2d().direct_space_state
#     var query := PhysicsShapeQueryParameters2D.new()
#     query.collide_with_areas = true
#     query.collide_with_bodies = false
#     query.set_shape(collision_shape.shape)
#     query.transform = collision_shape.global_transform
#     var result := space.intersect_shape(query)
#     var areas : Array[Area2D] = []
#     for area_collision in result:
#         var area := area_collision.collider as Area2D
#         if is_instance_valid(area): #perhaps some other checks here
#             areas.append(area)
#     return areas


func _process(_delta):
    # damage_area(delta)
    if lifespan == 0:
        queue_free()

func _physics_process(delta):
    damage_area(delta)
