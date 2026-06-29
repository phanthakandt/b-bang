class_name Player
extends CharacterBody2D

@export var move_speed: float = 200.0
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 1.5
@export var invincible_duration: float = 0.2
@export var max_hp: int = 100

var current_hp: int = 0
var is_dashing: bool = false
var can_dash: bool = true
var is_invincible: bool = false
var current_weapon: WeaponData = null
var facing_angle: float = 0.0

var _dash_direction: Vector2 = Vector2.RIGHT
var _dash_timer: float = 0.0
var _invincible_timer: float = 0.0
var _cooldown_timer: float = 0.0

@onready var body_rect: ColorRect = $ColorRect
@onready var gun_pivot: Marker2D = $GunPivot
@onready var facing_line: Line2D = $FacingLine
@onready var hurtbox: Area2D = $HurtBox
@onready var reload_bar: Node2D = $ReloadBar
@onready var reload_fill: ColorRect = $ReloadBar/Fill
# Untyped so GDScript duck-types weapon_holder methods without a class_name.
@onready var _wh = $GunPivot

const _BAR_W         := 32.0
const _CLR_COOLDOWN  := Color(1.0, 0.35, 0.10, 1.0)  # orange — waiting to reload
const _CLR_RELOADING := Color(0.95, 0.85, 0.15, 1.0)  # yellow — actively reloading

func _ready() -> void:
	add_to_group("player")
	current_hp = max_hp
	EventBus.hp_changed.emit(current_hp, max_hp)

func _physics_process(delta: float) -> void:
	_tick_timers(delta)

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	velocity = _dash_direction * dash_speed if is_dashing else input_dir * move_speed
	move_and_slide()

	_update_aim()
	_update_reload_bar()

	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		_begin_dash(input_dir)

func _tick_timers(delta: float) -> void:
	if is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			is_dashing = false
			body_rect.modulate.a = 1.0

	if is_invincible:
		_invincible_timer -= delta
		if _invincible_timer <= 0.0:
			is_invincible = false

	if not can_dash:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0:
			can_dash = true

func _update_reload_bar() -> void:
	if not _wh.is_busy():
		reload_bar.visible = false
		return
	reload_bar.visible = true
	reload_fill.size.x = _BAR_W * _wh.get_reload_progress()
	reload_fill.color   = _CLR_COOLDOWN if _wh.is_in_cooldown() else _CLR_RELOADING

func _update_aim() -> void:
	var aim_dir := (get_global_mouse_position() - global_position).normalized()
	facing_angle = aim_dir.angle()
	gun_pivot.rotation = facing_angle
	# Point 0 stays at origin; point 1 tracks mouse direction in local space.
	facing_line.set_point_position(1, aim_dir * 30.0)

func _begin_dash(input_dir: Vector2) -> void:
	_dash_direction = input_dir.normalized() if input_dir != Vector2.ZERO else Vector2.from_angle(facing_angle)
	is_dashing = true
	is_invincible = true
	can_dash = false
	_dash_timer = dash_duration
	_invincible_timer = invincible_duration
	_cooldown_timer = dash_cooldown
	body_rect.modulate.a = 0.4

func take_damage(amount: int) -> void:
	if is_invincible:
		return
	current_hp = maxi(current_hp - amount, 0)
	EventBus.hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		die()

func heal(amount: int) -> void:
	current_hp = mini(current_hp + amount, max_hp)
	EventBus.hp_changed.emit(current_hp, max_hp)

func die() -> void:
	EventBus.player_died.emit()
	queue_free()
