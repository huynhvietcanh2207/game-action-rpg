extends Node2D

# --- FLOATING DAMAGE TEXT ---
# Hiển thị số sát thương nhảy lên khi đánh quái

@onready var label: Label = $Label

func setup(amount: float, spawn_pos: Vector2) -> void:
	global_position = spawn_pos
	label.text = str(int(amount))
	
	# Tạo chuyển động bay lên và mờ dần
	var tween = create_tween()
	tween.set_parallel(true)
	# Bay lên trên 40px
	tween.tween_property(self, "global_position:y", global_position.y - 50.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Phóng to nhẹ lúc xuất hiện rồi thu nhỏ lại
	scale = Vector2(0.5, 0.5)
	var scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15)
	scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
	# Mờ dần và biến mất
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.2)
	
	# Xóa label khỏi bộ nhớ sau khi bay xong
	tween.chain().tween_callback(queue_free)
