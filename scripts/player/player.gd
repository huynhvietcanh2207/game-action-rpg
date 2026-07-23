extends CharacterBody2D

# Tốc độ di chuyển cơ bản (sẽ ghi đè bởi ClassData nếu có)
@export var speed: float = 200.0

# Lưu trữ hướng nhìn cuối cùng để duy trì animation Idle phù hợp
var last_facing: String = "down"

# Tải trước các kỹ năng thử nghiệm
var skill_tornado = preload("res://resources/skills/tornado.tres")
var skill_blue_fireball = preload("res://resources/skills/blue_fireball.tres")

# Tải trước Scene hiệu ứng chiêu thức
var skill_effect_scene = preload("res://scenes/systems/skill_effect.tscn")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Thiết lập ảnh nhân vật mặc định
	var default_frames = load("res://assets/charater/charater_1_frames.tres")
	sprite.sprite_frames = default_frames
	
	# Đưa người chơi vào nhóm 'player' để quái spawn sau dễ dàng tìm kiếm
	add_to_group("player")
	
	# Tải tốc độ và bộ hoạt ảnh SpriteFrames từ class hiện tại của GameManager nếu có
	if GameManager.current_class_data and GameManager.current_class_data is ClassData:
		speed = GameManager.current_class_data.base_speed
		if GameManager.current_class_data.character_sprite != null:
			sprite.sprite_frames = GameManager.current_class_data.character_sprite
		print("Player: Đã tải dữ liệu từ ClassData. Tốc độ: ", speed)
	else:
		print("Player: Không có ClassData, sử dụng tốc độ mặc định: ", speed)

	# Báo cáo lên EventBus rằng player đã sẵn sàng
	call_deferred("_emit_spawned")

func _emit_spawned() -> void:
	EventBus.player_spawned.emit(self)

func _unhandled_input(event: InputEvent) -> void:
	# Lắng nghe phím số 1 và 2 để tung skill hướng về phía chuột
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_1:
			_cast_skill(skill_tornado)
		elif event.keycode == KEY_2:
			_cast_skill(skill_blue_fireball)

func _cast_skill(skill_data: SkillData) -> void:
	var cast_dir = _get_auto_aim_direction()
		
	# Khởi tạo hiệu ứng chiêu thức
	var skill_effect = skill_effect_scene.instantiate()
	var spawn_pos = global_position + (cast_dir * 16.0) # Spawn nhô ra trước 1 chút
	get_parent().add_child(skill_effect)
	skill_effect.setup(skill_data, spawn_pos, cast_dir)
	
	# Báo tin lên EventBus
	EventBus.skill_activated.emit(skill_data, skill_data.slot_number)
	print("Player: Đã tung chiêu [", skill_data.skill_name, "] hướng về: ", cast_dir)

func _get_auto_aim_direction() -> Vector2:
	var monsters = get_tree().get_nodes_in_group("monsters")
	var nearest_monster: Node2D = null
	var min_dist: float = 600.0 # Bán kính tự động ghim bắn quái (600px)
	
	for monster in monsters:
		if is_instance_valid(monster) and monster.has_method("take_damage") and monster.current_hp > 0:
			var dist = global_position.distance_to(monster.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest_monster = monster
				
	if nearest_monster != null:
		var dir = (nearest_monster.global_position - global_position).normalized()
		if dir != Vector2.ZERO:
			return dir
			
	# Nếu không có quái nào ở gần, quay lại bắn theo phím di chuyển/hướng nhân vật
	return _get_cast_direction()

func _get_cast_direction() -> Vector2:
	var move_dir := Vector2.ZERO
	if InputMap.has_action("move_left") and InputMap.has_action("move_right") and InputMap.has_action("move_up") and InputMap.has_action("move_down"):
		move_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		move_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	else:
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			move_dir.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			move_dir.x += 1
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			move_dir.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			move_dir.y += 1
			
	if move_dir != Vector2.ZERO:
		return move_dir.normalized()
		
	# Nếu đứng yên, tung chiêu theo hướng nhìn hiện tại của nhân vật
	if last_facing == "side":
		return Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	elif last_facing == "up":
		return Vector2.UP
	else:
		return Vector2.DOWN

func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO
	
	# Đọc dữ liệu di chuyển từ Input Map (hỗ trợ cả phím cơ bản nếu chưa được cài đặt)
	if InputMap.has_action("move_left") and InputMap.has_action("move_right") and InputMap.has_action("move_up") and InputMap.has_action("move_down"):
		direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	else:
		# Fallback trực tiếp
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			direction.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			direction.x += 1
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			direction.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			direction.y += 1
			
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		
	velocity = direction * speed
	move_and_slide()
	
	# Xử lý cập nhật Animation dựa trên di chuyển thực tế
	_update_animation(direction)

func _update_animation(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		# Cập nhật hướng xoay mặt trái/phải khi có di chuyển ngang (kể cả đi chéo)
		if direction.x != 0:
			sprite.flip_h = (direction.x < 0)
			
		# Xác định hướng di chuyển ưu tiên (ngang hay dọc)
		if abs(direction.x) > abs(direction.y):
			last_facing = "side"
			sprite.play("run_side")
		else:
			if direction.y < 0:
				last_facing = "up"
				sprite.play("run_up")
			else:
				last_facing = "down"
				sprite.play("run_down")
	else:
		# Khi đứng yên, chạy animation Idle theo hướng nhìn cuối cùng
		if last_facing == "side":
			sprite.play("idle_side")
		elif last_facing == "up":
			sprite.play("idle_up")
		else:
			sprite.play("idle_down")
