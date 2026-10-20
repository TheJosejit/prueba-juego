extends Control
## Título animado del menú: cada letra cae rebotando al entrar y luego ondea.

@export var text := "PIP"
@export var font_size := 72
@export var letter_colors: Array[Color] = [Color("ff8c42"), Color("2ec4b6"), Color("ffd23f")]

const OUTLINE := Color("1e1428")
const DROP_TIME := 0.6 # lo que tarda cada letra en caer
const LETTER_DELAY := 0.15 # retraso entre letras

var time := 0.0


func _ready() -> void:
	physics_interpolation_mode = PHYSICS_INTERPOLATION_MODE_OFF # se anima cada fotograma


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


## Tiempo hasta que la última letra ha caído (para encadenar el resto de la entrada).
func intro_length() -> float:
	return LETTER_DELAY * (text.length() - 1) + DROP_TIME


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var spacing := 6.0
	var widths: Array[float] = []
	var total := -spacing
	for ch in text:
		var w := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		widths.append(w)
		total += w + spacing
	var x := (size.x - total) / 2.0
	var baseline := size.y * 0.5 + font_size * 0.35
	for i in text.length():
		var progress := clampf((time - i * LETTER_DELAY) / DROP_TIME, 0.0, 1.0)
		var fall := -size.y * 2.5 * (1.0 - _bounce(progress))
		var wave := sin(time * 3.0 - i * 0.8) * 4.0 * progress
		var tilt := sin(time * 2.0 - i * 1.3) * 0.06 * progress
		var squash := 1.0 + (0.25 * (1.0 - progress) if progress < 1.0 else 0.0)
		var center := Vector2(x + widths[i] / 2.0, baseline + fall + wave)
		draw_set_transform(center, tilt, Vector2(1.0 / squash, squash))
		var origin := Vector2(-widths[i] / 2.0, 0)
		var ch := text[i]
		draw_string(font, origin + Vector2(4, 6), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.3))
		draw_string_outline(font, origin, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 14, OUTLINE)
		draw_string(font, origin, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, letter_colors[i % letter_colors.size()])
		draw_string(font, origin + Vector2(-2, -3), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
			Color(1, 1, 1, 0.18))
		x += widths[i] + spacing
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Curva de "caer y rebotar" (0 -> 1).
func _bounce(t: float) -> float:
	if t < 1.0 / 2.75:
		return 7.5625 * t * t
	if t < 2.0 / 2.75:
		t -= 1.5 / 2.75
		return 7.5625 * t * t + 0.75
	if t < 2.5 / 2.75:
		t -= 2.25 / 2.75
		return 7.5625 * t * t + 0.9375
	t -= 2.625 / 2.75
	return 7.5625 * t * t + 0.984375
