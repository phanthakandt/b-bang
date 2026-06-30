extends Area2D

@export var speed: float = 600.0
@export var damage: float = 10.0
@export var lifetime: float = 2.0

func _ready() -> void:
	add_to_group("bullet")
	add_to_group("player_bullet")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _process(delta: float) -> void:
	# transform.x is the local right vector — bullet faces its direction of travel.
	global_position += transform.x * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.take_damage(int(damage))
	queue_free()

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("player") or area.is_in_group("bullet") or area.is_in_group("xp_orb"):
		return
	if area.has_method("take_damage"):
		area.take_damage(int(damage))
	queue_free()
