class_name Door
extends Node2D

@export var direction: String = "north"

var is_locked: bool = true

@onready var block_collision: CollisionShape2D = $BlockBody/CollisionShape2D
@onready var door_visual: ColorRect = $DoorVisual
@onready var trigger_shape: CollisionShape2D = $TransitionTrigger/CollisionShape2D

func _ready() -> void:
	$TransitionTrigger.body_entered.connect(_on_transition_trigger_body_entered)
	lock()

## Resizes the door's blocking shape, visual, and trigger area to match the
## wall opening room_base cut for this door — the base scene ships a generic
## 32x64 placeholder shape that doesn't fit every wall gap.
func configure(gap_size: Vector2) -> void:
	var block_shape: RectangleShape2D = block_collision.shape.duplicate()
	block_shape.size = gap_size
	block_collision.shape = block_shape

	door_visual.size = gap_size
	door_visual.position = -gap_size * 0.5

	var trig_shape: RectangleShape2D = trigger_shape.shape.duplicate()
	trig_shape.size = gap_size * 1.2
	trigger_shape.shape = trig_shape

func lock() -> void:
	is_locked = true
	block_collision.disabled = false
	door_visual.color = Color(0.35, 0.29, 0.17)

func unlock() -> void:
	is_locked = false
	block_collision.set_deferred("disabled", true)
	door_visual.color = Color(0.16, 0.54, 0.29)

func _on_transition_trigger_body_entered(body: Node) -> void:
	if not is_locked and body.is_in_group("player"):
		RoomLoader.load_next_room()
