extends Control
## Icono dibujado del marcador: moneda, corazón o la mejora actual.

@export_enum("coin", "heart", "power") var icon := "coin"
var power: Powers.Kind = Powers.Kind.NONE:
	set(value):
		power = value
		queue_redraw()

const OUTLINE := Color("1e1428")

var _spin := 0.0


## La moneda da una vuelta (al recoger una).
func spin() -> void:
	_spin = 0.4


func _process(delta: float) -> void:
	if _spin > 0.0:
		_spin = maxf(_spin - delta, 0.0)
		queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	match icon:
		"coin":
			draw_set_transform(c, 0.0, Vector2(maxf(absf(cos(_spin / 0.4 * TAU)), 0.15), 1.0))
			c = Vector2.ZERO
			draw_circle(c, 8.0, OUTLINE)
			draw_circle(c, 6.5, Color("ffd23f"))
			draw_rect(Rect2(c + Vector2(-1, -3.5), Vector2(2, 7)), Color("c98a00"))
			draw_circle(c + Vector2(-2.5, -3), 1.3, Color("fff1a8"))
		"heart":
			var red := Color("ff4d6d")
			for pass_ in 2:
				var grow := 1.5 if pass_ == 0 else 0.0
				var color := OUTLINE if pass_ == 0 else red
				draw_circle(c + Vector2(-3.5, -2), 4.5 + grow, color)
				draw_circle(c + Vector2(3.5, -2), 4.5 + grow, color)
				draw_colored_polygon(PackedVector2Array([
					c + Vector2(-8 - grow, -1), c + Vector2(8 + grow, -1), c + Vector2(0, 8 + grow),
				]), color)
			draw_circle(c + Vector2(-4.5, -3.5), 1.5, Color(1, 1, 1, 0.7))
		"power":
			if power == Powers.Kind.NONE:
				return
			draw_circle(c, 11.0, Color(0, 0, 0, 0.35))
			Powers.draw_icon(self, power, c + Vector2(0, 1), 0.75)
