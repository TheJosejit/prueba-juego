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
	draw_circle(Vector2.ZERO, 9.0, Color("ffd23f"))
	draw_circle(Vector2.ZERO, 6.0, Color("ffe98a"))
