extends CanvasLayer

# --- HUD UI SYSTEM ---
# Thanh Kỹ Năng (Hotbar) hiển thị các ô Skill 1, Skill 2 và Cooldown

@onready var slot1_icon: TextureRect = $Control/Hotbar/SkillSlot1/Margin/Icon
@onready var slot1_cd_mask: ColorRect = $Control/Hotbar/SkillSlot1/CooldownMask
@onready var slot1_cd_label: Label = $Control/Hotbar/SkillSlot1/CooldownLabel

@onready var slot2_icon: TextureRect = $Control/Hotbar/SkillSlot2/Margin/Icon
@onready var slot2_cd_mask: ColorRect = $Control/Hotbar/SkillSlot2/CooldownMask
@onready var slot2_cd_label: Label = $Control/Hotbar/SkillSlot2/CooldownLabel

var cd1_timer: float = 0.0
var cd1_max: float = 1.0

var cd2_timer: float = 0.0
var cd2_max: float = 1.0

func _ready() -> void:
	EventBus.skill_activated.connect(_on_skill_activated)
	
	# Đặt biểu tượng ô Skill 1 (Tornado)
	var tornado_tex = load("res://assets/skills/skill loc xoay/loc_xoay_projectile.png")
	if tornado_tex and slot1_icon:
		slot1_icon.texture = tornado_tex
		
	# Đặt biểu tượng ô Skill 2 (Blue Fireball)
	var fireball_tex = load("res://assets/skills/skill blue/blue_fireball_projectile.png")
	if fireball_tex and slot2_icon:
		slot2_icon.texture = fireball_tex
		
	# Ẩn các lớp hồi chiêu
	_reset_cd_ui(1)
	_reset_cd_ui(2)

func _process(delta: float) -> void:
	# Cập nhật Cooldown Slot 1
	if cd1_timer > 0.0:
		cd1_timer -= delta
		if cd1_timer <= 0.0:
			_reset_cd_ui(1)
		else:
			slot1_cd_label.text = "%.1f" % cd1_timer
			slot1_cd_mask.size.y = 54.0 * (cd1_timer / cd1_max)
			
	# Cập nhật Cooldown Slot 2
	if cd2_timer > 0.0:
		cd2_timer -= delta
		if cd2_timer <= 0.0:
			_reset_cd_ui(2)
		else:
			slot2_cd_label.text = "%.1f" % cd2_timer
			slot2_cd_mask.size.y = 54.0 * (cd2_timer / cd2_max)

func _on_skill_activated(skill_data: SkillData, slot: int) -> void:
	if skill_data.skill_name == "Cuồng Phong Trận" or slot == 2:
		cd1_max = skill_data.cooldown
		cd1_timer = skill_data.cooldown
		slot1_cd_mask.visible = true
		slot1_cd_label.visible = true
	elif skill_data.skill_name == "Thương Hải Lam Hỏa" or slot == 3:
		cd2_max = skill_data.cooldown
		cd2_timer = skill_data.cooldown
		slot2_cd_mask.visible = true
		slot2_cd_label.visible = true

func _reset_cd_ui(slot_index: int) -> void:
	if slot_index == 1:
		cd1_timer = 0.0
		slot1_cd_mask.visible = false
		slot1_cd_label.visible = false
	elif slot_index == 2:
		cd2_timer = 0.0
		slot2_cd_mask.visible = false
		slot2_cd_label.visible = false
