extends AnimatableBody2D
## Plataforma que va y viene. La crea el nivel a partir de los caracteres ">" (horizontal)
## y "v" (vertical); varios seguidos forman una plataforma más ancha.
## Se puede atravesar desde abajo. El origen es la esquina superior izquierda.

const TILE := 32
const THICKNESS := 12.0

var width_tiles := 3
var axis := Vector2.RIGHT
var distance := 96.0 # cuánto se aleja de su posición inicial
var period := 4.0 # segundos que tarda en ir y volver
var plank := Color("c98a4b")
var plank_dark := Color("7d5229")
var origin := Vector2.ZERO
var time := 0.0


func _ready() -> void:
	sync_to_physics = true
	origin = position
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width_tiles * TILE, THICKNESS)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(width_tiles * TILE / 2.0, THICKNESS / 2.0)
	collision.one_way_collision = true
	add_child(collision)


func _physics_process(delta: float) -> void:
	time += delta
	position = origin + axis * sin(time * TAU / period) * distance


func _draw() -> void:
	var w := width_tiles * TILE
	var outline := Color("1e1428")
	draw_rect(Rect2(0, 0, w, THICKNESS), outline)
	draw_rect(Rect2(1.5, 1.5, w - 3, THICKNESS - 3), plank)
	draw_rect(Rect2(1.5, THICKNESS - 4.5, w - 3, 3), plank_dark)
	draw_rect(Rect2(1.5, 1.5, w - 3, 2), plank.lightened(0.25))
	for i in width_tiles:
		draw_circle(Vector2(i * TILE + 16, THICKNESS / 2.0), 1.8, plank_dark)
	# Flechas que indican la dirección
	var arrow := Color(1, 1, 1, 0.6)
	var c := Vector2(w / 2.0, THICKNESS / 2.0)
	if axis.x != 0.0:
		draw_line(c + Vector2(-10, 0), c + Vector2(-6, -3), arrow, 1.5)
		draw_line(c + Vector2(-10, 0), c + Vector2(-6, 3), arrow, 1.5)
		draw_line(c + Vector2(10, 0), c + Vector2(6, -3), arrow, 1.5)
		draw_line(c + Vector2(10, 0), c + Vector2(6, 3), arrow, 1.5)
	else:
		draw_line(c + Vector2(-3, -2), c + Vector2(0, -5), arrow, 1.5)
		draw_line(c + Vector2(3, -2), c + Vector2(0, -5), arrow, 1.5)
		draw_line(c + Vector2(-3, 2), c + Vector2(0, 5), arrow, 1.5)
		draw_line(c + Vector2(3, 2), c + Vector2(0, 5), arrow, 1.5)
