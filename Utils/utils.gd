extends Node

static func dlerp(a, b, rate, delta):
    return lerp(a, b, 1 - pow(rate, delta))

static func dlerps(a, b, rate, delta, seconds):
    return lerp(a, b, 1 - pow(rate, delta / seconds))

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

static func approach_angle(a, b, rate) -> float:
    var diff = angle_difference(a, b)
    var dsign = sign(diff)
    var result = a + dsign * rate
    return result