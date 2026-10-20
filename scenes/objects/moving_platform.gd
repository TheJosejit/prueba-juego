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
var cloud := false # en el tema del cielo la plataforma es una nube
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
	DrawKit.plank(self, Rect2(0, 0, w, THICKNESS), plank, plank_dark, cloud)
	# Flechas que indican la dirección
	var arrow := Color(1, 1, 1, 0.75) if not cloud else Color(plank_dark, 0.9)
	var c := Vector2(w / 2.0, THICKNESS / 2.0)
	var tips: Array = [[Vector2(-10, 0), Vector2(1, 0)], [Vector2(10, 0), Vector2(-1, 0)]]
	if axis.x == 0.0:
		tips = [[Vector2(0, -4), Vector2(0, 1)], [Vector2(0, 4), Vector2(0, -1)]]
	for tip in tips:
		var point: Vector2 = c + tip[0]
		var back: Vector2 = tip[1] * 4.0
		var side := Vector2(-back.y, back.x) * 0.8
		draw_colored_polygon(PackedVector2Array([point, point + back + side, point + back - side]), arrow)
