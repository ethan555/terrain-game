class_name ActionEffect
extends Resource

enum EffectType {
    DamageTargets = 0,
    AddStatus = 1,
    Spawn = 2,
    AddTech = 3
}

@export var effect_type : EffectType
