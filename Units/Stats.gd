class_name Stats
extends Node

@onready var controller := get_node("/root/Level/Controller")

@export var _HEALTH := 10.0
@export var _ARMOR := 0.0
@export var _SPEED : float = 100

var statuses : Dictionary
var status_effects : Dictionary

signal death

var max_health : float
var health : float
var armor : float
var speed : float
var attack_multiplier := 1.0

class ActiveStatus:
    var name : String
    var effects : Array[StatusEffect]
    var icon : Texture2D
    var description : String
    var number : int
    var timer : float

    func _init(_name, _effects, _icon, _description, _lifespan):
        name = _name
        effects = _effects
        icon = _icon
        description = _description
        timer = _lifespan
        number = 1

    func update(_delta) -> bool:
        if timer == -1:
            return false
        timer -= _delta
        if timer <= 0:
            return true
        return false

func _ready():
    health = _HEALTH
    armor = _ARMOR
    speed = _SPEED

func damage(attack : Attack, delta := 1.0):
    health -= attack.get_damage(armor) * delta

    if health <= 0:
        death.emit()

func heal(attack : Attack, delta := 1.0):
    health = min(max_health, attack.get_damage(0) * delta)

func recalculate_attribute(attribute_name):
    var attribute_value = self.get(attribute_name)
    if attribute_value == null:
        return
    var effects = status_effects[attribute_name]

    var addition = 0.0
    var multiplication = 1.0
    for status_name in effects:
        var status : ActiveStatus = statuses[status_name]
        for status_effect in status.effects:
            if attribute_name != status_effect.attribute or status_effect.constant:
                continue
            match(status_effect):
                StatusEffect.ModifierType.Add:
                    addition += status_effect.value
                StatusEffect.ModifierType.Multiply:
                    multiplication *= status_effect.value
    attribute_value *= multiplication
    attribute_value += addition

    self.set(attribute_name, attribute_value)

func add_status(status: Status):
    var current_status = statuses.get(status.name)
    if not current_status == null and status.update_type != Status.UpdateType.Replace:
        # Update status
        match(status.update_type):
            Status.UpdateType.Add:
                statuses[status.name].timer += status.lifespan
                statuses[status.name].number += 1
            Status.UpdateType.Refresh:
                statuses[status.name].timer = status.lifespan

            # UpdateType.AddAndRefresh:
    else:
        statuses[status.name] = ActiveStatus.new(
            status.name, status.effects, status.icon,
            status.description, status.lifespan
        )

    for status_effect in status.effects:
        # Update status effects
        if not status_effect.attribute in status_effects:
            status_effects[status_effect.attribute] = {status.name: 1}
        else:
            match(status.update_type):
                Status.UpdateType.Add:
                    status_effects[status_effect.attribute][status.name] += 1

        recalculate_attribute(status_effect.attribute)

func _process(delta):
    if controller.current_state != controller.State.Play:
        return

    for status_name in statuses:
        var status : ActiveStatus = statuses[status_name]
        var remove := status.update(delta)
        if remove:
            remove_status(status.name)

func remove_status(status_name: String) -> bool:
    if not status_name in statuses:
        return false
    var status = statuses[status_name]
    statuses.erase(status_name)

    for status_effect in status.effects:
        var affected_attribute = status_effect.attribute
        status_effects[affected_attribute][status_name] -= 1
        if status_effects[affected_attribute][status_name] <= 0:
            status_effects[affected_attribute].erase(status_name)

    return true
