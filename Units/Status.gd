class_name Status
extends Resource

enum UpdateType {
    Add = 0,
    Refresh = 1,
    AddAndRefresh = 2,
    Replace = 3
}

@export var name : String
@export var icon : Texture2D
@export_multiline var description : String
@export var lifespan : float
@export var update_type : UpdateType

@export var effects : Array[StatusEffect]
## `Status` names which are removed on adding this status
@export var negated_effects : Array[String]
## `Status` names which prevent adding this status
@export var negating_effects : Array[String]
