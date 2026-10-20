extends Area2D
## Moneda: suma puntos al tocarla. Con el IMÁN, vuela hacia el jugador.

const GOLD := Color("ffd23f")
const GOLD_LIGHT := Color("fff1a8")
const GOLD_DARK := Color("c98a00")

var anim_time := 0.0
var target: Node2D = null
var attract_speed := 0.0


func _ready() -> void:
	add_to_group("coins")
	anim_time = position.x * 0.01 # cada moneda gira desfasada
	body_entered.connect(_on_body_entered)


func attract(to: Node2D) -> void:
	target = to


func _physics_process(delta: float) -> void:
	if target:
		attract_speed = minf(attract_speed + 1200.0 * delta, 520.0)
		global_position = global_position.move_toward(target.global_position + Vector2(0, -14), attract_speed * delta)


func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Game.add_coin()
		Fx.burst(self, global_position, GOLD_LIGHT, 8, 90.0)
		queue_free()


func _draw() -> void:
	var spin := cos(anim_time * 3.0)
	var width := maxf(absf(spin), 0.12)
	var bob := sin(anim_time * 2.5 + position.x * 0.05) * 1.5 if not target else 0.0
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(width, 1.0))
	draw_circle(Vector2.ZERO, 10.0, GOLD_DARK)
	draw_circle(Vector2.ZERO, 8.5, GOLD)
	draw_circle(Vector2(0, 0.5), 6.0, GOLD_DARK.lightened(0.3))
	draw_circle(Vector2.ZERO, 5.5, GOLD)
	draw_rect(Rect2(-1.5, -4, 3, 8), GOLD_DARK)
	draw_circle(Vector2(-3.5, -4.5), 1.8, GOLD_LIGHT)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Destello de vez en cuando
	var sparkle := fmod(anim_time + position.x * 0.003, 3.0)
	if sparkle < 0.3:
		var s := sin(sparkle / 0.3 * PI) * 5.0
		var p := Vector2(5, -6)
		draw_line(p - Vector2(s, 0), p + Vector2(s, 0), Color.WHITE, 1.5)
		draw_line(p - Vector2(0, s), p + Vector2(0, s), Color.WHITE, 1.5)
