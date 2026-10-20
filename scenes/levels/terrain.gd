extends StaticBody2D
## Suelo del nivel (las casillas "#" del mapa): colisiones y dibujo según el tema del nivel.
## Estilos: "grass" (hierba), "stone" (piedra), "cloud" (nube) y "rock" (roca volcánica).
## Los detalles animados (hierba, flores, cristales, grietas) están en decor.gd.

const TILE := 32

var theme := {}
var cells := {}
var depth := {} # cuántas casillas de suelo hay encima de cada una (para oscurecer lo profundo)


func add_cell(cell: Vector2i) -> void:
	cells[cell] = true


func build() -> void:
	# Una forma de colisión por cada tramo horizontal: menos formas y sin tropiezos entre casillas.
	var by_row := {}
	for cell: Vector2i in cells:
		if not by_row.has(cell.y):
			by_row[cell.y] = []
		by_row[cell.y].append(cell.x)
		var d := 0
		while d < 4 and cells.has(cell - Vector2i(0, d + 1)):
			d += 1
		depth[cell] = d
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
	var style: String = theme.get("style", "grass")
	for cell: Vector2i in cells:
		var pos := Vector2(cell) * TILE
		var d: int = depth.get(cell, 0)
		var fill: Color = theme.fill if d < 2 else (theme.fill_dark if d < 4 else theme.fill_deep)
		var h := _hash(cell)
		draw_rect(Rect2(pos, Vector2(TILE, TILE)), fill)
		match style:
			"stone":
				var mortar: Color = fill.darkened(0.3)
				draw_line(pos + Vector2(0, 16), pos + Vector2(TILE, 16), mortar, 2.0)
				var off := 8.0 if cell.y % 2 == 0 else 24.0
				draw_line(pos + Vector2(off, 0), pos + Vector2(off, 16), mortar, 2.0)
				draw_line(pos + Vector2(fmod(off + 16.0, 32.0), 16), pos + Vector2(fmod(off + 16.0, 32.0), 32), mortar, 2.0)
				draw_rect(Rect2(pos + Vector2(2, 2), Vector2(10, 2)), fill.lightened(0.12))
			"cloud":
				draw_circle(pos + Vector2(8 + h % 16, 12 + h % 11), 6.0, fill.lightened(0.4))
			_:
				# Motas en la tierra o la roca
				draw_rect(Rect2(pos + Vector2(4 + h % 20, 14 + h % 13), Vector2(5, 3)), fill.darkened(0.2))
				draw_rect(Rect2(pos + Vector2(4 + (h >> 4) % 20, 4 + (h >> 3) % 10), Vector2(3, 3)), fill.lightened(0.12))
		# Laterales y parte inferior expuestos: más oscuros, para que los bloques se lean bien
		if not cells.has(cell + Vector2i.LEFT):
			draw_rect(Rect2(pos, Vector2(3, TILE)), fill.darkened(0.3))
		if not cells.has(cell + Vector2i.RIGHT):
			draw_rect(Rect2(pos + Vector2(TILE - 3, 0), Vector2(3, TILE)), fill.darkened(0.3))
		if not cells.has(cell + Vector2i.DOWN):
			draw_rect(Rect2(pos + Vector2(0, TILE - 4), Vector2(TILE, 4)), fill.darkened(0.35))
		if not cells.has(cell + Vector2i.UP):
			_draw_top(pos, h, style)


func _draw_top(pos: Vector2, _h: int, style: String) -> void:
	var top: Color = theme.top
	var top_dark: Color = theme.top_dark
	match style:
		"grass":
			draw_rect(Rect2(pos, Vector2(TILE, 10)), top)
			draw_rect(Rect2(pos + Vector2(0, 10), Vector2(TILE, 3)), top_dark)
			draw_rect(Rect2(pos, Vector2(TILE, 2)), top.lightened(0.25))
		"stone":
			draw_rect(Rect2(pos, Vector2(TILE, 6)), top)
			draw_rect(Rect2(pos + Vector2(0, 6), Vector2(TILE, 2)), top_dark)
			draw_rect(Rect2(pos, Vector2(TILE, 1.5)), top.lightened(0.3))
		"cloud":
			for i in 3:
				draw_circle(pos + Vector2(5 + i * 11, 4), 8.0, top)
			draw_rect(Rect2(pos + Vector2(0, 4), Vector2(TILE, 6)), top)
			draw_rect(Rect2(pos + Vector2(0, 10), Vector2(TILE, 2)), top_dark)
		"rock":
			draw_rect(Rect2(pos, Vector2(TILE, 6)), top)
			draw_rect(Rect2(pos + Vector2(0, 6), Vector2(TILE, 2)), top_dark)
			draw_rect(Rect2(pos, Vector2(TILE, 1.5)), top.lightened(0.2))


func _hash(cell: Vector2i) -> int:
	return absi((cell.x * 73856093) ^ (cell.y * 19349663)) % 65536
