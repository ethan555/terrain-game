class_name UI
extends CanvasLayer

@onready var control_timer : Label = $ControlTimer
@onready var round_label : Label = $RoundLabel

@onready var player_faction_name : Label = $PlayerFactionName
@onready var player_faction_resources : Label = $PlayerFactionResources

func init_player_faction(resources: FactionResources):
    player_faction_name.text = resources.faction.faction_name
    player_faction_name.label_settings.font_color = resources.faction.color

    player_faction_resources.text = str(resources.energy)
    player_faction_resources.label_settings.font_color = resources.faction.color

func update_control_timer(control_time: float):
    control_timer.text = str(control_time)

func update_round_label(round_counter: int):
    round_label.text = "Round " + str(round_counter)

func update_player_faction(resources: FactionResources):
    player_faction_name.text = resources.faction.faction_name

    player_faction_resources.text = str(resources.energy)
