extends Enemy
## Blob: camina en línea recta y se da la vuelta al chocar con una pared. Se puede pisar.

const SPEED := 50.0
const COLOR := Color("9b5de5")
const COLOR_DARK := Color("6a31b5")
const COLOR_LIGHT := Color("c9a6ff")


func _ready() -> void:
	super()
	burst_color = COLOR


func _move(delta: float) -> void:
	walk(delta, SPEED)


func _draw_body() -> void:
	var wobble := sin(anim_time * 10.0) * 1.5 if active else 0.0
	var w := 14.0 + wobble
	var h := 19.0 - wobble
	draw_colored_polygon(_dome(w + 1.5, h + 1.5), OUTLINE)
	draw_colored_polygon(_dome(w, h), COLOR)
	# Sombra inferior y brillo
	draw_rect(Rect2(-w, -4, w * 2.0, 3.5), COLOR_DARK)
	draw_circle(Vector2(-w * 0.45, -h * 0.65), 3.0, COLOR_LIGHT)
	draw_circle(Vector2(-w * 0.2, -h * 0.8), 1.5, Color.WHITE)
	draw_eyes(Vector2(direction * 3.0, -11), 4.5, 3.5, true)


func _dome(w: float, h: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 21:
		var angle := PI + PI * i / 20.0
		points.append(Vector2(cos(angle) * w, sin(angle) * h))
	return points
