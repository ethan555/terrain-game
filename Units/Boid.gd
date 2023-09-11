class_name Boid
extends Area2D

@onready var collision_shape : CollisionShape2D = $CollisionShape2D

@export var radius : float = 10

@export var MAX_BOIDS : int = 10

var boids : Dictionary = {}
var calculated : Dictionary = {}
var parent : Node2D

func _ready():
    collision_shape.shape.radius = radius
    area_entered.connect(_on_area_entered)
    area_exited.connect(_on_area_exited)

    parent = get_parent()

func check_boid(key) -> bool:
    if not is_instance_valid(boids[key]):
        boids.erase(key)
        return false
    return true

## Returns Avoidance: Array[avoidance direction: Vector2, avoidance amount: float]
func calculate_avoidance(u : Unit) -> Array:
    var adist : Vector2 = u.global_position - parent.global_position
    var alen := adist.length()
    # if alen > radius:
    #     continue

    # var inside = false

    var adir : Vector2
    var avoid_amount : float = max((radius - alen) / radius, 0)
    if alen == 0:
        var _r := randf_range(0, 2 * PI)
        adir = Vector2.from_angle(_r)
        # inside = true
        # print("INSIDE THE HOUSE " + str(adir))
        avoid_amount = 10
        # inside_the_house = true
    else:
        adir = -adist.normalized()

    var avoidance := adir * avoid_amount
    # if inside:
        # print("Avoid amount " + str(avoid_amount) + " Adir " + str(adir))

    return [avoidance, avoid_amount]

func get_boid_direction(moving: bool) -> Vector2:
    var bv := Vector2.ZERO

    var counter : int = 0
    # var inside_the_house := false
    for key in boids.keys():
        if counter >= MAX_BOIDS:
            break
        if not check_boid(key):
            continue

        var u : Unit = boids[key]
        var avoidance : Array
        if key in calculated:
            avoidance = calculated[key]
            # print(parent.name + " CALCULATED " + u.name + " " + str(avoidance[0]))
        else: 
            avoidance = calculate_avoidance(u)
            u.boid.calculated[parent.name] = [-avoidance[0], avoidance[1]]
            # print(parent.name + " DONE " + u.name + " " + str(avoidance[0]))
        bv += avoidance[0]

        # Only care about other velocity if we are moving
        if !moving:
            continue
        var v := u.velocity
        var vdir := v.normalized()

        bv += vdir * avoidance[1]

        counter += 1

    bv = bv.normalized()
    # if inside_the_house:
    #     print("BV: " + str(bv))

    calculated.clear()

    return bv

func _on_area_entered(area: Area2D) -> void: #hurtbox: Hurtbox) -> void:
    if not area is Hurtbox:
        return
    var unit := area.get_parent()
    if unit == parent:
        return
    if not unit is Unit:
        return
    # print(name + " New boid " + unit.name)
    boids[unit.name] = unit

func _on_area_exited(area: Area2D) -> void: #hurtbox: Hurtbox) -> void:
    if not area is Hurtbox:
        return
    var unit := area.get_parent()
    if unit == parent:
        return
    if not unit is Unit:
        return
    # print(name + " Lost boid " + unit.name)
    boids.erase(unit)

