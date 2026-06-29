extends Node

const _PATHS: Dictionary = {
	"ak_iron":   "res://resources/weapons/ak_iron.tres",
	"breach_12": "res://resources/weapons/breach_12.tres",
	"echo_smg":  "res://resources/weapons/echo_smg.tres",
}

func create_weapon(weapon_id: String) -> WeaponData:
	if not _PATHS.has(weapon_id):
		push_error("WeaponFactory: unknown weapon_id '%s'" % weapon_id)
		return null
	return load(_PATHS[weapon_id]) as WeaponData
