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
	var top := -16.0 + squeeze
	DrawKit.contact_shadow(self, Vector2.ZERO, 14.0, 0.22)
	DrawKit.shape(self, DrawKit.rounded_rect(Rect2(-12.5, -4, 25, 4), 1.5), Color("aeb7c2"), Color("5d6670"), 1.4)
	var coil := PackedVector2Array()
	for i in 7:
		var y := lerpf(-4.0, top + 3.0, i / 6.0)
		coil.append(Vector2(-8.0 if i % 2 == 0 else 8.0, y))
	draw_polyline(coil, DrawKit.OUTLINE, 4.5, true)
	draw_polyline(coil, Color("c9d1d9"), 2.5, true)
	draw_polyline(coil, Color(1, 1, 1, 0.6), 0.8, true)
	var plate := DrawKit.rounded_rect(Rect2(-13.5, top - 1, 27, 6), 3.0)
	DrawKit.shape(self, plate, Color("ff6b74"), Color("c42d3a"), 1.5)
	draw_line(Vector2(-10, top + 0.4), Vector2(10, top + 0.4), Color(1, 1, 1, 0.6), 1.2)
