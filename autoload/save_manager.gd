extends Node

# --- SAVE MANAGER ---
# Xử lý lưu và tải tiến trình game

const SAVE_PATH = "user://save_game.dat"

func save_game() -> bool:
	var save_data = {
		"level": GameManager.player_level,
		"exp": GameManager.player_exp,
		"gold": GameManager.player_gold,
		"class": GameManager.current_class_data.resource_path if GameManager.current_class_data else ""
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		print("SaveManager: Lỗi khi mở file để ghi: ", SAVE_PATH)
		return false
		
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	print("SaveManager: Đã lưu game thành công.")
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("SaveManager: Không tìm thấy file save.")
		return false
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		print("SaveManager: Lỗi khi mở file để đọc: ", SAVE_PATH)
		return false
		
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		print("SaveManager: Lỗi khi parse dữ liệu save JSON.")
		return false
		
	var save_data = json.data
	GameManager.player_level = save_data.get("level", 1)
	GameManager.player_exp = save_data.get("exp", 0.0)
	GameManager.player_gold = save_data.get("gold", 0)
	
	var class_path = save_data.get("class", "")
	if class_path != "":
		GameManager.current_class_data = load(class_path)
		
	print("SaveManager: Đã tải game thành công.")
	return true
