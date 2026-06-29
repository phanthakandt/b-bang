extends Node

const SAVE_PATH: String = "user://save_data.json"

var data: Dictionary = {
	"unlocked_perks": [],
	"total_runs": 0,
	"best_run": 0,
	"settings": {}
}

func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot open save file — %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save()  # write defaults on first launch
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: cannot read save file — %s" % FileAccess.get_open_error())
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_warning("SaveManager: corrupt save file, using defaults")
		return
	# Merge so keys added in future game versions survive old saves.
	for key in data:
		if parsed.has(key):
			data[key] = parsed[key]

func get_perk_unlocked(perk_id: String) -> bool:
	return perk_id in data["unlocked_perks"]

func unlock_perk(perk_id: String) -> void:
	if get_perk_unlocked(perk_id):
		return
	data["unlocked_perks"].append(perk_id)
	save()

func reset() -> void:
	data = {
		"unlocked_perks": [],
		"total_runs": 0,
		"best_run": 0,
		"settings": {}
	}
	save()
