class_name SelectBox
extends Area2D

signal select_click

@onready var collision_shape : CollisionShape2D = $CollisionShape2D
@onready var color_rect : ColorRect = $ColorRect

@export var selected_color : Color = Color(1, 1, 1, .2)

var selected = false


func _ready():
    var shape = collision_shape.shape
    var size = shape.get_size()
    color_rect.set_size(size)
    color_rect.color = selected_color
    color_rect.visible = selected

func on_select_click(_event):
    select_click.emit()

func set_selected(is_selected: bool):
    selected = is_selected
    print("Selected " + str(selected))
    color_rect.visible = selected

# # func on_click(event: InputEventMouseButton):
# #     if event.button_index == MOUSE_BUTTON_LEFT:
# #         on_select_click(event)

# func _input_event(_viewport, event, _shape_idx):
#     if event is InputEventMouseButton \
#         and event.button_index == MOUSE_BUTTON_LEFT \
#         and event.is_pressed():

#         on_select_click(event)
#         # get_tree().get_root().set_input_as_handled()
