class_name Fx
## Efectos visuales reutilizables: partículas y textos flotantes.
## Se añaden a la escena actual, así siguen visibles aunque el nodo que los crea desaparezca.


## Explosión de partículas (pisar enemigos, recoger monedas, golpear bloques...).
static func burst(from: Node, pos: Vector2, color: Color, amount := 10, speed := 120.0) -> void:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = 0.5
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 500)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = color
	_emit(from, p, pos)


## Polvo a los pies (saltar, aterrizar, correr).
static func dust(from: Node, pos: Vector2, amount := 6) -> void:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = 0.35
	p.direction = Vector2.UP
	p.spread = 80.0
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 60.0
	p.gravity = Vector2(0, -20)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = Color(1, 1, 1, 0.8)
	_emit(from, p, pos)


## Texto que sube y se desvanece, por ejemplo "+200".
static func popup(from: Node, pos: Vector2, text: String, color := Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(60, 16)
	label.position = pos - label.size / 2.0
	label.z_index = 10
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	from.get_tree().current_scene.add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 30.0, 0.6) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.4)
	tween.tween_callback(label.queue_free)


static func _emit(from: Node, p: CPUParticles2D, pos: Vector2) -> void:
	p.one_shot = true
	p.explosiveness = 0.9
	p.position = pos
	p.z_index = 5
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	from.get_tree().current_scene.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
