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
			var brim := DrawKit.rounded_rect(Rect2(c + Vector2(-12, 3) * s, Vector2(24, 4) * s), 1.5 * s)
			DrawKit.shape(ci, brim, HELMET_COLOR, HELMET_COLOR.darkened(0.3), 1.2 * s)
			DrawKit.shape(ci, DrawKit.circle(c + Vector2(0, -1) * s, 2.6 * s, 12), Color("fffbe0"), Color("ffe27a"), 1.0 * s)
		Kind.FEATHER:
			var pts := PackedVector2Array()
			for i in 20:
				var a := i / 20.0 * TAU
				pts.append(c + (Vector2(cos(a) * 4.5, sin(a) * 11.0)).rotated(0.6) * s)
			DrawKit.shape(ci, pts, Color.WHITE, Color("cfe3f7"), 1.4 * s)
			ci.draw_line(c + Vector2(-7, 9) * s, c + Vector2(5, -8) * s, Color("8fb0d6"), 1.5 * s, true)
			for k in 4: # barbas de la pluma
				var along := c + Vector2(-4.0 + k * 3.0, 4.5 - k * 4.2) * s
				ci.draw_line(along, along + Vector2(3.0, 1.0) * s, Color("a9c6e6"), 0.8 * s, true)
		Kind.MAGNET:
			ci.draw_arc(c, 7.0 * s, 0.0, PI, 16, OUTLINE, 7.5 * s, true)
			ci.draw_arc(c, 7.0 * s, 0.0, PI, 16, MAGNET_COLOR, 5.0 * s, true)
			ci.draw_arc(c, 7.0 * s, 0.3, PI - 0.3, 12, Color(1, 1, 1, 0.35), 1.5 * s, true)
			for side in [-1.0, 1.0]:
				var leg := DrawKit.rounded_rect(Rect2(c + Vector2(side * 7.0 - 2.5, -7.5) * s, Vector2(5, 8) * s), 1.0 * s)
				DrawKit.shape(ci, leg, MAGNET_COLOR.lightened(0.15), MAGNET_COLOR.darkened(0.15), 1.2 * s)
				var tip := DrawKit.rounded_rect(Rect2(c + Vector2(side * 7.0 - 2.5, -7.5) * s, Vector2(5, 3) * s), 1.0 * s)
				DrawKit.gradient_fill(ci, tip, Color.WHITE, Color("b8c3cf"))


## Cúpula del casco: degradado, contorno y brillos.
static func draw_dome(ci: CanvasItem, base: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 17:
		var a := PI + PI * i / 16.0
		points.append(base + Vector2(cos(a), sin(a)) * radius)
	DrawKit.shape(ci, points, color.lightened(0.3), color.darkened(0.15), 1.6)
	ci.draw_arc(base, radius * 0.72, PI * 1.12, PI * 1.42, 8, Color(1, 1, 1, 0.45), radius * 0.12, true)
	DrawKit.shine(ci, base + Vector2(-radius * 0.38, -radius * 0.58), Vector2(radius * 0.18, radius * 0.12), 0.85)
