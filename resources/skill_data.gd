class_name SkillData
extends Resource

@export var skill_name: String = ""
@export var slot_number: int = 1 # 1-7 (1: Đánh thường, 2-6: Skill 1-5, 7: Ultimate)
@export var cooldown: float = 1.0
@export var mana_cost: float = 0.0
@export var damage: float = 10.0
@export var description: String = ""
@export var effect_type: String = "damage" # damage, heal, buff, debuff, shield

# --- HÌNH ẢNH CHIÊU THỨC (DATA-DRIVEN VISUALS) ---
@export_group("Visual Projectile")
@export var has_projectile: bool = true
@export var projectile_speed: float = 400.0
@export var projectile_texture: Texture2D = null
@export var proj_frame_count: int = 4
@export var proj_anim_speed: float = 0.1

# Cấu hình xoay ảnh theo hướng bắn (Hỏa cầu cần xoay, Lốc xoáy/Nhát chém cần đứng thẳng)
@export var rotate_to_direction: bool = true

# Phân nhỏ giai đoạn hoạt ảnh đạn bay để tránh lặp lại hoạt ảnh xuất hiện/tan biến
@export var proj_start_frames: int = 0  # Số frame đầu tiên chỉ chạy 1 lần khi xuất hiện
@export var proj_loop_frames: int = 4   # Số frame lặp lại trong suốt quá trình bay
@export var proj_end_frames: int = 0    # Số frame cuối tự nổ/tan biến khi hết tầm bay (nếu không có explosion_texture)

@export_group("Visual Explosion")
@export var has_explosion: bool = true
@export var explosion_texture: Texture2D = null
@export var exp_frame_count: int = 8
@export var exp_anim_speed: float = 0.08
