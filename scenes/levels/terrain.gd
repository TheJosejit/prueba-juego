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


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED # para el grano


## Color de relleno según la profundidad (cuántas casillas de suelo hay encima): más oscuro abajo.
func _fill_color(d: float) -> Color:
	if d < 2.0:
		return (theme.fill as Color).lerp(theme.fill_dark, d / 2.0)
	return (theme.fill_dark as Color).lerp(theme.fill_deep, clampf((d - 2.0) / 2.0, 0.0, 1.0))


func _draw() -> void:
	var style: String = theme.get("style", "grass")
	var grain_strength := {"grass": 0.3, "rock": 0.35, "stone": 0.2, "cloud": 0.08}.get(style, 0.25) as float
	for cell: Vector2i in cells:
		var pos := Vector2(cell) * TILE
		var rect := Rect2(pos, Vector2(TILE, TILE))
		var d: float = depth.get(cell, 0)
		var fill := _fill_color(d)
		var h := _hash(cell)
		DrawKit.gradient_fill(self, PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end,
			Vector2(rect.position.x, rect.end.y)]), fill, _fill_color(d + 1.0))
		match style:
			"stone": # sillares de piedra con relieve
				draw_rect(rect, fill.darkened(0.4))
				for row in 2:
					var y := pos.y + row * 16.0
					var xs := [0.0, 16.0, 32.0] if (cell.y + row) % 2 == 0 else [0.0, 8.0, 24.0, 32.0]
					for k in xs.size() - 1:
						var stone_rect := Rect2(pos.x + xs[k] + 0.8, y + 0.8, xs[k + 1] - xs[k] - 1.6, 14.4)
						DrawKit.gradient_fill(self, DrawKit.rounded_rect(stone_rect, 2.5), fill.lightened(0.1), fill.darkened(0.12))
						draw_line(stone_rect.position + Vector2(2, 1), Vector2(stone_rect.end.x - 2, stone_rect.position.y + 1), Color(1, 1, 1, 0.15), 1.0)
			"cloud": # bultos esponjosos
				var puff := pos + Vector2(8 + h % 16, 13 + h % 11)
				DrawKit.gradient_fill(self, DrawKit.circle(puff, 7.0, 16), fill.lightened(0.6), fill)
				DrawKit.gradient_fill(self, DrawKit.circle(puff + Vector2(9, 4), 4.5, 14), fill.lightened(0.5), fill)
			_:
				if h % 3 == 0: # piedrecita con brillo
					var stone := pos + Vector2(6 + h % 18, 15 + h % 11)
					var radii := Vector2(2.6 + h % 2, 1.9)
					draw_colored_polygon(DrawKit.ellipse(stone + Vector2(0, 1), radii, 12), Color(0, 0, 0, 0.18))
					DrawKit.gradient_fill(self, DrawKit.ellipse(stone, radii, 12), fill.lightened(0.35), fill.lightened(0.05))
					draw_circle(stone + Vector2(-0.8, -0.7), 0.7, Color(1, 1, 1, 0.45))
				draw_circle(pos + Vector2(4 + (h >> 4) % 22, 5 + (h >> 3) % 9), 1.2, fill.darkened(0.25))
		DrawKit.grain(self, rect, grain_strength)
		# Laterales y parte inferior expuestos: sombra suave hacia dentro
		var shade := Color(0, 0, 0, 0.32)
		var clear := Color(0, 0, 0, 0)
		if not cells.has(cell + Vector2i.LEFT):
			draw_polygon(PackedVector2Array([pos, pos + Vector2(6, 0), pos + Vector2(6, TILE), pos + Vector2(0, TILE)]),
				PackedColorArray([shade, clear, clear, shade]))
		if not cells.has(cell + Vector2i.RIGHT):
			draw_polygon(PackedVector2Array([pos + Vector2(TILE - 6, 0), pos + Vector2(TILE, 0), pos + Vector2(TILE, TILE), pos + Vector2(TILE - 6, TILE)]),
				PackedColorArray([clear, shade, shade, clear]))
		if not cells.has(cell + Vector2i.DOWN):
			draw_polygon(PackedVector2Array([pos + Vector2(0, TILE - 6), pos + Vector2(TILE, TILE - 6), pos + Vector2(TILE, TILE), pos + Vector2(0, TILE)]),
				PackedColorArray([clear, clear, shade, shade]))
		if not cells.has(cell + Vector2i.UP):
			_draw_top(pos, cell, style)


