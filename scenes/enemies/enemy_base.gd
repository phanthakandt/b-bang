class_name EnemyBase
extends CharacterBody2D

enum EnemyState { IDLE, PATROL, CHASE, ATTACK, STUNNED, DEAD }

@export var enemy_name: String = "Enemy"
@export var max_hp: float = 50.0
@export var move_speed: float = 120.0
@export var damage: float = 10.0
@export var attack_cooldown: float = 1.5
@export var xp_reward: int = 10
@export var gold_reward: int = 5
@export var detection_radius: float = 250.0
@export var attack_radius: float = 40.0
@export var body_color: Color = Color(0.88, 0.29, 0.29)
@export var body_size: Vector2 = Vector2(24, 28)

var current_hp: float
var state: EnemyState = EnemyState.IDLE
var player_ref: Player = null
var attack_timer: float = 0.0
var stun_timer: float = 0.0
var patrol_target: Vector2
var patrol_timer: float = 0.0

var _base_move_speed: float = 0.0
var _slow_timer: float = 0.0

@onready var body_rect: ColorRect = $BodyRect
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = $HurtBox
@onready var hurtbox_shape: CollisionShape2D = $HurtBox/CollisionShape2D
@onready var detection_zone: Area2D = $DetectionZone
@onready var detection_shape: CollisionShape2D = $DetectionZone/CollisionShape2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var hp_bar: ProgressBar = $HPBar
@onready var debug_label: Label = $DebugLabel

func _ready() -> void:
	add_to_group("enemy")
	current_hp = max_hp
	_base_move_speed = move_speed
	patrol_target = global_position
	patrol_timer = randf_range(2.0, 4.0)

	body_rect.color = body_color
	body_rect.size = body_size
	body_rect.position = -body_size * 0.5

	# Sub-resources are shared across instances unless duplicated — without this,
	# resizing one enemy's hitbox would resize every enemy using the same base scene.
	var body_shape: RectangleShape2D = collision_shape.shape.duplicate()
	body_shape.size = body_size
	collision_shape.shape = body_shape

	var hurt_shape: RectangleShape2D = hurtbox_shape.shape.duplicate()
	hurt_shape.size = body_size
	hurtbox_shape.shape = hurt_shape

	var det_shape: CircleShape2D = detection_shape.shape.duplicate()
	det_shape.radius = detection_radius
	detection_shape.shape = det_shape

	detection_zone.body_entered.connect(_on_player_detected)
	detection_zone.body_exited.connect(_on_player_lost)
	hurtbox.area_entered.connect(_on_hurt)

	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	debug_label.visible = OS.is_debug_build()

	if state == EnemyState.IDLE:
		state = EnemyState.PATROL

func _physics_process(delta: float) -> void:
	if state == EnemyState.DEAD:
		return

	_tick_slow(delta)

	match state:
		EnemyState.PATROL:
			_state_patrol(delta)
		EnemyState.CHASE:
			_state_chase(delta)
		EnemyState.ATTACK:
			_state_attack(delta)
		EnemyState.STUNNED:
			_state_stunned(delta)

	move_and_slide()
	debug_label.text = EnemyState.keys()[state]

func _tick_slow(delta: float) -> void:
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			move_speed = _base_move_speed

func _state_patrol(delta: float) -> void:
	patrol_timer -= delta
	var to_target := patrol_target - global_position
	if to_target.length() < 4.0 or patrol_timer <= 0.0:
		patrol_target = global_position + Vector2(randf_range(-100.0, 100.0), randf_range(-100.0, 100.0))
		patrol_timer = randf_range(2.0, 4.0)
		velocity = Vector2.ZERO
	else:
		velocity = to_target.normalized() * move_speed * 0.5

func _state_chase(delta: float) -> void:
	if player_ref == null:
		state = EnemyState.PATROL
		return

	nav_agent.target_position = player_ref.global_position
	var next_pos: Vector2 = nav_agent.get_next_path_position()
	velocity = (next_pos - global_position).normalized() * move_speed
	if velocity != Vector2.ZERO:
		body_rect.rotation = velocity.angle()

	var dist := global_position.distance_to(player_ref.global_position)
	if dist <= attack_radius:
		state = EnemyState.ATTACK
	elif dist > detection_radius:
		state = EnemyState.PATROL
		player_ref = null

func _state_attack(delta: float) -> void:
	velocity = Vector2.ZERO
	if player_ref == null:
		state = EnemyState.PATROL
		return

	body_rect.rotation = (player_ref.global_position - global_position).angle()

	attack_timer -= delta
	if attack_timer <= 0.0:
		perform_attack()
		attack_timer = attack_cooldown

	if global_position.distance_to(player_ref.global_position) > attack_radius:
		state = EnemyState.CHASE

func _state_stunned(delta: float) -> void:
	velocity = Vector2.ZERO
	stun_timer -= delta
	if stun_timer <= 0.0:
		state = EnemyState.CHASE if player_ref != null else EnemyState.PATROL

func perform_attack() -> void:
	pass

func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> void:
	if state == EnemyState.DEAD:
		return
	current_hp -= amount
	hp_bar.value = current_hp
	velocity += knockback
	_flash_hit()
	if current_hp <= 0.0:
		die()

func apply_stun(duration: float) -> void:
	state = EnemyState.STUNNED
	stun_timer = duration

func apply_slow(multiplier: float, duration: float) -> void:
	move_speed = _base_move_speed * multiplier
	_slow_timer = duration

func die() -> void:
	state = EnemyState.DEAD
	EventBus.enemy_died.emit(self)
	GameManager.add_gold(gold_reward)
	_spawn_xp_orb()
	body_rect.color = Color.WHITE
	hp_bar.visible = false
	await get_tree().create_timer(0.3).timeout
	queue_free()

func _flash_hit() -> void:
	body_rect.color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(body_rect) and state != EnemyState.DEAD:
		body_rect.color = body_color

func _spawn_xp_orb() -> void:
	var orb := Area2D.new()
	orb.global_position = global_position
	orb.add_to_group("xp_orb")

	var shape := CircleShape2D.new()
	shape.radius = 16.0
	var col := CollisionShape2D.new()
	col.shape = shape
	orb.add_child(col)

	var vis := ColorRect.new()
	vis.color = Color(0.4, 0.9, 1.0)
	vis.size = Vector2(10, 10)
	vis.position = Vector2(-5, -5)
	orb.add_child(vis)

	get_tree().current_scene.add_child(orb)
	orb.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("player"):
			orb.queue_free()
	)

func _on_player_detected(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_ref = body as Player
	if state == EnemyState.IDLE or state == EnemyState.PATROL:
		state = EnemyState.CHASE

func _on_player_lost(body: Node2D) -> void:
	if body != player_ref:
		return
	player_ref = null
	if state == EnemyState.CHASE:
		state = EnemyState.PATROL

## HurtBox is the only thing bullets damage — the body's CollisionShape2D sits on
## collision_layer 4 (not bullets' default mask 1) so body_entered can't also fire
## and apply damage a second time for the same hit.
func _on_hurt(area: Area2D) -> void:
	if not area.is_in_group("bullet"):
		return
	var dmg: float = area.damage if "damage" in area else 0.0
	take_damage(dmg)
	area.queue_free()
