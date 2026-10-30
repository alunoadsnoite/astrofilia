extends Node

## SaveSystem — JSON-based persistence.
## Replaces ConfigFile for nested dictionaries (achievements, slots, snapshots).
##
## Usage (from GameManager):
##   SaveSystem.save(slot_data)  → saves a slot
##   SaveSystem.load()           → returns the whole save dict or {}
##
## Data format:
##   {
##     "version": 2,
##     "player": {...},
##     "saves": { "games": [ { "name": "...", "snapshot": {...} }, ... ] }
##   }

const SAVE_PATH := "user://astrofilia_save.json"
const SAVE_VERSION := 2

func _ready() -> void:
	# No initialization needed

## Save the full save data.
## Returns OK on success, ERR_* on failure.
func save(data: Dictionary) -> Error:
	var json := JSON.stringify(data, 0, JSON.CONTAINS_NO_SLASHES)
	var fa := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if fa == null:
		_print("SaveSystem: cannot open " + SAVE_PATH)
		return Error.ERR_CANT_CREATE
	fa.store_string(json)
	fa.close()
	return OK

## Load the full save data.
## Returns a Dictionary (empty if no save exists or parse fails).
func load() -> Dictionary:
	var fa := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if fa == null:
		return {}
	var json := fa.get_as_string()
	fa.close()
	var parsed := JSON.parse_string(json, true)
	if parsed.is_error():
		_print("SaveSystem: parse error: " + str(parsed.error_code()))
		return {}
	return parsed
