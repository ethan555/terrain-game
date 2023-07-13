var array = []
var length: int
var width: int

func _init(scale: Vector2i):
    array.resize(scale.x * scale.y)
    length = scale.x
    width = scale.y

func get_cell(position: Vector2i):
    return array[position.y * length + position.x]

func set_cell(position: Vector2i, value):
    array[position.y * length + position.x] = value
