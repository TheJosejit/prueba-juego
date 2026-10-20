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
	var clouds: Color = theme.clouds
	# Solo se redibujan cada fotograma las capas que se animan
	var animated_clouds := layer == Layer.CLOUDS and (clouds.a > 0.0 or style == "rock")
	var animated_near := layer == Layer.NEAR and style in ["stone", "grass"]
	set_process(animated_clouds or animated_near)


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
				var base_left := Vector2(x, ground_y + 40)
				var base_right := Vector2(x + w, ground_y + 40)
				var haze: Color = far.lerp(theme.sky_bottom, 0.55) # neblina: la base se funde con el cielo
				DrawKit.gradient_fill(self, PackedVector2Array([base_left, peak, base_right]), far, haze)
				# Ladera en sombra (lado derecho)
				draw_polygon(PackedVector2Array([peak, base_right, peak.lerp(base_right, 0.5) + Vector2(-w * 0.12, 0)]),
					PackedColorArray([Color(0, 0, 0, 0.12), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.06)]))
				if style == "grass":
					var snow := PackedVector2Array([
						peak, peak + Vector2(h * 0.2, h * 0.24), peak + Vector2(h * 0.08, h * 0.27),
						peak + Vector2(-h * 0.05, h * 0.2), peak + Vector2(-h * 0.22, h * 0.25),
					])
					DrawKit.gradient_fill(self, snow, Color.WHITE, light)
					draw_colored_polygon(PackedVector2Array([peak, peak + Vector2(h * 0.2, h * 0.24), peak + Vector2(h * 0.08, h * 0.27)]),
						Color(0.6, 0.75, 0.9, 0.35)) # cara en sombra de la nieve
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
				var hill: Color = near if i % 2 == 0 else near_alt
				var center := Vector2(x, ground_y + 30)
				DrawKit.gradient_fill(self, DrawKit.circle(center, radius, 40), hill.lightened(0.1), hill.darkened(0.15))
				draw_arc(center, radius - 4.0, PI * 1.2, PI * 1.4, 12, Color(1, 1, 1, 0.12), 4.0, true)
				if rng.randf() < 0.6: # árbol
					var tx := x + rng.randf_range(-radius * 0.5, radius * 0.5)
					var ty := ground_y + 30 - sqrt(maxf(radius * radius - pow(tx - x, 2), 0.0))
					var sway := sin(anim_time * 1.3 + tx * 0.02) * 2.0
					var trunk := DrawKit.rounded_rect(Rect2(tx - 3, ty - 26, 6, 28), 2.0)
					DrawKit.gradient_fill(self, trunk, Color("8a5f3c"), Color("5a3b22"))
					var leaves: Color = near.darkened(0.12)
					for blob in [[Vector2(-7, -30), 10.0], [Vector2(7, -31), 10.0], [Vector2(0, -40), 12.0]]:
						var c: Vector2 = Vector2(tx + sway, ty) + blob[0]
						DrawKit.gradient_fill(self, DrawKit.circle(c, blob[1], 20), leaves.lightened(0.15), leaves.darkened(0.15))
					DrawKit.shine(self, Vector2(tx - 4 + sway, ty - 45), Vector2(4, 2.5), 0.3)
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
		var cx := fmod(x + anim_time * 5.0 * s, width + 300.0) - 150.0 # se desplazan despacio
		var puffs := [Vector2(0, 0), Vector2(18, -10), Vector2(36, 0), Vector2(18, 6), Vector2(-14, 4)]
		var underside := Color(color.r * 0.9, color.g * 0.94, color.b * 1.0, color.a) # base de la nube en sombra
		for puff in puffs:
			draw_circle(Vector2(cx, y + 3.0 * s) + puff * s, 15.5 * s, underside)
		for puff in puffs:
			draw_circle(Vector2(cx, y) + puff * s, 15.0 * s, color)
		draw_circle(Vector2(cx + 14.0 * s, y - 14.0 * s), 6.0 * s, Color(1, 1, 1, 0.6 * color.a))
		x += rng.randf_range(160, 320) * (0.6 if style == "cloud" else 1.0)
	if style == "rock": # brasas que suben
		for k in 40:
			var bx := fmod(rng.randf_range(0, width) + anim_time * 8.0, width)
			var by := ground_y + 40 - fmod(rng.randf_range(0, 400) + anim_time * rng.randf_range(20, 50), 420)
			draw_circle(Vector2(bx, by), rng.randf_range(1.0, 2.2), Color(1, rng.randf_range(0.4, 0.8), 0.1, 0.8))
