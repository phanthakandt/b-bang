class_name PerkData
extends Resource

@export var perk_id: String = ""
@export var perk_name: String = ""
@export var description: String = ""
@export_enum("combat", "survival", "fortune") var perk_tree: String = "combat"
@export var cost: int = 1
## perk_ids that must be unlocked before this perk becomes available.
@export var prerequisites: Array[String] = []

@export_group("Effect")
@export var effect_type: String = ""
@export var effect_params: Dictionary = {}
