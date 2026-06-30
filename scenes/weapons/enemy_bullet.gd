extends Area2D

@export var speed: float = 300.0
@export var damage: float = 10.0
@export var lifetime: float = 2.0

func _ready() -> void:
	add_to_group("bullet")
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _process(delta: float) -> void:
	global_position += transform.x * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(int(damage))
	queue_free()
