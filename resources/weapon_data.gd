class_name WeaponData
extends Resource

@export var weapon_name: String = ""
@export_enum("auto", "burst", "semi", "shotgun", "special") var weapon_type: String = "auto"
@export var damage: float = 10.0
@export var fire_rate: float = 5.0        # shots per second
@export var mag_size: int = 30
@export var reload_time: float = 2.0      # seconds for full reload animation
@export var cooldown_time: float = 0.5    # delay after last shot before reload begins
@export var accuracy: float = 0.9         # spread = (1 - accuracy) * 15 degrees
@export var bullet_speed: float = 800.0
@export var bullet_count: int = 1         # >1 for shotgun pellets
@export var is_auto: bool = true          # true = hold to fire, false = click per shot

@export_group("Skill")
@export var skill_name: String = ""
@export var skill_description: String = ""
@export var skill_cooldown: float = 10.0

@export_group("Synergy")
@export_enum("aggro", "precision", "control", "dot") var synergy_path: String = "aggro"
