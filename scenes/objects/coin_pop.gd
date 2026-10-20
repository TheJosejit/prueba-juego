extends Node2D
## Moneda que sale disparada de un bloque sorpresa y desaparece.


func _ready() -> void:
	physics_interpolation_mode = PHYSICS_INTERPOLATION_MODE_OFF # se anima cada fotograma, no con la física
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 48.0, 0.25) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 10.6, DrawKit.OUTLINE)
	DrawKit.gradient_fill(self, DrawKit.circle(Vector2.ZERO, 9.4, 24), Color("fff1a8"), Color("c98a00"))
	DrawKit.gradient_fill(self, DrawKit.circle(Vector2.ZERO, 6.6, 20), Color("dca21a"), Color("ffe066"))
	draw_arc(Vector2.ZERO, 8.0, PI * 1.1, PI * 1.5, 8, Color(1, 1, 1, 0.75), 1.6, true)
