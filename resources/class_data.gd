class_name ClassData
extends Resource

@export var class_title: String = ""
@export var base_hp: float = 100.0
@export var base_mp: float = 50.0
@export var base_atk: float = 10.0
@export var base_def: float = 5.0
@export var base_speed: float = 150.0

# Lưu trữ SpriteFrames chứa toàn bộ hoạt ảnh của nhân vật tương ứng với Class này (extensible)
@export var character_sprite: SpriteFrames = null

# Danh sách chứa 7 SkillData tương ứng cho class
@export var skills: Array[SkillData] = []
