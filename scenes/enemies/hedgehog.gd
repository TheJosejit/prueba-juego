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
	# Pinchos (detrás del cuerpo), metálicos con brillo
	for i in 7:
		var a := PI + 0.25 + i * (PI - 0.5) / 6.0
		var base := Vector2(cos(a) * 11.0 - direction * 2.0, -10.0 + sin(a) * 8.0)
		var tip := base + Vector2(cos(a), sin(a)) * 9.0
		var side := Vector2(-sin(a), cos(a)) * 3.2
		DrawKit.shape(self, PackedVector2Array([base - side, tip, base + side]), Color.WHITE, SPIKE.darkened(0.25), 1.2)
	# Patas
	for foot in [Vector2(-5.5, -2.0 - maxf(step, 0.0)), Vector2(5.5, -2.0 - maxf(-step, 0.0))]:
		DrawKit.shape(self, DrawKit.ellipse(foot, Vector2(3.5, 2.3), 10), BODY_DARK.lightened(0.1), BODY_DARK.darkened(0.2), 1.2)
	# Cuerpo
	DrawKit.shape(self, DrawKit.ellipse(Vector2(0, -10), Vector2(12, 10.5), 24), BODY.lightened(0.15), BODY_DARK, 1.8)
	DrawKit.shine(self, Vector2(-direction * 4.0, -16.5), Vector2(3.0, 1.8), 0.35)
	# Cara
	var face := Vector2(direction * 7.0, -9)
	DrawKit.shape(self, DrawKit.ellipse(face, Vector2(6.0, 5.5), 18), FACE.lightened(0.15), FACE.darkened(0.12), 1.4)
	var nose := face + Vector2(direction * 5.5, 0.5)
	draw_circle(nose, 2.3, OUTLINE)
	draw_circle(nose + Vector2(-0.6, -0.6), 0.7, Color(1, 1, 1, 0.7))
	var eye := face + Vector2(direction * 1.0, -2.2)
	draw_colored_polygon(DrawKit.ellipse(eye, Vector2(1.7, 2.1), 12), OUTLINE)
	draw_circle(eye + Vector2(-0.5, -0.7), 0.6, Color.WHITE)
	draw_line(eye + Vector2(-2.5, -3.0), eye + Vector2(2.0, -2.3), OUTLINE, 1.2, true) # ceja enfadada
	draw_colored_polygon(DrawKit.ellipse(face + Vector2(-direction * 1.5, 2.5), Vector2(1.8, 1.0), 10), Color(1, 0.45, 0.5, 0.5))
