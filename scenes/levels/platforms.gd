extends StaticBody2D
## Plataformas fijas (casillas "=" del mapa). Se pueden atravesar saltando desde abajo.

const TILE := 32
const THICKNESS := 12.0

var theme := {}
var cells := {}
var runs: Array[Rect2] = [] # tramos horizontales, para dibujarlos


func add_cell(cell: Vector2i) -> void:
	cells[cell] = true


func build() -> void:
	var by_row := {}
	for cell: Vector2i in cells:
		if not by_row.has(cell.y):
			by_row[cell.y] = []
		by_row[cell.y].append(cell.x)
	for y: int in by_row:
		var xs: Array = by_row[y]
		xs.sort()
		var start: int = xs[0]
		var prev: int = start
		for i in range(1, xs.size() + 1):
			if i < xs.size() and xs[i] == prev + 1:
				prev = xs[i]
				continue
			_add_run(start, prev, y)
			if i < xs.size():
				start = xs[i]
				prev = start
	queue_redraw()


func _add_run(x0: int, x1: int, y: int) -> void:
	var rect := Rect2(x0 * TILE, y * TILE, (x1 - x0 + 1) * TILE, THICKNESS)
	runs.append(rect)
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = rect.get_center()
	collision.one_way_collision = true
	add_child(collision)


func _draw() -> void:
	var plank: Color = theme.get("plank", Color("c98a4b"))
	var plank_dark: Color = theme.get("plank_dark", Color("7d5229"))
	var cloud: bool = theme.get("style", "") == "cloud"
	for rect in runs:
		if not cloud: # soportes bajo la tabla
			for sx in [rect.position.x + 5.0, rect.end.x - 10.0]:
				var support := DrawKit.rounded_rect(Rect2(sx, rect.end.y - 2.0, 5, 10), 1.5)
				DrawKit.shape(self, support, plank_dark.lightened(0.1), plank_dark.darkened(0.2), 1.2)
		DrawKit.plank(self, rect, plank, plank_dark, cloud)
