class_name Powers
## Mejoras (poderes) del personaje. Aquí también se dibuja su icono,
## que comparten el objeto que se recoge, el jugador y el marcador.
##
##   CASCO  rompe ladrillos al golpearlos desde abajo
##   PLUMA  doble salto y planear (mantener salto al caer)
##   IMÁN   atrae las monedas cercanas
## Cualquier mejora protege de un golpe: al recibirlo se pierde la mejora en vez de morir.

enum Kind { NONE, HELMET, FEATHER, MAGNET }

const NAMES := {Kind.HELMET: "CASCO", Kind.FEATHER: "PLUMA", Kind.MAGNET: "IMÁN"}
const HINTS := {
	Kind.HELMET: "¡Rompe ladrillos!",
	Kind.FEATHER: "¡Doble salto y planear!",
	Kind.MAGNET: "¡Atrae monedas!",
}
const OUTLINE := Color("2b1a12")
const HELMET_COLOR := Color("f2c14e")
const MAGNET_COLOR := Color("e63946")


static func draw_icon(ci: CanvasItem, kind: Kind, c: Vector2, s := 1.0) -> void:
	match kind:
		Kind.HELMET:
			draw_dome(ci, c + Vector2(0, 4) * s, 10.0 * s, HELMET_COLOR)
			ci.draw_rect(Rect2(c + Vector2(-12, 3) * s, Vector2(24, 4) * s), OUTLINE)
			ci.draw_rect(Rect2(c + Vector2(-11, 3.5) * s, Vector2(22, 2.5) * s), HELMET_COLOR.darkened(0.25))
			ci.draw_circle(c + Vector2(0, -1) * s, 3.2 * s, OUTLINE)
			ci.draw_circle(c + Vector2(0, -1) * s, 2.4 * s, Color("fff6c2"))
		Kind.FEATHER:
			var pts := PackedVector2Array()
			for i in 17:
				var a := i / 16.0 * TAU
				pts.append(c + (Vector2(cos(a) * 4.5, sin(a) * 11.0)).rotated(0.6) * s)
			ci.draw_colored_polygon(pts, Color.WHITE)
			pts.append(pts[0])
			ci.draw_polyline(pts, OUTLINE, 1.5 * s, true)
			ci.draw_line(c + Vector2(-7, 9) * s, c + Vector2(5, -8) * s, Color("9ab7d8"), 1.5 * s, true)
		Kind.MAGNET:
			ci.draw_arc(c + Vector2(0, 0) * s, 7.0 * s, 0.0, PI, 16, OUTLINE, 7.5 * s, true)
			ci.draw_arc(c + Vector2(0, 0) * s, 7.0 * s, 0.0, PI, 16, MAGNET_COLOR, 5.0 * s, true)
			for side in [-1.0, 1.0]:
				ci.draw_rect(Rect2(c + Vector2(side * 7.0 - 3.5, -8) * s, Vector2(7, 8.5) * s), OUTLINE)
				ci.draw_rect(Rect2(c + Vector2(side * 7.0 - 2.5, -4) * s, Vector2(5, 4.5) * s), MAGNET_COLOR)
				ci.draw_rect(Rect2(c + Vector2(side * 7.0 - 2.5, -7) * s, Vector2(5, 3) * s), Color("dfe6ee"))


## Semicírculo con contorno (cúpula del casco).
static func draw_dome(ci: CanvasItem, base: Vector2, radius: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 17:
		var a := PI + PI * i / 16.0
		pts.append(base + Vector2(cos(a), sin(a)) * radius)
	var outline := PackedVector2Array()
	for i in 17:
		var a := PI + PI * i / 16.0
		outline.append(base + Vector2(cos(a), sin(a)) * (radius + 1.5))
	ci.draw_colored_polygon(outline, OUTLINE)
	ci.draw_colored_polygon(pts, color)
	ci.draw_circle(base + Vector2(-radius * 0.4, -radius * 0.55), radius * 0.2, color.lightened(0.5))
