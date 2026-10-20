extends Area2D
## Pinchos: hacen daño al jugador (si tiene una mejora, la pierde; si no, muere).

const METAL := Color("c9d1d9")
const METAL_DARK := Color("6e7781")


func _ready() -> void:
	add_to_group("hazards")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("hurt"):
		body.hurt()


func _draw() -> void:
	draw_rect(Rect2(-16, 12, 32, 4), METAL_DARK)
	for i in 3:
		var x := -16.0 + i * 32.0 / 3.0
		var w := 32.0 / 3.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, 13), Vector2(x + w / 2.0, 0), Vector2(x + w, 13)]), METAL_DARK)
		draw_colored_polygon(PackedVector2Array([Vector2(x + 1, 13), Vector2(x + w / 2.0, 2), Vector2(x + w / 2.0, 13)]), METAL)
		draw_colored_polygon(PackedVector2Array([Vector2(x + w / 2.0, 2), Vector2(x + w - 1, 13), Vector2(x + w / 2.0, 13)]), METAL.darkened(0.2))
