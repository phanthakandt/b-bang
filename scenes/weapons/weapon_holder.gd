extends Marker2D

enum WeaponState { IDLE, FIRING, COOLDOWN, RELOADING }

var state: WeaponState = WeaponState.IDLE
var current_ammo: int = 0
var weapon_data: WeaponData = null

var _fire_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _reload_timer: float = 0.0

@onready var muzzle_point: Marker2D = $MuzzlePoint

const BULLET_SCENE = preload("res://scenes/weapons/bullet.tscn")

func _process(delta: float) -> void:
	if weapon_data == null:
		return

	if _fire_timer > 0.0:
		_fire_timer -= delta

	match state:
		WeaponState.IDLE:
			if weapon_data.is_auto and Input.is_action_pressed("shoot") and _fire_timer <= 0.0:
				try_fire()
		WeaponState.COOLDOWN:
			_cooldown_timer -= delta
			if _cooldown_timer <= 0.0:
				_begin_reload()
		WeaponState.RELOADING:
			_reload_timer -= delta
			if _reload_timer <= 0.0:
				_finish_reload()

	# Semi-auto: one bullet per click, not per hold
	if not weapon_data.is_auto and state == WeaponState.IDLE and _fire_timer <= 0.0:
		if Input.is_action_just_pressed("shoot"):
			try_fire()

	if Input.is_action_just_pressed("reload"):
		manual_reload()

func load_weapon(data: WeaponData) -> void:
	weapon_data = data
	current_ammo = data.mag_size
	state = WeaponState.IDLE
	_fire_timer = 0.0

func try_fire() -> void:
	if state != WeaponState.IDLE or current_ammo <= 0:
		return

	var spread_deg: float = (1.0 - weapon_data.accuracy) * 15.0

	if weapon_data.bullet_count > 1:
		# Distribute pellets evenly across the full spread cone
		var step := spread_deg * 2.0 / (weapon_data.bullet_count - 1)
		for i in weapon_data.bullet_count:
			_spawn_bullet(deg_to_rad(-spread_deg + step * i))
	else:
		_spawn_bullet(deg_to_rad(randf_range(-spread_deg, spread_deg)))

	current_ammo -= 1
	_fire_timer = 1.0 / weapon_data.fire_rate

	if current_ammo <= 0:
		state = WeaponState.COOLDOWN
		_cooldown_timer = weapon_data.cooldown_time
		EventBus.weapon_mag_empty.emit()

func manual_reload() -> void:
	if weapon_data == null or current_ammo >= weapon_data.mag_size:
		return
	match state:
		WeaponState.IDLE:
			_begin_reload()
		WeaponState.COOLDOWN:
			# Pressing R during cooldown skips the penalty — reward for good timing
			_cooldown_timer = 0.0
			_begin_reload()

func get_state_string() -> String:
	match state:
		WeaponState.COOLDOWN:  return "COOLDOWN"
		WeaponState.RELOADING: return "RELOADING"
		_:                     return "READY"

func is_busy() -> bool:
	return state == WeaponState.COOLDOWN or state == WeaponState.RELOADING

func is_in_cooldown() -> bool:
	return state == WeaponState.COOLDOWN

## Returns 0.0 → 1.0 fill progress for whichever phase is active.
func get_reload_progress() -> float:
	if weapon_data == null:
		return 0.0
	match state:
		WeaponState.COOLDOWN:
			return 1.0 - (_cooldown_timer / weapon_data.cooldown_time)
		WeaponState.RELOADING:
			return 1.0 - (_reload_timer / weapon_data.reload_time)
	return 0.0

func _spawn_bullet(angle_offset: float) -> void:
	var bullet := BULLET_SCENE.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle_point.global_position
	bullet.global_rotation = global_rotation + angle_offset
	bullet.speed = weapon_data.bullet_speed
	bullet.damage = weapon_data.damage

func _begin_reload() -> void:
	state = WeaponState.RELOADING
	_reload_timer = weapon_data.reload_time

func _finish_reload() -> void:
	current_ammo = weapon_data.mag_size
	state = WeaponState.IDLE
	EventBus.weapon_reload_complete.emit()
