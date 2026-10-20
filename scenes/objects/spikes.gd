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
	DrawKit.shape(self, DrawKit.rounded_rect(Rect2(-16, 11, 32, 5), 1.5), METAL_DARK.lightened(0.1), METAL_DARK.darkened(0.3), 1.2)
	for i in 3:
		var x := -16.0 + i * 32.0 / 3.0
		var w := 32.0 / 3.0
		var spike := PackedVector2Array([Vector2(x + 0.5, 12), Vector2(x + w / 2.0, 0), Vector2(x + w - 0.5, 12)])
		DrawKit.shape(self, spike, Color.WHITE, METAL.darkened(0.2), 1.2)
		draw_colored_polygon(PackedVector2Array([Vector2(x + w / 2.0, 1.5), Vector2(x + w - 1.5, 11.5), Vector2(x + w / 2.0, 11.5)]),
			Color(METAL_DARK, 0.45)) # cara en sombra
		draw_circle(Vector2(x + w / 2.0 - 0.6, 3.0), 0.9, Color.WHITE)
