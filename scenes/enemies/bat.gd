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
	has_shadow = false
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
		# Ala de membrana con "dedos"
		var wing := PackedVector2Array([
			center + Vector2(side * 4.0, -2),
			center + Vector2(side * 12.0, -7 - flap * 6.0),
			center + Vector2(side * 19.0, -6 - flap * 8.0),
			center + Vector2(side * 16.0, 0 - flap * 4.0),
			center + Vector2(side * 12.5, 2 - flap * 2.5),
			center + Vector2(side * 9.0, 3 - flap * 1.5),
			center + Vector2(side * 4.0, 4),
		])
		DrawKit.shape(self, wing, WING.lightened(0.2), WING.darkened(0.25), 1.5)
		for k in [1, 3, 4]:
			draw_line(center + Vector2(side * 4.0, -1), wing[k], Color(BODY.darkened(0.2), 0.8), 1.0, true)
	# Orejas con el interior rosado
	for side in [-1.0, 1.0]:
		var ear := PackedVector2Array([center + Vector2(side * 1.5, -6), center + Vector2(side * 6.0, -13), center + Vector2(side * 7.0, -4)])
		DrawKit.shape(self, ear, BODY.lightened(0.2), BODY, 1.2)
		draw_colored_polygon(PackedVector2Array([center + Vector2(side * 3.0, -6.5), center + Vector2(side * 5.8, -10.5), center + Vector2(side * 6.0, -5.5)]), Color("ff9fc0"))
	# Cuerpo
	DrawKit.shape(self, DrawKit.circle(center, 7.0, 20), BODY.lightened(0.2), BODY.darkened(0.2), 1.6)
	DrawKit.gradient_fill(self, DrawKit.ellipse(center + Vector2(0, 3), Vector2(4.0, 3.2), 14), BELLY.lightened(0.2), BELLY)
	DrawKit.shine(self, center + Vector2(-3, -4), Vector2(1.8, 1.2), 0.5)
	draw_eyes(center + Vector2(direction * 1.5, -1), 3.0, 2.3)
	for side in [-1.5, 1.5]: # colmillos
		draw_colored_polygon(PackedVector2Array([center + Vector2(side - 0.8, 3.5), center + Vector2(side + 0.8, 3.5), center + Vector2(side, 6.0)]), Color.WHITE)
