extends Node2D
## Decorado de fondo. Cada nivel crea tres capas (lejana, cercana y nubes), cada una dentro de un
## Parallax2D que la mueve más despacio que el nivel. Lo que se dibuja depende del tema.

enum Layer { FAR, NEAR, CLOUDS }

var layer := Layer.NEAR
var theme: Dictionary = Themes.MEADOW
var width := 2000.0:
	set(value):
		width = value
		queue_redraw()
var ground_y := 416.0
var anim_time := 0.0


func _ready() -> void:
	var style: String = theme.style
	set_process(layer == Layer.CLOUDS and style == "rock" or layer == Layer.NEAR and style == "stone")


func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234 + layer * 77
	var style: String = theme.style
	match layer:
		Layer.FAR:
			_draw_far(rng, style)
		Layer.NEAR:
			_draw_near(rng, style)
			if style != "cloud":
				# Tapa lo que queda bajo el suelo, que se vería por los huecos
				draw_rect(Rect2(-100, ground_y, width + 200, 2000), theme.sky_bottom)
		Layer.CLOUDS:
			_draw_clouds(rng, style)


func _draw_far(rng: RandomNumberGenerator, style: String) -> void:
	var far: Color = theme.far
	var light: Color = theme.far_light
	var x := -150.0
	match style:
		"grass", "rock":
			while x < width:
				var w := rng.randf_range(160, 280)
				var h := rng.randf_range(140, 230)
				var peak := Vector2(x + w / 2.0 + rng.randf_range(-30, 30), ground_y - h)
				draw_colored_polygon(PackedVector2Array([
					Vector2(x, ground_y + 40), peak, Vector2(x + w, ground_y + 40),
				]), far)
				if style == "grass":
					draw_colored_polygon(PackedVector2Array([
						peak, peak + Vector2(-h * 0.22, h * 0.25), peak + Vector2(-h * 0.05, h * 0.2),
						peak + Vector2(h * 0.08, h * 0.27), peak + Vector2(h * 0.2, h * 0.24),
					]), light)
				else: # cima incandescente
					draw_colored_polygon(PackedVector2Array([
						peak, peak + Vector2(-h * 0.08, h * 0.12), peak + Vector2(h * 0.08, h * 0.12),
					]), Color(light, 0.5))
				x += w * 0.6
		"stone":
			while x < width: # estalactitas y columnas
				var w := rng.randf_range(30, 70)
				var h := rng.randf_range(80, 200)
				draw_colored_polygon(PackedVector2Array([
					Vector2(x, -200), Vector2(x + w, -200), Vector2(x + w / 2.0, -200 + h + 200),
				]), far)
				if rng.randf() < 0.4:
					var ch := rng.randf_range(120, 260)
					draw_rect(Rect2(x + w, ground_y + 40 - ch, w * 0.8, ch), light)
				x += w + rng.randf_range(20, 80)
		"cloud":
			draw_circle(Vector2(width * 0.15 + 200, 70), 40.0, Color(1, 0.97, 0.8, 0.9)) # sol
			draw_circle(Vector2(width * 0.15 + 200, 70), 52.0, Color(1, 0.95, 0.7, 0.25))
			while x < width:
				var r := rng.randf_range(40, 80)
				draw_circle(Vector2(x, ground_y + rng.randf_range(-40, 20)), r, far)
				x += r * 1.2


func _draw_near(rng: RandomNumberGenerator, style: String) -> void:
	var near: Color = theme.near
	var near_alt: Color = theme.near_alt
	var x := -80.0
	var i := 0
	match style:
		"grass":
			while x < width:
				var radius := rng.randf_range(60, 130)
				draw_circle(Vector2(x, ground_y + 30), radius, near if i % 2 == 0 else near_alt)
				if rng.randf() < 0.6: # árbol
					var tx := x + rng.randf_range(-radius * 0.5, radius * 0.5)
					var ty := ground_y + 30 - sqrt(maxf(radius * radius - pow(tx - x, 2), 0.0))
					draw_rect(Rect2(tx - 3, ty - 26, 6, 28), Color("6b4a2f"))
					draw_circle(Vector2(tx, ty - 32), 15.0, near.darkened(0.15))
					draw_circle(Vector2(tx - 6, ty - 38), 9.0, near.darkened(0.05))
				x += rng.randf_range(140, 260)
				i += 1
		"stone":
			while x < width:
				var h := rng.randf_range(60, 180)
				var w := rng.randf_range(40, 90)
				draw_colored_polygon(PackedVector2Array([
					Vector2(x, ground_y + 40), Vector2(x + w * 0.3, ground_y - h), Vector2(x + w * 0.7, ground_y - h * 0.8),
					Vector2(x + w, ground_y + 40),
				]), near if i % 2 == 0 else near_alt)
				if rng.randf() < 0.7: # cristales que brillan
					var glow := 0.6 + sin(anim_time * 2.0 + i) * 0.25
					var cx := x + w * 0.5
					var color: Color = theme.crystal if i % 2 == 0 else theme.crystal_alt
					draw_circle(Vector2(cx, ground_y - 6), 22.0, Color(color, 0.12 * glow))
					for k in 3:
						var base := Vector2(cx + (k - 1) * 8.0, ground_y + 4)
						var tall := rng.randf_range(14, 30)
						draw_colored_polygon(PackedVector2Array([
							base + Vector2(-4, 0), base + Vector2((k - 1) * 4.0, -tall), base + Vector2(4, 0),
						]), Color(color, glow))
				x += w + rng.randf_range(30, 120)
				i += 1
		"cloud":
			while x < width: # mar de nubes
				var r := rng.randf_range(40, 70)
				draw_circle(Vector2(x, ground_y + 70), r, near_alt)
				draw_circle(Vector2(x + 20, ground_y + 60), r * 0.8, near)
				x += r
			draw_rect(Rect2(-100, ground_y + 80, width + 200, 2000), near)
		"rock":
			while x < width:
				var h := rng.randf_range(50, 140)
				var w := rng.randf_range(50, 110)
				var pts := PackedVector2Array([Vector2(x, ground_y + 40)])
				for k in 4:
					pts.append(Vector2(x + w * (k + 0.5) / 4.0, ground_y - h * rng.randf_range(0.5, 1.0)))
				pts.append(Vector2(x + w, ground_y + 40))
				draw_colored_polygon(pts, near if i % 2 == 0 else near_alt)
				x += w + rng.randf_range(10, 80)
				i += 1


func _draw_clouds(rng: RandomNumberGenerator, style: String) -> void:
	var color: Color = theme.clouds
	if color.a <= 0.0:
		return
	var x := 40.0
	while x < width:
		var y := rng.randf_range(20, 160)
		var s := rng.randf_range(0.8, 1.6)
		for puff in [Vector2(0, 0), Vector2(18, -10), Vector2(36, 0), Vector2(18, 6), Vector2(-14, 4)]:
			draw_circle(Vector2(x, y) + puff * s, 16.0 * s, color)
		x += rng.randf_range(160, 320) * (0.6 if style == "cloud" else 1.0)
	if style == "rock": # brasas que suben
		for k in 40:
			var bx := fmod(rng.randf_range(0, width) + anim_time * 8.0, width)
			var by := ground_y + 40 - fmod(rng.randf_range(0, 400) + anim_time * rng.randf_range(20, 50), 420)
			draw_circle(Vector2(bx, by), rng.randf_range(1.0, 2.2), Color(1, rng.randf_range(0.4, 0.8), 0.1, 0.8))
