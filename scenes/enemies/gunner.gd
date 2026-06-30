class_name Gunner
extends EnemyBase

@export var bullet_scene: PackedScene = preload("res://scenes/weapons/enemy_bullet.tscn")
@export var shoot_range: float = 220.0

var preferred_distance: float = 160.0

func _ready() -> void:
	enemy_name = "Gunner"
	max_hp = 45.0
	move_speed = 80.0
	damage = 12.0
	attack_cooldown = 1.8
	xp_reward = 15
	gold_reward = 6
	body_color = Color(0.85, 0.4, 0.2)
	body_size = Vector2(22, 26)
	attack_radius = shoot_range
	super._ready()

func _state_chase(_delta: float) -> void:
	if player_ref == null:
		state = EnemyState.PATROL
		return

	var dist := global_position.distance_to(player_ref.global_position)
	if dist > shoot_range:
		nav_agent.target_position = player_ref.global_position
		var next_pos: Vector2 = nav_agent.get_next_path_position()
		velocity = (next_pos - global_position).normalized() * move_speed
	# get_slide_collision_count() reflects last physics frame's move_and_slide() — if
	# retreating is blocked by a wall, dist never grows past preferred_distance, so
	# the un-gated version below would push into the wall forever. Stand and shoot instead.
	elif dist < preferred_distance and get_slide_collision_count() == 0:
		velocity = (global_position - player_ref.global_position).normalized() * move_speed
	else:
		velocity = Vector2.ZERO
		state = EnemyState.ATTACK

	if velocity != Vector2.ZERO:
		_face((player_ref.global_position - global_position).angle())

	if dist > detection_radius:
		state = EnemyState.PATROL
		player_ref = null

func perform_attack() -> void:
	if player_ref == null:
		return
	var bullet := bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position
	bullet.damage = damage
	bullet.speed = 300.0
	var dir := (player_ref.global_position - global_position).normalized()
	dir = dir.rotated(randf_range(-0.15, 0.15))
	bullet.global_rotation = dir.angle()
