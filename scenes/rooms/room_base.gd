class_name RoomBase
extends Node2D

const WALL_T: float = 32.0
const NS_GAP: Vector2 = Vector2(96.0, WALL_T)
const EW_GAP: Vector2 = Vector2(WALL_T, 96.0)
const ROOM_CENTER: Vector2 = Vector2(416.0, 304.0)
# Matches the floor's NavigationPolygon rect in room_base.tscn (32,32)-(800,576) —
# passed to spawned enemies so their PATROL wander target stays inside the room.
const FLOOR_BOUNDS: Rect2 = Rect2(Vector2(32.0, 32.0), Vector2(768.0, 544.0))

@export var room_type: String = "combat"
@export var enemy_scenes: Array[PackedScene] = []
@export var wave_count: int = 2
@export var enemies_per_wave: int = 3

var current_wave: int = 0
var active_enemies: int = 0
var room_cleared: bool = false
var player_entered: bool = false

@onready var spawn_points: Node2D = $EnemySpawnPoints
@onready var enemies_node: Node2D = $Enemies
@onready var loot_node: Node2D = $Loot
@onready var room_label: Label = $RoomLabel
@onready var door_north: Door = $Doors/Door_North
@onready var door_south: Door = $Doors/Door_South
@onready var door_east: Door = $Doors/Door_East
@onready var door_west: Door = $Doors/Door_West
@onready var _doors: Array[Door] = [door_north, door_south, door_east, door_west]

func _ready() -> void:
	door_north.configure(NS_GAP)
	door_south.configure(NS_GAP)
	door_east.configure(EW_GAP)
	door_west.configure(EW_GAP)
	_lock_doors()
	EventBus.enemy_died.connect(_on_enemy_died)

func start_room() -> void:
	player_entered = true
	_lock_doors()
	spawn_wave()

func spawn_wave() -> void:
	current_wave += 1
	var points: Array = spawn_points.get_children()
	points.shuffle()

	active_enemies = 0
	if not enemy_scenes.is_empty():
		var count: int = mini(enemies_per_wave, points.size())
		for i in count:
			var scene: PackedScene = enemy_scenes[randi() % enemy_scenes.size()]
			var enemy: EnemyBase = scene.instantiate()
			enemies_node.add_child(enemy)
			enemy.global_position = points[i].global_position
			enemy.patrol_bounds = FLOOR_BOUNDS
			active_enemies += 1

	room_label.text = "Wave %d / %d" % [current_wave, wave_count]

func _on_enemy_died(_enemy: Node) -> void:
	if not enemies_node.is_ancestor_of(_enemy):
		return
	active_enemies -= 1
	if active_enemies <= 0:
		if current_wave < wave_count:
			await get_tree().create_timer(1.5).timeout
			spawn_wave()
		else:
			clear_room()

func clear_room() -> void:
	room_cleared = true
	_unlock_doors()
	_spawn_loot()
	EventBus.room_cleared.emit()
	room_label.text = "CLEARED"

func _lock_doors() -> void:
	for door in _doors:
		door.lock()

func _unlock_doors() -> void:
	for door in _doors:
		door.unlock()

func _spawn_loot() -> void:
	var drop := ColorRect.new()
	if randf() < 0.5:
		drop.color = Color(1.0, 0.85, 0.2)
		drop.size = Vector2(12, 12)
	else:
		drop.color = Color(0.3, 0.9, 0.4)
		drop.size = Vector2(14, 14)
	drop.position = ROOM_CENTER - drop.size * 0.5
	loot_node.add_child(drop)
