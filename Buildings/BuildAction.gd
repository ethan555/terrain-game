class_name BuildAction
extends Resource

@export var cost := 0
@export var icon : Texture2D

@export var spawn_area : PackedScene

func check(controller: Controller, faction: Faction):
    pass

func attempt(controller: Controller, faction: Faction):
    return controller.attempt_cost(cost, faction)
