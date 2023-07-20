class_name Faction
extends Resource

@export var id : int = 0
@export var faction_name : String = "DIS"
@export var color : Color = Color(1.0, 1.0, 1.0)
@export var allies : Array[String]

func _init(_id: int = -1, _faction_name: String = "Unknown", _color: Color = Color(1, 1, 1), _allies: Array[String] = []):
    id = _id
    faction_name = _faction_name
    color = _color
    allies = _allies

func check_ally(name: String) -> bool:
    if name == faction_name:
        return true
    return name in allies

func check_enemy(name: String) -> bool:
    if name == faction_name:
        return false
    return name not in allies
