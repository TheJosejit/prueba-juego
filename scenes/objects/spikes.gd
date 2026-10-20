extends Area2D
## Pinchos: matan al jugador al tocarlos.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()


func _draw() -> void:
	for i in 3:
		var x := -16.0 + i * 32.0 / 3.0
		var spike := PackedVector2Array([
			Vector2(x, 16), Vector2(x + 32.0 / 6.0, 0), Vector2(x + 32.0 / 3.0, 16),
		])
		draw_colored_polygon(spike, Color("c9d1d9"))
		draw_polyline(spike, Color("6e7781"), 1.5)
