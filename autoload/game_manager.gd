extends Node

const MAX_RUNS: int = 10
const STAGES_PER_RUN: int = 5

var current_run: int = 0
var current_stage: int = 0
var gold: int = 0
var is_paused: bool = false

func _ready() -> void:
	EventBus.run_ended.connect(_on_run_ended)

func start_run() -> void:
	current_run += 1
	current_stage = 0
	gold = 0
	EventBus.run_started.emit(current_run)

func end_run(won: bool) -> void:
	SaveManager.data["total_runs"] += 1
	if current_run > SaveManager.data["best_run"]:
		SaveManager.data["best_run"] = current_run
	SaveManager.save()
	EventBus.run_ended.emit(won)

func next_stage() -> void:
	current_stage += 1
	if current_stage >= STAGES_PER_RUN:
		end_run(true)

func add_gold(amount: int) -> void:
	gold += amount
	EventBus.gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	EventBus.gold_changed.emit(gold)
	return true

## Difficulty scales linearly: 1.0 at run 1, 2.5 at run 10.
func get_difficulty_multiplier() -> float:
	return 1.0 + current_run * 0.15

func _on_run_ended(_won: bool) -> void:
	is_paused = false
