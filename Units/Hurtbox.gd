class_name Hurtbox
extends Area2D

@onready var collision_shape := $CollisionShape2D

signal aura_entered

func _ready():
    area_entered.connect(_on_area_entered)

func handle_aura(aura: Aura):
    aura_entered.emit(aura)

func _on_area_entered(area: Area2D):
    if area is Aura:
        handle_aura(area)
    pass

func set_disabled(is_disabled: bool):
    collision_shape.set_deferred("disabled", is_disabled)
