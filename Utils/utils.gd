extends Node2D

static func dlerp(a, b, rate, delta):
    return lerp(a, b, 1 - pow(rate, delta))

static func dlerps(a, b, rate, delta, seconds):
    return lerp(a, b, 1 - pow(rate, delta / seconds))

static func modulo(a, b):
    return (a % b + b) % b

static func approach(a, b, rate) -> float:
    if a == b:
        return b
    if abs(b - a) < rate:
        return b
    var dsign = sign(b - a)
    var result = a + rate * dsign
    var dsign_result = sign(result)
    if dsign != dsign_result:
        return b
    return result

static func approach_vector(a: Vector2, b: Vector2, rate: float) -> Vector2:
    var diff := b - a
    if diff.length() <= rate:
        return b
    var norm := diff.normalized()
    var result := a + norm * rate
    return result

static func angle_difference(a, b) -> float:
    var MAX_ANGLE = PI * 2
    var diff = fmod(b - a, MAX_ANGLE)
    return (fmod(2 * diff, MAX_ANGLE) - diff)

static func angle_distance(a, b) -> float:
    return abs(angle_difference(a, b))

static func approach_angle(a, b, rate) -> float:
    var diff = angle_difference(a, b)
    var adiff = abs(diff)
    if adiff < rate:
        return b
    var dsign = sign(diff)
    var result = a + dsign * rate
    return result

static func get_overlapping_areas_godot_sucks(node: Node2D, collision_shape: CollisionShape2D) -> Array[Area2D]:
    var space := node.get_world_2d().direct_space_state
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