extends Node2D

enum State {
    Play,
    Building,
    Pause,
    Destroying
}

@export var factions : Array[Faction] = []

@onready var timer := $Timer

var current_state = State.Play

var energy := 3

func _ready():
    pass

func _process(delta):
    match (current_state):
        State.Play:
            play(delta)
        State.Building:
            build(delta)
        State.Destroying:
            pass

func play(delta):
    pass

func build(delta):
    pass
