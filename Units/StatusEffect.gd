class_name StatusEffect
extends Resource

enum ModifierType {
    Add = 0,
    Multiply = 1
}

@export var attribute : String
@export var modifier : ModifierType
@export var value : float
@export var constant: bool
