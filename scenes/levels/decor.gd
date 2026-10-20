extends Node2D
## Detalles animados sobre el suelo: hierba que se mece (y se aparta cuando pasa Pip), flores,
## cristales que brillan y grietas de lava que laten. Solo se dibuja lo que está en pantalla.

const TILE := 32
const PETALS := [Color("ffffff"), Color("ffd23f"), Color("ff7eb6"), Color("9ad7ff")]

var theme := {}
var player: Node2D
var anim_time := 0.0
var _items: Array = [] # [tipo, posición, semilla], ordenados por x para dibujar solo lo visible
var _xs := PackedFloat32Array() # la x de cada detalle, para buscar rápido el primero visible


## Recibe las casillas de suelo del nivel y decide dónde va cada detalle.
func setup(cells: Dictionary) -> void:
	var style: String = theme.get("style", "grass")
	for cell: Vector2i in cells:
		var h := absi((cell.x * 73856093) ^ (cell.y * 19349663)) % 65536
		var pos := Vector2(cell) * TILE
		var top := not cells.has(cell + Vector2i.UP)
		match style:
			"grass":
				if top:
					for i in 4:
						_items.append(["blade", pos + Vector2(3.0 + i * 8.0 + (h >> i) % 3, 1.0), h >> (i + 2)])
					if h % 6 == 0:
						_items.append(["flower", pos + Vector2(10 + h % 12, 0), h])
			"stone":
				if top and h % 5 == 0:
					_items.append(["crystal", pos + Vector2(8 + h % 16, 0), h])
			"rock":
				if h % 5 == 0:
					_items.append(["crack", pos, h])
	_items.sort_custom(func(a: Array, b: Array) -> bool: return a[1].x < b[1].x)
	for item in _items:
		_xs.append(item[1].x)


func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()


func _draw() -> void:
	if _items.is_empty():
		return
	var view := get_viewport().get_canvas_transform().affine_inverse() * get_viewport_rect()
	var left := view.position.x - 40.0
	var right := view.end.x + 40.0
	var near := player.global_position if is_instance_valid(player) else Vector2(-99999, 0)
	var start := _xs.bsearch(left)
	var top: Color = theme.get("top", Color.GREEN)
	for i in range(start, _items.size()):
		var item: Array = _items[i]
		var pos: Vector2 = item[1]
		if pos.x > right:
			break
		var salt: int = item[2]
		match item[0]:
			"blade":
				var sway := sin(anim_time * 2.2 + pos.x * 0.045) * 1.5
				var dx := pos.x - near.x
				if absf(dx) < 22.0 and absf(pos.y - near.y) < 24.0: # Pip la aparta al pasar
					sway += signf(dx) * (22.0 - absf(dx)) / 22.0 * 5.0
				var tip := pos + Vector2(sway, -5.0 - salt % 3)
				draw_colored_polygon(PackedVector2Array([pos + Vector2(-2, 0), tip, pos + Vector2(2, 0)]),
					top.lightened(0.08 * (salt % 3)))
			"flower":
				var bob := sin(anim_time * 2.0 + pos.x) * 1.2
				var head := pos + Vector2(bob, -7)
				draw_line(pos, head, top.darkened(0.3), 1.2)
				var petal: Color = PETALS[salt % PETALS.size()]
				for k in 5:
					var a := k * TAU / 5.0 + anim_time * 0.5
					draw_circle(head + Vector2(cos(a), sin(a)) * 2.2, 1.6, petal)
				draw_circle(head, 1.2, Color("ff9f1c"))
			"crystal":
				var glow := 0.65 + sin(anim_time * 2.5 + pos.x * 0.1) * 0.35
				var color: Color = theme.crystal if salt % 2 == 0 else theme.crystal_alt
				draw_circle(pos + Vector2(0, -4), 10.0, Color(color, 0.18 * glow))
				draw_colored_polygon(PackedVector2Array([pos + Vector2(-3.5, 0), pos + Vector2(0, -11), pos + Vector2(3.5, 0)]), Color(color, 0.6 + 0.4 * glow))
				draw_colored_polygon(PackedVector2Array([pos + Vector2(2, 0), pos + Vector2(6, -6), pos + Vector2(7, 0)]), Color(color, 0.5 + 0.4 * glow))
				draw_line(pos + Vector2(-1, -2), pos + Vector2(0, -9), Color(1, 1, 1, 0.6 * glow), 1.0)
			"crack":
				var pulse := 0.5 + sin(anim_time * 1.8 + salt) * 0.5
				var lava: Color = theme.lava
				var crack := PackedVector2Array([pos + Vector2(6, 26), pos + Vector2(12, 20), pos + Vector2(18, 23), pos + Vector2(25, 16)])
				draw_polyline(crack, Color(lava, 0.25 * pulse), 4.0, true)
				draw_polyline(crack, Color(theme.lava_light, 0.5 + 0.5 * pulse), 1.5, true)
