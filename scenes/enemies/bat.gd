extends Enemy
## Murciélago: vuela de un lado a otro ondulando, atravesando paredes. Se puede pisar.

const SPEED := 60.0
const RANGE := 96.0 # distancia que recorre a cada lado de su posición inicial
const BODY := Color("4b3b6b")
const WING := Color("6c5a96")
const BELLY := Color("9d8cc4")

var origin := Vector2.ZERO
var fly_time := 0.0


func _ready() -> void:
	super()
	points = 250
	squash_on_stomp = false
	burst_color = WING
	origin = position


func _move(delta: float) -> void:
	fly_time += delta
	var x := position.x + direction * SPEED * delta
	if absf(x - origin.x) > RANGE:
		direction = -direction
	position = Vector2(x, origin.y + sin(fly_time * 3.0) * 14.0)


func _draw_body() -> void:
	var flap := sin(anim_time * 18.0)
	var center := Vector2(0, -14)
	for side in [-1.0, 1.0]:
		var wing := PackedVector2Array([
			center + Vector2(side * 4.0, -2),
			center + Vector2(side * 18.0, -6 - flap * 8.0),
			center + Vector2(side * 14.0, 0 - flap * 3.0),
			center + Vector2(side * 10.0, 4 - flap * 2.0),
			center + Vector2(side * 4.0, 4),
		])
		var outline := wing.duplicate()
		outline.append(wing[0])
		draw_colored_polygon(wing, WING)
		draw_polyline(outline, OUTLINE, 1.5, true)
	draw_circle(center, 8.5, OUTLINE)
	draw_circle(center, 7.0, BODY)
	draw_circle(center + Vector2(0, 3), 4.0, BELLY)
	# Orejas
	for side in [-1.0, 1.0]:
		var ear := PackedVector2Array([
			center + Vector2(side * 2.0, -6), center + Vector2(side * 6.0, -12), center + Vector2(side * 7.0, -4),
		])
		draw_colored_polygon(ear, BODY)
	draw_eyes(center + Vector2(direction * 1.5, -1), 3.0, 2.3)
	draw_line(center + Vector2(-1.5, 3.5), center + Vector2(-1.0, 6), Color.WHITE, 1.2)
	draw_line(center + Vector2(1.5, 3.5), center + Vector2(1.0, 6), Color.WHITE, 1.2)
