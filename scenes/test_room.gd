extends Node2D

const ROOM_W := 800.0
const ROOM_H := 600.0
const WALL_T := 32.0
const WALL_COLOR  := Color(0.227, 0.227, 0.416)  # #3a3a6a
const FLOOR_COLOR := Color(0.176, 0.290, 0.133)  # #2d4a22

@onready var hp_label:     Label = $HUD_placeholder/HPLabel
@onready var ammo_label:   Label = $HUD_placeholder/AmmoLabel
@onready var state_label:  Label = $HUD_placeholder/StateLabel
@onready var weapon_label: Label = $HUD_placeholder/WeaponLabel
@onready var player: Player = $Player

var _wh: Node = null  # weapon_holder on GunPivot

func _ready() -> void:
	_build_room()

	EventBus.hp_changed.connect(_on_hp_changed)
	EventBus.weapon_mag_empty.connect(func(): state_label.text = "COOLDOWN")
	EventBus.weapon_reload_complete.connect(func(): state_label.text = "READY")

	_wh = $Player/GunPivot
	var weapon: WeaponData = load("res://resources/weapons/echo_smg.tres")
	_wh.load_weapon(weapon)
	weapon_label.text = weapon.weapon_name

func _process(_delta: float) -> void:
	if _wh == null or not is_instance_valid(player) or _wh.weapon_data == null:
		return
	ammo_label.text  = "%d / %d" % [_wh.current_ammo, _wh.weapon_data.mag_size]
	state_label.text = _wh.get_state_string()

# ---------------------------------------------------------------------------
# Room builder — creates floor + 4 walls as StaticBody2D at runtime
# ---------------------------------------------------------------------------

func _build_room() -> void:
	var floor_rect := ColorRect.new()
	floor_rect.color = FLOOR_COLOR
	floor_rect.size  = Vector2(ROOM_W, ROOM_H)
	floor_rect.z_index = -1
	add_child(floor_rect)

	_make_wall(Vector2(0,       -WALL_T),  Vector2(ROOM_W, WALL_T))             # top
	_make_wall(Vector2(0,        ROOM_H),  Vector2(ROOM_W, WALL_T))             # bottom
	_make_wall(Vector2(-WALL_T, -WALL_T),  Vector2(WALL_T, ROOM_H + WALL_T * 2.0))  # left
	_make_wall(Vector2(ROOM_W,  -WALL_T),  Vector2(WALL_T, ROOM_H + WALL_T * 2.0))  # right

func _make_wall(pos: Vector2, sz: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	add_child(body)

	var rect := RectangleShape2D.new()
	rect.size = sz
	var col := CollisionShape2D.new()
	col.shape    = rect
	col.position = sz * 0.5   # CollisionShape2D origin is its center
	body.add_child(col)

	var vis := ColorRect.new()
	vis.color = WALL_COLOR
	vis.size  = sz
	body.add_child(vis)

# ---------------------------------------------------------------------------

func _on_hp_changed(current: int, maximum: int) -> void:
	hp_label.text = "HP: %d / %d" % [current, maximum]
