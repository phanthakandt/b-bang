extends Node

@export var room_scenes: Array[PackedScene] = []
@export var default_enemy_scenes: Array[PackedScene] = []
@export var default_wave_count: int = 2
@export var default_enemies_per_wave: int = 3

var current_room: Node = null
var rooms_completed: int = 0

const BOSS_ROOM_SCENE: PackedScene = preload("res://scenes/rooms/boss_room.tscn")
const PLAYER_SPAWN_POS: Vector2 = Vector2(416, 304)

func load_next_room() -> void:
	if current_room:
		current_room.queue_free()

	var is_boss := rooms_completed >= 4
	var next_scene: PackedScene = BOSS_ROOM_SCENE if is_boss else room_scenes[randi() % room_scenes.size()]

	current_room = next_scene.instantiate()
	get_tree().current_scene.add_child(current_room)

	if current_room is RoomBase:
		var room := current_room as RoomBase
		room.enemy_scenes = default_enemy_scenes
		room.wave_count = default_wave_count
		room.enemies_per_wave = default_enemies_per_wave

	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = PLAYER_SPAWN_POS

	current_room.start_room()
	rooms_completed += 1
