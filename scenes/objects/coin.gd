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
	# Borde abombado, cara hundida y estrella en relieve
	draw_circle(Vector2.ZERO, 10.6, DrawKit.OUTLINE)
	DrawKit.gradient_fill(self, DrawKit.circle(Vector2.ZERO, 9.4, 24), GOLD_LIGHT, GOLD_DARK)
	DrawKit.gradient_fill(self, DrawKit.circle(Vector2.ZERO, 6.6, 20), GOLD_DARK.lightened(0.1), GOLD.lightened(0.15))
	var star := PackedVector2Array()
	for i in 10:
		var r := 4.4 if i % 2 == 0 else 1.9
		var a := -PI / 2.0 + i * PI / 5.0
		star.append(Vector2(cos(a), sin(a)) * r)
	DrawKit.gradient_fill(self, star, GOLD_LIGHT, GOLD)
	draw_arc(Vector2.ZERO, 8.0, PI * 1.1, PI * 1.5, 8, Color(1, 1, 1, 0.75), 1.6, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Destello de vez en cuando
	var sparkle := fmod(anim_time + position.x * 0.003, 3.0)
	if sparkle < 0.3:
		var s := sin(sparkle / 0.3 * PI) * 5.0
		var p := Vector2(5, -6)
		draw_line(p - Vector2(s, 0), p + Vector2(s, 0), Color.WHITE, 1.5)
		draw_line(p - Vector2(0, s), p + Vector2(0, s), Color.WHITE, 1.5)
