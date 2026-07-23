extends Node2D

# --- MONSTER SPAWNER SYSTEM ---
# Tự động tạo 1 quái Slime mới mỗi 5 giây xung quanh Player

@export var spawn_interval: float = 5.0
@export var slime_scene: PackedScene = preload("res://scenes/monsters/slime.tscn")
@export var slime_dark_scene: PackedScene = preload("res://scenes/monsters/slime_dark.tscn")

var player_node: Node2D = null
var spawn_timer: float = 0.0

func _ready() -> void:
	# Lắng nghe người chơi xuất hiện để bám theo lấy vị trí
	EventBus.player_spawned.connect(func(player):
		player_node = player
	)
	
	# Đặt thời gian hồi phục khởi đầu
	spawn_timer = spawn_interval

func _process(delta: float) -> void:
	if player_node == null or not is_instance_valid(player_node):
		# Thử tìm kiếm trực tiếp trong nhóm nếu chưa nhận được signal
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_node = players[0]
		else:
			return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = spawn_interval
		_spawn_monster()

func _spawn_monster() -> void:
	# Chọn một góc ngẫu nhiên và khoảng cách ngẫu nhiên từ 250 đến 450 px
	var random_angle = randf() * TAU
	var random_dist = randf_range(250.0, 450.0)
	var spawn_offset = Vector2(cos(random_angle), sin(random_angle)) * random_dist
	var spawn_pos = player_node.global_position + spawn_offset
	
	# Ngẫu nhiên chọn loại quái: 70% Slime thường, 30% Slime Tối
	var selected_scene = slime_scene
	var is_dark = randf() < 0.3
	if is_dark and slime_dark_scene != null:
		selected_scene = slime_dark_scene
		
	if selected_scene == null:
		return
		
	var monster = selected_scene.instantiate()
	monster.global_position = spawn_pos
	
	# Thêm vào node chứa quái của map
	var monsters_node = get_node_or_null("/root/MapPlayground/Monsters")
	if monsters_node:
		monsters_node.add_child(monster)
	else:
		get_parent().add_child(monster)
		
	var monster_type = "Slime Dark" if is_dark else "Slime"
	print("Spawner: Đã sinh ra 1 quái [", monster_type, "] tại vị trí: ", spawn_pos)
