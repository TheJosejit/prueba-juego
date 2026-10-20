extends Node2D
## Decorado de fondo (colinas y nubes). Va dentro de un Parallax2D para moverse más lento.

var width := 2000.0:
	set(value):
		width = value
		queue_redraw()
var ground_y := 416.0


func _draw() -> void:
	var x := -80.0
	var i := 0
	while x < width:
		var radius := 60.0 + (i * 37) % 70
		draw_circle(Vector2(x, ground_y + 30), radius, Color("7cc982") if i % 2 == 0 else Color("94d69a"))
		x += 140.0 + (i * 53) % 120
		i += 1
	# Tapa la parte de las colinas bajo el suelo, que se vería por los huecos.
	draw_rect(Rect2(-100, ground_y, width + 200, 1000), Level.SKY_COLOR)

	x = 40.0
	i = 0
	while x < width:
		var y := 50.0 + (i * 41) % 90
		for puff in [Vector2(0, 0), Vector2(18, -10), Vector2(36, 0), Vector2(18, 6)]:
			draw_circle(Vector2(x, y) + puff, 16.0, Color(1, 1, 1, 0.9))
		x += 220.0 + (i * 71) % 160
		i += 1
