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

@onready var ui := get_node("/root/Level/UI")
@onready var timer : Timer = $Timer

var current_state = State.Building

var energy := 3

var selected : Node2D
signal next_round_signal

func _ready():
    timer.connect("timeout", round_timeout)
    timer.start(round_timeouts[current_state])

func round_timeout():
    match (current_state):
        State.Play:
            # Switch to Building
            current_state = State.Building
        State.Building:
            # Switch to Play
            current_state = State.Play
            next_round_signal.emit()
    timer.start(round_timeouts[current_state])

func _input(event):
    if event.is_action_pressed("end_turn"):
        if current_state == State.Building:
            timer.start(0.1)

func _process(delta):
    match (current_state):
        State.Play:
            play(delta)
        State.Building:
            build(delta)
        State.Destroying:
            pass
    ui.get_node("ControlTimer").text = str(ceil(timer.time_left))

func play(delta):
    pass

func build(delta):
    pass
