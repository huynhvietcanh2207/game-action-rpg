extends Node

# --- GLOBAL EVENT BUS ---
# Các module giao tiếp qua signal tại đây để tránh phụ thuộc trực tiếp (decoupling)

# Player Signals
signal player_spawned(player_node: CharacterBody2D)
signal player_health_changed(current_hp: float, max_hp: float)
signal player_mana_changed(current_mp: float, max_mp: float)
signal player_died()

# Skill/Combat Signals
signal skill_activated(skill_data: Resource, slot: int)
signal skill_cooldown_started(slot: int, duration: float)
signal damage_dealt(target: Node2D, amount: float, is_critical: bool)

# Monster Signals
signal monster_damaged_player(monster: Node2D, target: Node2D, amount: float)

# Quest & Loot Signals
signal item_collected(item_data: Resource, amount: int)
signal quest_objective_updated(quest_id: String, objective_index: int, progress: int)
