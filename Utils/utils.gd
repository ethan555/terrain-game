extends Node

static func dlerp(a, b, rate, delta):
    return lerp(a, b, 1 - pow(rate, delta))

static func dlerps(a, b, rate, delta, seconds):
    return lerp(a, b, 1 - pow(rate, delta / seconds))
