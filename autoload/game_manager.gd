extends Node

# --- GAME MANAGER ---
# Quản lý trạng thái vòng đời game và các thuộc tính toàn cục của người chơi

var player_node: CharacterBody2D = null
var current_class_data: Resource = null # Sẽ là ClassData lưu class hiện tại

# Thuộc tính nhân vật
var player_level: int = 1
var player_exp: float = 0.0
var player_gold: int = 0

func _ready() -> void:
	# Đăng ký lắng nghe tín hiệu khi người chơi được spawn
	EventBus.player_spawned.connect(_on_player_spawned)

func _on_player_spawned(player: CharacterBody2D) -> void:
	player_node = player
	print("GameManager: Đã phát hiện Player spawned.")

func add_gold(amount: int) -> void:
	player_gold += amount
	print("GameManager: Nhận ", amount, " vàng. Tổng vàng hiện tại: ", player_gold)

func add_exp(amount: float) -> void:
	player_exp += amount
	print("GameManager: Nhận ", amount, " EXP. Tổng EXP: ", player_exp)
	# Logic level up có thể mở rộng tại đây ở các giai đoạn sau
