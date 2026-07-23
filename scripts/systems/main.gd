extends Node2D

# --- MAIN GAME WORLD MANAGER ---
# Quản lý cấu trúc tổng thể: Tải Map, nạp Player, sinh Quái và Giao diện UI

@export var map_scene: PackedScene = preload("res://scenes/map/map_playground.tscn")
@export var player_scene: PackedScene = preload("res://scenes/player/player.tscn")
@export var slime_scene: PackedScene = preload("res://scenes/monsters/slime.tscn")
@export var slime_dark_scene: PackedScene = preload("res://scenes/monsters/slime_dark.tscn")

@onready var map_container: Node2D = $MapContainer
@onready var player_container: Node2D = $Entities/PlayerContainer
@onready var monsters_container: Node2D = $Entities/Monsters

func _ready() -> void:
	# 1. Khởi tạo Bản đồ (Map)
	if map_scene:
		var current_map = map_scene.instantiate()
		map_container.add_child(current_map)
		
		# 2. Khởi tạo Player tại điểm PlayerSpawn của Map
		var player_spawn = current_map.get_node_or_null("SpawnPoints/PlayerSpawn")
		var spawn_pos = player_spawn.global_position if player_spawn else Vector2.ZERO
		
		if player_scene:
			var player = player_scene.instantiate()
			player.global_position = spawn_pos
			player_container.add_child(player)
			
		# 3. Khởi tạo bầy quái ban đầu tại các điểm MonsterSpawns của Map
		var monster_spawns = current_map.get_node_or_null("SpawnPoints/MonsterSpawns")
		if monster_spawns:
			var spawn_nodes = monster_spawns.get_children()
			for idx in range(spawn_nodes.size()):
				var marker = spawn_nodes[idx]
				# 70% Slime thường, 30% SlimeDark
				var m_scene = slime_dark_scene if (idx % 3 == 0) else slime_scene
				if m_scene:
					var m = m_scene.instantiate()
					m.global_position = marker.global_position
					monsters_container.add_child(m)
