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
	var deep := lava.darkened(0.45)
	for cell: Vector2i in cells:
		var pos := Vector2(cell) * TILE
		if cells.has(cell + Vector2i.UP):
			DrawKit.gradient_fill(self, PackedVector2Array([pos, pos + Vector2(TILE, 0), pos + Vector2(TILE, TILE), pos + Vector2(0, TILE)]),
				lava.lerp(deep, 0.5), deep)
			continue
		# Resplandor sobre la superficie
		draw_polygon(PackedVector2Array([pos + Vector2(0, -16), pos + Vector2(TILE, -16), pos + Vector2(TILE, 8), pos + Vector2(0, 8)]),
			PackedColorArray([Color(lava, 0.0), Color(lava, 0.0), Color(lava, 0.3), Color(lava, 0.3)]))
		var surface := PackedVector2Array()
		for i in 17:
			var x := pos.x + i * 2.0
			surface.append(Vector2(x, pos.y + 6.0 + sin(anim_time * 3.0 + x * 0.15) * 2.0))
		var body := surface.duplicate()
		body.append(pos + Vector2(TILE, TILE))
		body.append(pos + Vector2(0, TILE))
		DrawKit.gradient_fill(self, body, light.lerp(lava, 0.35), lava.lerp(deep, 0.4))
		draw_polyline(surface, light, 2.5, true)
		draw_polyline(surface, Color(1, 1, 0.85, 0.7), 1.0, true)
		# Manchas de roca fundida que se mueven despacio
		var drift := fmod(anim_time * 6.0 + cell.x * 11.0, 32.0)
		draw_colored_polygon(DrawKit.ellipse(pos + Vector2(drift, 18 + (cell.x % 3) * 3), Vector2(4.0, 1.6), 10), Color(deep, 0.5))
		# Burbujas
		var phase := fmod(anim_time * 0.7 + cell.x * 0.37, 1.0)
		if phase < 0.5:
			var bubble := pos + Vector2(8 + (cell.x * 7) % 16, 12 - phase * 8.0)
			var r := 2.8 * (1.0 - phase)
			DrawKit.gradient_fill(self, DrawKit.circle(bubble, r, 12), Color(1, 1, 0.85), light)
			draw_circle(bubble + Vector2(-r * 0.35, -r * 0.35), r * 0.3, Color.WHITE)
