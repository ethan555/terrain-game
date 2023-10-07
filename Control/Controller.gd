class_name Controller
extends Node2D

enum State {
    Play = 0,
    Building = 1,
    Pause = 2,
    Destroying = 3
}

@export var factions : Array[Faction] = []
@export var round_timeouts := {
    State.Play: 10.0,
    State.Building: 60.0,
    State.Pause: -1.0,
    State.Destroying: -1.0
}

@onready var ui : UI = get_node("/root/Level/UI")
@onready var timer : Timer = $Timer

var current_state = State.Building

# var energy := 3
@export var starting_faction_resources : Array[FactionResources]
var player_faction : String
var faction_resources : Dictionary = {}

var selected_stack : Array[Node2D] = []
var selected : Node2D
var round_counter := 0
signal next_round_signal
signal terrain_click

func init_faction_resources():
    # Player will be the first faction
    player_faction = starting_faction_resources[0].faction.faction_name
    for sfr in starting_faction_resources:
        faction_resources[sfr.faction.faction_name] = sfr
    ui.init_player_faction(faction_resources[player_faction])

func _ready():
    timer.connect("timeout", round_timeout)
    timer.start(round_timeouts[current_state])

    init_faction_resources()

func round_timeout():
    match (current_state):
        State.Play:
            # Switch to Building
            current_state = State.Building
        State.Building:
            # Switch to Play
            current_state = State.Play
            var spawning_round : bool = round_counter % 3 == 0
            next_round_signal.emit(round_counter, spawning_round)
            ui.update_round_label(round_counter + 1)
            # ui.get_node("RoundLabel").text = "Round " + str(round_counter + 1)
            round_counter += 1
    timer.start(round_timeouts[current_state])


## Set the given unit or building as selected by the controller
## `node`: The unit to be selected
## `reset_on_same`: If the selected unit is the same as what is already selected, reset selected to null
## `save_previous`: Push the previously selected unit onto the selection stack
func set_selected(node: Node2D, reset_on_same: bool, save_previous: bool):
    if reset_on_same and selected == node:
        # Reset selected
        reset_selected()
        return
    if is_instance_valid(selected):
        selected.deselect()
        if save_previous:
            selected_stack.push_back(selected)
    selected = node

func reset_selected():
    print("RESETTING SELECTED")
    if len(selected_stack) > 0:
        if is_instance_valid(selected):
            selected.deselect()
        var new_selected = selected_stack.pop_back()
        new_selected._on_select_click()
    else:
        if is_instance_valid(selected):
            selected.deselect()
        selected = null

func check_selected():
    return selected != null and is_instance_valid(selected)

func is_selected(node : Node2D):
    return selected == node

func on_click(event):
    # !!!!!!!!!!!!!!!!!!!!!! GODOT SUCKS !!!!!!!!!!!!!!!!!!!!!!!!!!
    var query_params := PhysicsPointQueryParameters2D.new()
    query_params.position = get_global_mouse_position()
    query_params.collide_with_areas = true
    query_params.collide_with_bodies = false
    query_params.collision_mask = 0x7FFFFFFF

    var results = get_world_2d().direct_space_state.intersect_point(query_params, 32) # The last 'true' enables Area2D intersections, previous four values are all defaults

    var clicked_selectbox = false
    for result in results:
        var c = result["collider"]
        if c is SelectBox:
            c.on_select_click(event)
            clicked_selectbox = true
            break
    if not clicked_selectbox:
        if is_instance_valid(selected):
            selected._on_select_click()
        else:
            reset_selected()

func on_right_click(_event):
    if is_instance_valid(selected):
        reset_selected()
    else:
        terrain_click.emit()

## Attempt to pay the cost of an action from the `faction`.
## If successful, the `cost` is paid and return `true`
## If unsuccessful, the `cost` is not paid, and return `false`
func attempt_cost(cost, faction: Faction) -> bool:
    if faction.faction_name not in faction_resources:
        push_error("Invalid faction: " + faction.faction_name)
        return false
    # If faction can afford, pay the cost
    var faction_resource : FactionResources = faction_resources[faction.faction_name]
    if faction_resource.energy >= cost:
        faction_resource.energy -= cost
        # faction_resources[faction.faction_name] -= cost
        if faction.faction_name == player_faction:
            ui.update_player_faction(faction_resource)
            # ui.update_player_faction(faction_resources[faction.faction_name])
        return true
    return false

func _input(event):
    if event.is_action_pressed("end_turn"):
        if current_state == State.Building:
            timer.start(0.1)
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT \
            and event.is_pressed():

            on_click(event)
        if event.button_index == MOUSE_BUTTON_RIGHT \
            and event.is_pressed():

            on_right_click(event)

    if is_instance_valid(selected):
        selected._on_selected_input(event)

func _process(delta):
    match (current_state):
        State.Play:
            play(delta)
        State.Building:
            build(delta)
        State.Destroying:
            pass
    # ui.get_node("ControlTimer").text = str(ceil(timer.time_left))
    ui.update_control_timer(ceil(timer.time_left))

func play(delta):
    pass

func build(delta):
    pass
