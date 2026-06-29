class_name CardData
extends Resource

@export var card_id: String = ""
@export var card_name: String = ""
@export var description: String = ""
@export_enum("common", "rare", "epic", "legendary", "curse") var rarity: String = "common"
@export var is_curse: bool = false

@export_group("Effect")
@export_enum("stat_modifier", "weapon_mod", "passive", "active") var effect_type: String = "stat_modifier"
## Flexible bag of params interpreted by the effect system (e.g. {"stat": "damage", "value": 0.1}).
@export var effect_params: Dictionary = {}

@export_group("Synergy")
@export var synergy_tags: Array[String] = []