func _is_top(cell: Vector2i) -> bool:
	return cells.has(cell) and not cells.has(cell + Vector2i.UP)


func _draw_top(pos: Vector2, cell: Vector2i, style: String) -> void:
	var top: Color = theme.top
	var top_dark: Color = theme.top_dark
	match style:
		"grass":
			# Capa de hierba con el borde inferior ondulado, que "cuelga" sobre la tierra
			var edge := PackedVector2Array()
			for i in 17:
				var x := i * 2.0
				edge.append(pos + Vector2(x, 8.5 + 2.4 * absf(sin((pos.x + x) * PI / 8.0))))
			var shadow := edge.duplicate()
			for i in shadow.size():
				shadow[i].y += 2.5
			draw_polyline(shadow, Color(0, 0, 0, 0.2), 3.0, true)
			var lip := PackedVector2Array([pos + Vector2(0, -1), pos + Vector2(TILE, -1)])
			var reversed := edge.duplicate()
			reversed.reverse()
			lip.append_array(reversed)
			DrawKit.gradient_fill(self, lip, top.lightened(0.18), top_dark)
			draw_polyline(edge, top_dark.darkened(0.2), 1.0, true)
			draw_line(pos + Vector2(0, 0.5), pos + Vector2(TILE, 0.5), Color(1, 1, 1, 0.35), 1.2)
			# Extremos redondeados donde termina el césped
			for side in [-1, 1]:
				if not _is_top(cell + Vector2i(side, 0)):
					var cap := pos + Vector2(0.0 if side < 0 else float(TILE), 5.0)
					DrawKit.shape(self, DrawKit.circle(cap, 5.5, 14), top.lightened(0.15), top_dark, 1.2)
		"stone", "rock":
			# Borde superior irregular (piedra desgastada o roca volcánica)
			var edge := PackedVector2Array()
			for i in 9:
				var x := i * 4.0
				var bump := float(_hash(Vector2i(int(pos.x + x), cell.y)) % 3)
				edge.append(pos + Vector2(x, 6.0 + bump * (0.8 if style == "stone" else 1.3)))
			var shadow := edge.duplicate()
			for i in shadow.size():
				shadow[i].y += 2.0
			draw_polyline(shadow, Color(0, 0, 0, 0.25), 2.5, true)
			var lip := PackedVector2Array([pos, pos + Vector2(TILE, 0)])
			var reversed := edge.duplicate()
			reversed.reverse()
			lip.append_array(reversed)
			DrawKit.gradient_fill(self, lip, top.lightened(0.15), top_dark)
			draw_line(pos + Vector2(0, 0.6), pos + Vector2(TILE, 0.6), Color(1, 1, 1, 0.3), 1.2)
			if style == "rock": # brillo rojizo de la lava cercana
				draw_line(pos + Vector2(0, 0.6), pos + Vector2(TILE, 0.6), Color(theme.lava_light, 0.25), 1.0)
		"cloud":
			for i in 3:
				draw_circle(pos + Vector2(5 + i * 11, 6.5), 8.0, top_dark)
			for i in 3:
				var c := pos + Vector2(5 + i * 11, 4)
				DrawKit.gradient_fill(self, DrawKit.circle(c, 8.0, 18), Color.WHITE, top.lerp(top_dark, 0.5))
			DrawKit.gradient_fill(self, PackedVector2Array([pos + Vector2(0, 4), pos + Vector2(TILE, 4), pos + Vector2(TILE, 11), pos + Vector2(0, 11)]),
				top.lerp(top_dark, 0.4), top_dark)
			draw_circle(pos + Vector2(8, 0), 2.0, Color(1, 1, 1, 0.9))


func _hash(cell: Vector2i) -> int:
	return absi((cell.x * 73856093) ^ (cell.y * 19349663)) % 65536
