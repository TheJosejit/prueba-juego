extends StaticBody2D
## Suelo del nivel (las casillas "#" del mapa): colisiones y dibujo.

const TILE := 32
const GRASS := Color("5cc85c")
const GRASS_DARK := Color("3c9a48")
const DIRT := Color("b5734a")
const DIRT_DARK := Color("8f5536")

var cells := {}


func add_cell(cell: Vector2i) -> void:
	cells[cell] = true


func build() -> void:
	# Una forma de colisión por cada tramo horizontal: menos formas y sin tropiezos entre casillas.
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
			_add_shape(start, prev, y)
			if i < xs.size():
				start = xs[i]
				prev = start
	queue_redraw()


func _add_shape(x0: int, x1: int, y: int) -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2((x1 - x0 + 1) * TILE, TILE)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2((x0 + x1 + 1) * TILE / 2.0, (y + 0.5) * TILE)
	add_child(collision)


func _draw() -> void:
	for cell: Vector2i in cells:
		var pos := Vector2(cell) * TILE
		draw_rect(Rect2(pos, Vector2(TILE, TILE)), DIRT)
		if (cell.x + cell.y) % 2 == 0:
			draw_rect(Rect2(pos + Vector2(6, 18), Vector2(6, 4)), DIRT_DARK)
		else:
			draw_rect(Rect2(pos + Vector2(20, 8), Vector2(5, 4)), DIRT_DARK)
		if not cells.has(cell + Vector2i.UP):
			draw_rect(Rect2(pos, Vector2(TILE, 10)), GRASS)
			draw_rect(Rect2(pos + Vector2(0, 10), Vector2(TILE, 3)), GRASS_DARK)
