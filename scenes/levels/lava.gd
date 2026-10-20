extends Area2D
## Lava (casillas "L" del mapa): tocarla es muerte segura, aunque se tenga una mejora.

const TILE := 32
const SURFACE := 10.0 # la superficie peligrosa empieza un poco por debajo del borde

var theme := {}
var cells := {}
var anim_time := 0.0


func add_cell(cell: Vector2i) -> void:
	cells[cell] = true


func build() -> void:
	collision_layer = 0
	collision_mask = 2
	for cell: Vector2i in cells:
		var top := not cells.has(cell + Vector2i.UP)
		var shape := RectangleShape2D.new()
		shape.size = Vector2(TILE, TILE - (SURFACE if top else 0.0))
		var collision := CollisionShape2D.new()
		collision.shape = shape
		collision.position = Vector2(cell.x + 0.5, cell.y + 0.5) * TILE + Vector2(0, (SURFACE / 2.0 if top else 0.0))
		add_child(collision)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("die"):
		body.die()


func _process(delta: float) -> void:
	anim_time += delta
	if not cells.is_empty():
		queue_redraw()


func _draw() -> void:
	var lava: Color = theme.get("lava", Color("ff6a14"))
	var light: Color = theme.get("lava_light", Color("ffd04a"))
	for cell: Vector2i in cells:
		var pos := Vector2(cell) * TILE
		if cells.has(cell + Vector2i.UP):
			draw_rect(Rect2(pos, Vector2(TILE, TILE)), lava.darkened(0.15))
			continue
		# Resplandor sobre la superficie
		for k in 4:
			draw_rect(Rect2(pos + Vector2(0, 6 - (k + 1) * 5), Vector2(TILE, 5)), Color(lava, 0.16 - k * 0.04))
		var surface := PackedVector2Array()
		for i in 9:
			var x := pos.x + i * 4.0
			surface.append(Vector2(x, pos.y + 6.0 + sin(anim_time * 3.0 + x * 0.15) * 2.0))
		var body := surface.duplicate()
		body.append(pos + Vector2(TILE, TILE))
		body.append(pos + Vector2(0, TILE))
		draw_colored_polygon(body, lava)
		draw_polyline(surface, light, 2.5, true)
		# Burbujas
		var phase := fmod(anim_time * 0.7 + cell.x * 0.37, 1.0)
		if phase < 0.5:
			draw_circle(pos + Vector2(8 + (cell.x * 7) % 16, 12 - phase * 8.0), 2.5 * (1.0 - phase), light)
