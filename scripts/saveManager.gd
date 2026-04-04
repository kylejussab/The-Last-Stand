extends Node

const HOLDOUT_SAVE_PATH = "user://holdout.json"
const SECRET_KEY = "T3h_L4sT_St4nD_H0ld0ut_K3y_9921!" 

var isLoadingSave: bool = false

func has_holdout_save() -> bool:
	return FileAccess.file_exists(HOLDOUT_SAVE_PATH)

func save_holdout_state(data: Dictionary) -> void:
	var file = FileAccess.open_encrypted_with_pass(HOLDOUT_SAVE_PATH, FileAccess.WRITE, SECRET_KEY)
	if file:
		var jsonString = JSON.stringify(data)
		file.store_string(jsonString)
		file.close()
		print("Holdout state saved and encrypted successfully.")
	else:
		printerr("Failed to open save file for encrypted writing.")

func load_holdout_state() -> Dictionary:
	if not has_holdout_save():
		return {}
		
	var file = FileAccess.open_encrypted_with_pass(HOLDOUT_SAVE_PATH, FileAccess.READ, SECRET_KEY)
	
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		
		if error == OK:
			return json.data
		else:
			printerr("JSON Parse Error: Save file corrupted.")
			return {}
	else:
		printerr("Decryption failed. Save file tampered with or corrupted.")
		clear_holdout_save()
		return {}

func clear_holdout_save() -> void:
	if has_holdout_save():
		DirAccess.remove_absolute(HOLDOUT_SAVE_PATH)
		print("Holdout save cleared.")
