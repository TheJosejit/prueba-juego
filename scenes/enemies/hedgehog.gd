extends Enemy
## Erizo: camina despacio y se da la vuelta en los bordes. Tiene pinchos: NO se puede pisar.
## Solo se le vence golpeando desde abajo el bloque sobre el que está.

const SPEED := 38.0
const BODY := Color("8a5a3c")
const BODY_DARK := Color("5e3a24")
const FACE := Color("e8c49a")
const SPIKE := Color("d9dde3")


func _ready() -> void:
	super()
	spiky = true
	points = 300
	burst_color = BODY


func _move(delta: float) -> void:
	walk(delta, SPEED, true)


func _draw_body() -> void:
	var step := sin(anim_time * 12.0) * 1.5 if active else 0.0
	# Pinchos (detrás del cuerpo)
	for i in 7:
		var a := PI + 0.25 + i * (PI - 0.5) / 6.0
		var base := Vector2(cos(a) * 12.0 - direction * 2.0, -9.0 + sin(a) * 9.0)
		var tip := base + Vector2(cos(a), sin(a)) * 8.0
		var side := Vector2(-sin(a), cos(a)) * 3.0
		var spike := PackedVector2Array([base - side, tip, base + side])
		draw_colored_polygon(spike, SPIKE)
		draw_polyline(PackedVector2Array([base - side, tip, base + side]), OUTLINE, 1.2, true)
	# Patas
	draw_rect(Rect2(-9, -4 - maxf(step, 0.0), 6, 4), OUTLINE)
	draw_rect(Rect2(3, -4 - maxf(-step, 0.0), 6, 4), OUTLINE)
	# Cuerpo
	draw_circle(Vector2(0, -10), 12.5, OUTLINE)
	draw_circle(Vector2(0, -10), 11.0, BODY)
	draw_circle(Vector2(-direction * 3.0, -6), 7.0, BODY_DARK)
	# Cara
	var face := Vector2(direction * 7.0, -9)
	draw_circle(face, 6.5, OUTLINE)
	draw_circle(face, 5.5, FACE)
	draw_circle(face + Vector2(direction * 5.5, 1), 2.2, OUTLINE)
	draw_circle(face + Vector2(direction * 1.0, -2), 1.6, OUTLINE)
