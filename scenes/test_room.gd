extends Node2D

@onready var hp_label:        Label = $HUD_placeholder/HPLabel
@onready var ammo_label:      Label = $HUD_placeholder/AmmoLabel
@onready var state_label:     Label = $HUD_placeholder/StateLabel
@onready var weapon_label:    Label = $HUD_placeholder/WeaponLabel
@onready var room_state_label: Label = $HUD_placeholder/RoomStateLabel
@onready var player:          Player = $Player
@onready var room_base:       RoomBase = $RoomBase

var _wh: Node = null  # weapon_holder on GunPivot

func _ready() -> void:
	EventBus.hp_changed.connect(_on_hp_changed)
	EventBus.weapon_mag_empty.connect(func(): state_label.text = "COOLDOWN")
	EventBus.weapon_reload_complete.connect(func(): state_label.text = "READY")
	EventBus.room_cleared.connect(_on_room_cleared)
	EventBus.player_died.connect(_on_player_died)

	_wh = $Player/GunPivot
	var weapon: WeaponData = load("res://resources/weapons/echo_smg.tres")
	_wh.load_weapon(weapon)
	weapon_label.text = weapon.weapon_name

	RoomLoader.room_scenes = [preload("res://scenes/rooms/room_base.tscn")]
	RoomLoader.default_enemy_scenes = [preload("res://scenes/enemies/runner.tscn"), preload("res://scenes/enemies/gunner.tscn")]
	RoomLoader.default_wave_count = 2
	RoomLoader.default_enemies_per_wave = 3
	RoomLoader.current_room = room_base
	room_base.start_room()

func _process(_delta: float) -> void:
	if _wh == null or not is_instance_valid(player) or _wh.weapon_data == null:
		return
	ammo_label.text  = "%d / %d" % [_wh.current_ammo, _wh.weapon_data.mag_size]
	state_label.text = _wh.get_state_string()

func _on_hp_changed(current: int, maximum: int) -> void:
	hp_label.text = "HP: %d / %d" % [current, maximum]

func _on_room_cleared() -> void:
	room_state_label.text = "ROOM CLEARED — walk through door"

func _on_player_died() -> void:
	room_state_label.text = "YOU DIED"
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
