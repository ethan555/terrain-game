var array := []
var length: int
var width: int
var bounds: Vector2

func _init(scale: Vector2i):
    array.resize(scale.x * scale.y)
    length = scale.x
    width = scale.y
    bounds = Vector2(length - 1, width - 1)

func get_cell(position: Vector2i):
    var bounded_pos := position.clamp(Vector2.ZERO, bounds)
    var index := bounded_pos.y * length + bounded_pos.x
    return array[index]

func set_cell(position: Vector2i, value):
    array[position.y * length + position.x] = value
