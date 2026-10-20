class_name DrawKit
## Utilidades de dibujo del estilo "cartoon pulido": formas con degradado, contornos,
## sombras de contacto, brillos y una textura de grano para dar textura a superficies.
## Todas reciben el CanvasItem en el que dibujar (normalmente "self" dentro de _draw()).

const OUTLINE := Color("2a1a14")

static var _grain: ImageTexture


# --- Formas (listas de puntos) ---

static func circle(center: Vector2, radius: float, segments := 24) -> PackedVector2Array:
	return ellipse(center, Vector2(radius, radius), segments)


static func ellipse(center: Vector2, radii: Vector2, segments := 24) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments:
		var a := TAU * i / segments
		points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	return points


## Rectángulo con esquinas redondeadas; top_radius y bottom_radius pueden ser distintos.
static func rounded_rect(rect: Rect2, top_radius: float, bottom_radius := -1.0, corner_segments := 5) -> PackedVector2Array:
	if bottom_radius < 0.0:
		bottom_radius = top_radius
	var points := PackedVector2Array()
	var corners := [
		[rect.position + Vector2(top_radius, top_radius), top_radius, PI],
		[Vector2(rect.end.x - top_radius, rect.position.y + top_radius), top_radius, PI * 1.5],
		[rect.end - Vector2(bottom_radius, bottom_radius), bottom_radius, 0.0],
		[Vector2(rect.position.x + bottom_radius, rect.end.y - bottom_radius), bottom_radius, PI * 0.5],
	]
	for corner in corners:
		for i in corner_segments + 1:
			var a: float = corner[2] + PI * 0.5 * i / corner_segments
			points.append(corner[0] + Vector2(cos(a), sin(a)) * corner[1])
	return points


## Agranda (o encoge, con amount negativo) una forma convexa desde su centro: sirve para contornos.
static func grow(points: PackedVector2Array, amount: float) -> PackedVector2Array:
	var center := Vector2.ZERO
	for p in points:
		center += p
	center /= points.size()
	var result := PackedVector2Array()
	for p in points:
		result.append(p + (p - center).normalized() * amount)
	return result


# --- Dibujo ---

## Rellena una forma con un degradado vertical (top arriba, bottom abajo).
static func gradient_fill(ci: CanvasItem, points: PackedVector2Array, top: Color, bottom: Color) -> void:
	var min_y := INF
	var max_y := -INF
	for p in points:
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	var span := maxf(max_y - min_y, 0.001)
	var colors := PackedColorArray()
	for p in points:
		colors.append(top.lerp(bottom, (p.y - min_y) / span))
	ci.draw_polygon(points, colors)


## Forma con contorno grueso y relleno degradado: el "ladrillo" básico del estilo.
static func shape(ci: CanvasItem, points: PackedVector2Array, top: Color, bottom: Color, outline_width := 2.0) -> void:
	if outline_width > 0.0:
		ci.draw_colored_polygon(grow(points, outline_width), OUTLINE)
	gradient_fill(ci, points, top, bottom)


## Brillo suave (elipse blanca semitransparente).
static func shine(ci: CanvasItem, center: Vector2, radii: Vector2, alpha := 0.45) -> void:
	ci.draw_colored_polygon(ellipse(center, radii, 16), Color(1, 1, 1, alpha))


## Sombra de contacto en el suelo (varias elipses superpuestas para que sea difusa).
static func contact_shadow(ci: CanvasItem, center: Vector2, width: float, alpha := 0.25) -> void:
	for i in 3:
		var k := 1.0 - i * 0.25
		ci.draw_colored_polygon(ellipse(center, Vector2(width * k, width * 0.22 * k), 20), Color(0, 0, 0, alpha / 3.0))


## Textura de grano (64x64) para dar textura a tierra, ladrillos, etc. Se crea una sola vez.
static func grain_texture() -> Texture2D:
	if _grain == null:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		for y in 64:
			for x in 64:
				var v := rng.randf()
				if v > 0.55:
					image.set_pixel(x, y, Color(1, 1, 1, (v - 0.55) * 1.2))
				elif v < 0.3:
					image.set_pixel(x, y, Color(0, 0, 0, (0.3 - v) * 1.6))
				else:
					image.set_pixel(x, y, Color(0, 0, 0, 0))
		_grain = ImageTexture.create_from_image(image)
	return _grain


## Cubre un rectángulo con grano (el nodo debe tener texture_repeat activado).
static func grain(ci: CanvasItem, rect: Rect2, strength := 0.25) -> void:
	ci.draw_texture_rect(grain_texture(), rect, true, Color(1, 1, 1, strength))


## Tablón de madera con vetas y clavos (o nube esponjosa si cloud es true), para plataformas.
static func plank(ci: CanvasItem, rect: Rect2, color: Color, dark: Color, cloud := false) -> void:
	if cloud:
		var n := maxi(int(rect.size.x / 11.0), 1)
		for i in n + 1:
			ci.draw_circle(rect.position + Vector2(i * rect.size.x / n, 7.5), 8.5, dark)
		for i in n + 1:
			var c := rect.position + Vector2(i * rect.size.x / n, 4.5)
			gradient_fill(ci, circle(c, 7.5, 16), Color.WHITE, color.lerp(dark, 0.4))
		for i in n:
			ci.draw_circle(rect.position + Vector2((i + 0.3) * rect.size.x / n, 1.5), 1.8, Color(1, 1, 1, 0.8))
		return
	shape(ci, rounded_rect(rect, 3.0), color.lightened(0.12), dark.lightened(0.15), 1.5)
	for k in 2: # vetas de la madera
		var grain_line := PackedVector2Array()
		var x := rect.position.x + 3.0
		while x < rect.end.x - 2.0:
			grain_line.append(Vector2(x, rect.position.y + 4.5 + k * 3.5 + sin(x * 0.25 + k * 2.0) * 0.7))
			x += 5.0
		if grain_line.size() > 1:
			ci.draw_polyline(grain_line, Color(dark, 0.45), 1.0, true)
	var joint := rect.position.x + 32.0
	while joint < rect.end.x - 1.0: # juntas entre tablones
		ci.draw_line(Vector2(joint, rect.position.y + 1.5), Vector2(joint, rect.end.y - 1.5), Color(dark, 0.8), 1.2)
		joint += 32.0
	var nail := rect.position.x + 5.0
	while nail < rect.end.x:
		ci.draw_circle(Vector2(nail, rect.get_center().y), 1.3, dark.darkened(0.3))
		ci.draw_circle(Vector2(nail - 0.4, rect.get_center().y - 0.4), 0.5, Color(1, 1, 1, 0.5))
		nail += 32.0
	ci.draw_line(rect.position + Vector2(3, 1.6), Vector2(rect.end.x - 3, rect.position.y + 1.6), Color(1, 1, 1, 0.35), 1.2)
