class_name ActionEffect
extends Resource

enum EffectType {
    DamageTargets,
    AddStatus,
    Spawn,
    AddTech
}

@export var effect_type : EffectType
