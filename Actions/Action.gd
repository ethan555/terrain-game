class_name Action
extends Resource

@export var icon : Image
@export var name := ""
@export_multiline var description := ""

@export_category("Stats")
@export var cost := 0
@export var recharge_time := 1.0
@export var recharge_on_round := 0.0
@export var action_effects : Array[ActionEffect]
