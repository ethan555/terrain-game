extends Area2D

@export var faction : Faction
@export var attack : Attack
@export var lifespan := 0.0
@onready var timer := $Timer

@onready var collision_shape := $CollisionShape2D

func _ready():
    print("Explosion Ready: " + str(attack.radius) + " " + str(lifespan))
    collision_shape.shape.radius = attack.radius

    if lifespan > 0:
        timer.connect("timeout", queue_free)
        timer.start(lifespan)

func damage_area(delta):
    var areas := get_overlapping_areas_godot_sucks()
    print("Hitting Targets: " + str(len(areas)))
    var damaged = 0
    for area in areas:
        if not area is Hurtbox:
            continue
        var unit = area.get_parent()
        var target_faction : Faction = unit.faction
        if faction.check_ally(target_faction.faction_name):
            continue
        damaged += 1
        if lifespan == 0:
            unit.stats.damage(attack)
        else:
            unit.stats.damage(attack, delta)
    print("Damaged " + str(damaged))

func get_overlapping_areas_godot_sucks() -> Array[Area2D]:
    var space := get_world_2d().direct_space_state
    var query := PhysicsShapeQueryParameters2D.new()
    query.collide_with_areas = true
    query.collide_with_bodies = false
    query.set_shape(collision_shape.shape)
    query.transform = collision_shape.global_transform
    var result := space.intersect_shape(query)
    var areas : Array[Area2D] = []
    for area_collision in result:
        var area := area_collision.collider as Area2D
        if is_instance_valid(area): #perhaps some other checks here
            areas.append(area)
    return areas


func _process(_delta):
    print("Processing Explosion " + str(global_position))
    # damage_area(delta)
    if lifespan == 0:
        queue_free()

func _physics_process(delta):
    damage_area(delta)
