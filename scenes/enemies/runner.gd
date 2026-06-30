class_name Runner
extends EnemyBase

func _ready() -> void:
	enemy_name = "Runner"
	max_hp = 30.0
	move_speed = 200.0
	damage = 8.0
	attack_cooldown = 0.8
	xp_reward = 8
	gold_reward = 3
	body_color = Color(0.9, 0.3, 0.3)
	body_size = Vector2(18, 22)
	attack_radius = 35.0
	super._ready()

func perform_attack() -> void:
	if player_ref and global_position.distance_to(player_ref.global_position) < attack_radius + 10.0:
		player_ref.take_damage(int(damage))
