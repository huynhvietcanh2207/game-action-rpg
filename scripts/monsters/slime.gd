extends CharacterBody2D

# --- SLIME MONSTER AI ---
# Trạng thái di chuyển và tấn công của quái Slime

enum State {
	IDLE,
	WALK,
	CHASE,
	ATTACK,
	HURT,
	DIE
}

@export var max_hp: float = 500.0
@export var walk_speed: float = 35.0
@export var chase_speed: float = 65.0
@export var attack_damage: float = 10.0
@export var attack_range: float = 35.0
@export var detect_range: float = 250.0

var current_hp: float = max_hp
var current_state: State = State.IDLE
var target_player: Node2D = null

# Quản lý thời gian hồi chiêu tấn công
var attack_timer: float = 0.0
var attack_cooldown: float = 1.5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	add_to_group("monsters")
	
	# Lắng nghe khi player xuất hiện trên EventBus
	EventBus.player_spawned.connect(_on_player_spawned)
	
	# Tìm kiếm trực tiếp player nếu đã được tạo từ trước (tránh bỏ lỡ signal khi spawn sau)
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]
	
	# Bắt đầu ở trạng thái đứng im
	_change_state(State.IDLE)

func _on_player_spawned(player: Node2D) -> void:
	target_player = player

func _physics_process(delta: float) -> void:
	if current_state == State.DIE:
		return
		
	# Cập nhật bộ đếm thời gian hồi đòn
	if attack_timer > 0.0:
		attack_timer -= delta
		
	# Xử lý các trạng thái
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			_check_player_distance()
			
		State.WALK, State.CHASE:
			if target_player and is_instance_valid(target_player):
				var dist = global_position.distance_to(target_player.global_position)
				var dir = (target_player.global_position - global_position).normalized()
				
				# Xoay mặt quái theo hướng di chuyển
				if dir.x != 0:
					sprite.flip_h = (dir.x < 0)
					
				if dist <= attack_range and attack_timer <= 0.0:
					_change_state(State.ATTACK)
				elif dist > detect_range * 1.5:
					_change_state(State.IDLE)
				else:
					var move_spd = chase_speed if current_state == State.CHASE else walk_speed
					velocity = dir * move_spd
					move_and_slide()
			else:
				_change_state(State.IDLE)
				
		State.ATTACK:
			velocity = Vector2.ZERO

func _check_player_distance() -> void:
	if target_player and is_instance_valid(target_player):
		var dist = global_position.distance_to(target_player.global_position)
		if dist <= detect_range:
			# Nếu ở gần, đuổi theo (chạy)
			_change_state(State.CHASE if dist < detect_range * 0.6 else State.WALK)

func _change_state(new_state: State) -> void:
	current_state = new_state
	match current_state:
		State.IDLE:
			sprite.play("idle")
		State.WALK:
			sprite.play("walk")
		State.CHASE:
			sprite.play("run")
		State.ATTACK:
			sprite.play("attack")
			attack_timer = attack_cooldown
			# Gây sát thương khi hoàn tất hoạt ảnh tấn công
			get_tree().create_timer(0.4).timeout.connect(_deal_attack_damage)

func _deal_attack_damage() -> void:
	if current_state == State.ATTACK:
		if target_player and is_instance_valid(target_player):
			var dist = global_position.distance_to(target_player.global_position)
			if dist <= attack_range + 15.0:
				print("Slime: Đã tấn công gây ", attack_damage, " sát thương cho Player!")
				# Báo sự kiện sát thương lên EventBus
				EventBus.monster_damaged_player.emit(self, target_player, attack_damage)
		# Chuyển về chạy/đuổi theo sau khi đánh xong
		_change_state(State.CHASE)

func take_damage(amount: float) -> void:
	if current_state == State.DIE:
		return
		
	current_hp -= amount
	health_bar.value = max(0.0, current_hp)
	print("Slime: Nhận ", amount, " sát thương! HP còn lại: ", current_hp, "/", max_hp)
	
	# Tạo và hiển thị số sát thương bay lên trên đầu quái
	var damage_label_scene = preload("res://scenes/systems/damage_label.tscn")
	var dmg_lbl = damage_label_scene.instantiate()
	get_parent().add_child(dmg_lbl)
	dmg_lbl.setup(amount, global_position + Vector2(0, -25.0))
	
	# Hất nhẹ quái ra sau khi trúng chiêu
	if target_player and is_instance_valid(target_player):
		var knock_dir = (global_position - target_player.global_position).normalized()
		global_position += knock_dir * 12.0
		
	if current_hp <= 0.0:
		die()

func die() -> void:
	_change_state(State.DIE)
	print("Slime: Đã bị tiêu diệt!")
	# Tắt va chạm và làm mờ biến mất
	collision_shape.set_deferred("disabled", true)
	health_bar.visible = false
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
