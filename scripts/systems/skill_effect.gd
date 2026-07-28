extends Area2D

# --- SKILL EFFECT SYSTEM ---
# Lớp xử lý chuyển động projectile và vụ nổ của Skill một cách data-driven (sử dụng ảnh đã cắt)
# Hỗ trợ máy trạng thái 3 giai đoạn: Xuất hiện (Start) -> Bay lặp (Loop) -> Biến mất (End/Explosion)

enum State {
	START,
	LOOP,
	END,
	EXPLOSION
}

var skill_data: SkillData
var direction: Vector2 = Vector2.RIGHT
var current_state: State = State.START

# Quản lý hoạt ảnh thủ công
var current_frame: int = 0
var anim_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Kết nối sự kiện va chạm với các vật thể vật lý (Tường, Quái...)
	body_entered.connect(_on_body_entered)
	
	# Đặt thời gian sống tối đa (2 giây) tránh rò rỉ bộ nhớ
	get_tree().create_timer(2.0).timeout.connect(func():
		if current_state != State.END and current_state != State.EXPLOSION:
			explode()
	)

func setup(data: SkillData, spawn_pos: Vector2, dir: Vector2) -> void:
	skill_data = data
	direction = dir
	global_position = spawn_pos
	scale = Vector2(0.35, 0.35)
	
	# Quay sprite theo hướng bay nếu cấu hình cho phép
	if dir != Vector2.ZERO:
		if skill_data.rotate_to_direction:
			rotation = dir.angle()
			# Tránh lật ngược đầu (upside down) khi bắn sang trái (hemi-sphere bên trái)
			sprite.flip_v = (dir.x < 0)
		else:
			rotation = 0.0
			sprite.flip_v = false
			# Nếu không xoay đạn (như lốc xoáy), chỉ lật ngang (flip_h) để xoay hướng bay nếu cần
			sprite.flip_h = (dir.x < 0)
		
	# Tắt region_enabled do chúng ta sử dụng ảnh đã cắt riêng biệt
	sprite.region_enabled = false
	
	if skill_data.has_projectile and skill_data.projectile_texture != null:
		_setup_projectile_visuals()
	else:
		explode()

func _physics_process(delta: float) -> void:
	# Di chuyển đạn khi chưa phát nổ/biến mất
	if current_state == State.START or current_state == State.LOOP:
		global_position += direction * skill_data.projectile_speed * delta
		
	_process_state_animation(delta)

func _setup_projectile_visuals() -> void:
	sprite.texture = skill_data.projectile_texture
	sprite.hframes = skill_data.proj_frame_count
	sprite.vframes = 1
	anim_timer = 0.0
	
	if skill_data.proj_start_frames > 0:
		current_state = State.START
		current_frame = 0
	else:
		current_state = State.LOOP
		current_frame = 0
		
	sprite.frame = current_frame

func _setup_explosion_visuals() -> void:
	current_state = State.EXPLOSION
	if not skill_data.has_explosion or skill_data.explosion_texture == null:
		queue_free()
		return
		
	sprite.texture = skill_data.explosion_texture
	sprite.hframes = skill_data.exp_frame_count
	sprite.vframes = 1
	current_frame = 0
	sprite.frame = 0
	anim_timer = 0.0
	
	# Reset các thuộc tính quay và lật để hiệu ứng nổ hiển thị bình thường thẳng đứng
	rotation = 0.0
	sprite.flip_v = false
	sprite.flip_h = false

func _process_state_animation(delta: float) -> void:
	anim_timer += delta
	var anim_speed = skill_data.proj_anim_speed if current_state != State.EXPLOSION else skill_data.exp_anim_speed
	
	if anim_timer >= anim_speed:
		anim_timer = 0.0
		
		match current_state:
			State.START:
				current_frame += 1
				if current_frame >= skill_data.proj_start_frames:
					# Chuyển sang giai đoạn bay lặp (Loop)
					current_state = State.LOOP
					current_frame = skill_data.proj_start_frames
				sprite.frame = current_frame
				
			State.LOOP:
				current_frame += 1
				var loop_end = skill_data.proj_start_frames + skill_data.proj_loop_frames
				if current_frame >= loop_end:
					# Lặp lại trong khoảng các frame bay lặp
					current_frame = skill_data.proj_start_frames
				sprite.frame = current_frame
				
			State.END:
				current_frame += 1
				var end_max = skill_data.proj_start_frames + skill_data.proj_loop_frames + skill_data.proj_end_frames
				if current_frame >= end_max:
					queue_free() # Đã chạy xong hoạt ảnh tan biến -> giải phóng bộ nhớ
					return
				sprite.frame = current_frame
				
			State.EXPLOSION:
				current_frame += 1
				if current_frame >= skill_data.exp_frame_count:
					queue_free() # Đã nổ xong -> giải phóng bộ nhớ
					return
				sprite.frame = current_frame

func explode() -> void:
	if current_state == State.EXPLOSION or current_state == State.END:
		return
		
	if skill_data.has_explosion and skill_data.explosion_texture != null:
		_setup_explosion_visuals()
	else:
		# Nếu không có vụ nổ riêng, chạy hoạt ảnh tan biến (END) của chính đạn bay
		if skill_data.proj_end_frames > 0:
			current_state = State.END
			current_frame = skill_data.proj_start_frames + skill_data.proj_loop_frames
			sprite.frame = current_frame
			anim_timer = 0.0
		else:
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	# Tránh va chạm với chính người chơi bắn ra chiêu thức
	if body is CharacterBody2D and body.name == "Player":
		return
		
	# Gây sát thương nếu va chạm vật thể có phương thức take_damage (ví dụ: Quái Slime)
	if body.has_method("take_damage"):
		body.take_damage(skill_data.damage)
		
	# Nếu chạm bất kỳ vật thể nào khác (Tường hoặc Quái), kích hoạt nổ/tan biến
	explode()
