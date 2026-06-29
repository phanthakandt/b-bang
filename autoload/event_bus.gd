extends Node

## Global signal hub — emit here, listen anywhere. No direct node references needed.

signal player_died
signal player_leveled_up(new_level: int)
signal room_cleared
signal run_started(run_index: int)
signal run_ended(won: bool)
signal card_selected(card_id: String)
signal weapon_mag_empty
signal weapon_reload_complete
signal enemy_died(enemy: Node)
signal gold_changed(amount: int)
signal hp_changed(current: int, maximum: int)
