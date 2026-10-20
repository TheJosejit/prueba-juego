extends Enemy
## Blob: camina en línea recta y se da la vuelta al chocar con una pared. Se puede pisar.

const SPEED := 50.0
const COLOR := Color("9b5de5")
const COLOR_DARK := Color("6a31b5")
const COLOR_LIGHT := Color("c49bff")


func _ready() -> void:
	super()
	burst_color = COLOR


func _move(delta: float) -> void:
	walk(delta, SPEED)


func _draw_body() -> void:
	var wobble := sin(anim_time * 10.0) * 1.5 if active else 0.0
	var w := 14.0 + wobble
	var h := 19.0 - wobble
	DrawKit.shape(self, _dome(w, h), COLOR_LIGHT, COLOR_DARK, 2.0)
	# Burbujas dentro de la gelatina
	for k in 3:
		var bubble := Vector2(sin(anim_time * 1.3 + k * 2.1) * w * 0.4, -h * (0.25 + 0.15 * k))
		draw_circle(bubble, 1.4 + k * 0.4, Color(1, 1, 1, 0.22))
	# Brillo
	DrawKit.shine(self, Vector2(-w * 0.45, -h * 0.68), Vector2(3.2, 2.2), 0.7)
	draw_circle(Vector2(-w * 0.18, -h * 0.84), 1.3, Color.WHITE)
	draw_eyes(Vector2(direction * 3.0, -10.5), 4.6, 3.4, true)
	# Boca con un colmillo
	var mouth := Vector2(direction * 3.0, -4.5)
	draw_arc(mouth, 2.6, PI + 0.5, TAU - 0.5, 8, OUTLINE, 1.4, true)
	draw_colored_polygon(PackedVector2Array([mouth + Vector2(1.0, -1.6), mouth + Vector2(2.4, -1.2), mouth + Vector2(1.7, 0.4)]), Color.WHITE)


func _dome(w: float, h: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 21:
		var angle := PI + PI * i / 20.0
		points.append(Vector2(cos(angle) * w, sin(angle) * h))
	return points
