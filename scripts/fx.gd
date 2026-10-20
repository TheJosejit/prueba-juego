class_name Fx
## Efectos visuales reutilizables: partículas, estelas, ondas y textos flotantes.
## Se añaden a la escena actual, así siguen visibles aunque el nodo que los crea desaparezca.

static var _soft: Texture2D


## Textura de círculo difuminado para partículas suaves (se crea una sola vez).
static func soft_texture() -> Texture2D:
	if _soft == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color.WHITE)
		gradient.set_color(1, Color(1, 1, 1, 0))
		gradient.add_point(0.5, Color(1, 1, 1, 0.9))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1.0, 0.5)
		texture.width = 16
		texture.height = 16
		_soft = texture
	return _soft


## Explosión de partículas (pisar enemigos, recoger monedas, golpear bloques...).
static func burst(from: Node, pos: Vector2, color: Color, amount := 10, speed := 120.0) -> void:
	var p := CPUParticles2D.new()
	p.texture = soft_texture()
	p.amount = amount
	p.lifetime = 0.5
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 500)
	p.damping_min = 40.0
	p.damping_max = 80.0
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.6
	p.color = color
	_emit(from, p, pos)


## Destellos que flotan sin caer (mejoras, puntos de control).
static func sparkle(from: Node, pos: Vector2, color: Color, amount := 8) -> void:
	var p := CPUParticles2D.new()
	p.texture = soft_texture()
	p.amount = amount
	p.lifetime = 0.7
	p.spread = 180.0
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 70.0
	p.gravity = Vector2(0, -30)
	p.scale_amount_min = 0.15
	p.scale_amount_max = 0.4
	p.color = color
	_emit(from, p, pos)


## Trozos grandes que salen volando y giran (ladrillos rotos).
static func debris(from: Node, pos: Vector2, color: Color, amount := 8) -> void:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = 0.9
	p.direction = Vector2.UP
	p.spread = 70.0
	p.initial_velocity_min = 150.0
	p.initial_velocity_max = 280.0
	p.gravity = Vector2(0, 1100)
	p.angular_velocity_min = -720.0
	p.angular_velocity_max = 720.0
	p.scale_amount_min = 5.0
	p.scale_amount_max = 8.0
	p.color = color
	_emit(from, p, pos)


## Polvo a los pies (saltar, aterrizar, correr, derrapar).
static func dust(from: Node, pos: Vector2, amount := 6) -> void:
	var p := CPUParticles2D.new()
	p.texture = soft_texture()
	p.amount = amount
	p.lifetime = 0.45
	p.direction = Vector2.UP
	p.spread = 85.0
	p.initial_velocity_min = 25.0
	p.initial_velocity_max = 75.0
	p.gravity = Vector2(0, -20)
	p.damping_min = 60.0
	p.damping_max = 100.0
	p.scale_amount_min = 0.4
	p.scale_amount_max = 0.9
	p.color = Color(1, 1, 1, 0.75)
	_emit(from, p, pos)


## Onda circular que se expande y se desvanece.
static func ring(from: Node, pos: Vector2, color: Color, radius := 28.0, life := 0.3) -> void:
	var effect := Ring.new()
	effect.color = color
	effect.radius = radius
	effect.life = life
	_add(from, effect, pos)


## Silueta de Pip que se desvanece: deja una estela al ir muy rápido.
static func afterimage(from: Node, pos: Vector2, squash: Vector2, color: Color) -> void:
	var effect := Ghost.new()
	effect.squash = squash
	effect.color = color
	_add(from, effect, pos)


## Texto que sube y se desvanece, por ejemplo "+200". size: tamaño de letra.
static func popup(from: Node, pos: Vector2, text: String, color := Color.WHITE, size := 12) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(160, size + 6)
	label.position = pos - label.size / 2.0
	label.pivot_offset = label.size / 2.0
	label.z_index = 10
	label.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF # se anima cada fotograma
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("1e1428"))
	label.add_theme_constant_override("outline_size", 4)
	from.get_tree().current_scene.add_child(label)
	label.scale = Vector2(0.4, 0.4)
	var tween := label.create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "position:y", label.position.y - 32.0, 0.7) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.45)
	tween.tween_callback(label.queue_free)


static func _emit(from: Node, p: CPUParticles2D, pos: Vector2) -> void:
	p.one_shot = true
	p.explosiveness = 0.9
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	_add(from, p, pos)
	p.emitting = true
	p.finished.connect(p.queue_free)


static func _add(from: Node, node: Node2D, pos: Vector2) -> void:
	node.position = pos
	node.z_index = 5
	node.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	from.get_tree().current_scene.add_child(node)


## Efecto que se dibuja durante "life" segundos y se borra solo.
class TimedEffect extends Node2D:
	var life := 0.3
	var age := 0.0

	func _process(delta: float) -> void:
		age += delta
		if age >= life:
			queue_free()
		else:
			queue_redraw()


class Ring extends TimedEffect:
	var color := Color.WHITE
	var radius := 28.0

	func _draw() -> void:
		var t := age / life
		var r := radius * (0.3 + 0.7 * (1.0 - pow(1.0 - t, 3.0)))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(color, 1.0 - t), 3.0 * (1.0 - t) + 0.5, true)


class Ghost extends TimedEffect:
	var color := Color(1, 0.55, 0.26)
	var squash := Vector2.ONE

	func _ready() -> void:
		life = 0.22
		z_index = 0

	func _draw() -> void:
		var c := Color(color, 0.35 * (1.0 - age / life))
		draw_set_transform(Vector2.ZERO, 0.0, squash)
		draw_circle(Vector2(0, -20), 11.0, c)
		draw_rect(Rect2(-11, -20, 22, 15), c)
