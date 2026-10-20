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
			draw_circle(Vector2.ZERO, 8.4, OUTLINE)
			DrawKit.gradient_fill(self, DrawKit.circle(Vector2.ZERO, 7.2, 20), Color("fff1a8"), Color("c98a00"))
			DrawKit.gradient_fill(self, DrawKit.circle(Vector2.ZERO, 4.8, 16), Color("dca21a"), Color("ffe066"))
			draw_arc(Vector2.ZERO, 6.0, PI * 1.1, PI * 1.5, 6, Color(1, 1, 1, 0.75), 1.3, true)
		"heart":
			var heart := PackedVector2Array()
			for i in 32:
				var t := TAU * i / 32.0
				# Curva de corazón clásica, escalada al icono
				var x := 16.0 * pow(sin(t), 3)
				var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
				heart.append(c + Vector2(x, y) * 0.5)
			DrawKit.shape(self, heart, Color("ff7a92"), Color("d6234a"), 1.6)
			DrawKit.shine(self, c + Vector2(-3.8, -3.2), Vector2(1.8, 1.2), 0.8)
		"power":
			if power == Powers.Kind.NONE:
				return
			DrawKit.gradient_fill(self, DrawKit.circle(c, 11.5, 24), Color(1, 1, 1, 0.35), Color(0, 0, 0, 0.35))
			draw_arc(c, 11.5, 0.0, TAU, 24, Color(1, 1, 1, 0.5), 1.2, true)
			Powers.draw_icon(self, power, c + Vector2(0, 1), 0.72)
