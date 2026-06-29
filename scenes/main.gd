extends Node2D

func _ready() -> void:
	print("=== B-BANG — Step 1 Init Check ===")
	print("  EventBus   : ", EventBus)
	print("  GameManager: ", GameManager)
	print("  SaveManager: ", SaveManager)

	SaveManager.load()
	print("  Save data  : ", SaveManager.data)

	# Defer the first run_started so all _ready() calls across the tree finish first.
	var timer := get_tree().create_timer(1.0)
	await timer.timeout
	EventBus.run_started.emit(0)
	print("  EventBus.run_started(0) emitted — foundation ready.")
