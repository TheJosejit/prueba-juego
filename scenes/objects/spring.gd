extends Area2D
## Muelle: al caer encima, el jugador sale disparado hacia arriba. El origen está en su base.

var squeeze := 0.0:
	set(value):
		squeeze = value
		queue_redraw()


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("spring_bounce") and body.velocity.y >= 0.0:
		body.spring_bounce()
		Sfx.play("spring", 0.05)
		var tween := create_tween()
		tween.tween_property(self, "squeeze", 7.0, 0.05)
		tween.tween_property(self, "squeeze", 0.0, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var outline := Color("1e1428")
	var top := -16.0 + squeeze
	draw_rect(Rect2(-13, -4, 26, 4), outline)
	draw_rect(Rect2(-12, -3.5, 24, 3), Color("6e7781"))
	var coil := PackedVector2Array()
	for i in 7:
		var y := lerpf(-4.0, top + 3.0, i / 6.0)
		coil.append(Vector2(-8.0 if i % 2 == 0 else 8.0, y))
	draw_polyline(coil, outline, 4.0, true)
	draw_polyline(coil, Color("c9d1d9"), 2.0, true)
	draw_rect(Rect2(-14, top - 1, 28, 6), outline)
	draw_rect(Rect2(-13, top, 26, 4), Color("e63946"))
	draw_rect(Rect2(-13, top, 26, 1.5), Color("ff8a92"))
