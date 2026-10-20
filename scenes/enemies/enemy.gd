class_name Enemy
extends CharacterBody2D
## Base de todos los enemigos. El origen del nodo está en su base.
## Cada enemigo hereda de aquí y define _move() (cómo se mueve) y _draw_body() (cómo se ve).
##   - Empieza a moverse cuando entra en pantalla.
##   - stomp(combo): el jugador lo pisa. Pisar varios seguidos sin tocar el suelo da más puntos.
##   - knock_out(): lo golpean desde abajo (un bloque); sale despedido y cae.

const GRAVITY := 1500.0
const OUTLINE := Color("1e1428")

@export var points := 200
var spiky := false # si es true, pisarlo hace daño al jugador
var squash_on_stomp := true # false: al pisarlo sale despedido en vez de aplastarse
var burst_color := Color.WHITE
var direction := -1.0
var active := false
var dead := false
var squashed := false
var knocked := false
var anim_time := 0.0
var squash := Vector2.ONE
var flash := 0.0 # destello blanco al recibir un golpe


func _ready() -> void:
	add_to_group("enemies")
	anim_time = randf() * 10.0
	var notifier := VisibleOnScreenNotifier2D.new()
	notifier.rect = Rect2(-24, -40, 48, 40)
	notifier.screen_entered.connect(func() -> void: active = true)
	add_child(notifier)


func _physics_process(delta: float) -> void:
	if knocked:
		velocity.y += GRAVITY * delta
		position += velocity * delta
		rotation += direction * 8.0 * delta
	elif not dead and active:
		_move(delta)
	if position.y > 3000.0:
		queue_free()


func _process(delta: float) -> void:
	anim_time += delta
	squash = squash.lerp(Vector2.ONE, minf(delta * 10.0, 1.0))
	flash = move_toward(flash, 0.0, delta * 5.0)
	var bright := 1.0 + flash * 4.0
	modulate = Color(bright, bright, bright)
	queue_redraw()


func _move(_delta: float) -> void:
	pass


## Movimiento de los enemigos que caminan: gravedad, se dan la vuelta en paredes
## y, si turn_at_ledges es true, también al llegar a un borde.
func walk(delta: float, speed: float, turn_at_ledges := false) -> void:
	velocity.x = direction * speed
	velocity.y = minf(velocity.y + GRAVITY * delta, 700.0)
	if turn_at_ledges and is_on_floor() and not _ground_ahead():
		direction = -direction
		velocity.x = direction * speed
		squash = Vector2(0.75, 1.2)
	move_and_slide()
	if is_on_wall() and signf(get_wall_normal().x) != direction:
		direction = signf(get_wall_normal().x)
		squash = Vector2(0.75, 1.2)


func _ground_ahead() -> bool:
	return test_move(global_transform.translated(Vector2(direction * 14.0, 0)), Vector2(0, 8))


func stomp(combo := 1) -> void:
	if dead:
		return
	if not squash_on_stomp:
		knock_out(combo)
		return
	dead = true
	squashed = true
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)
	_reward(combo)
	await get_tree().create_timer(0.5, false).timeout
	queue_free()


func knock_out(combo := 1) -> void:
	if dead:
		return
	dead = true
	knocked = true
	velocity = Vector2(-direction * 60.0, -380.0)
	z_index = 5
	$CollisionShape2D.set_deferred("disabled", true)
	_reward(combo)


## Puntos x1, x2, x4, x8 según el combo; con 5 seguidos, vida extra.
func _reward(combo: int) -> void:
	var multiplier := 1 << mini(combo - 1, 3)
	Game.add_score(points * multiplier)
	Sfx.play("stomp", 0.05, 1.0 + (combo - 1) * 0.12)
	flash = 1.0
	Fx.burst(self, global_position + Vector2(0, -10), burst_color, 12, 140.0)
	Fx.ring(self, global_position + Vector2(0, -10), Color.WHITE, 26.0 + combo * 4.0)
	if combo >= 5:
		Game.add_life()
		Fx.popup(self, global_position + Vector2(0, -34), "¡VIDA EXTRA!", Color("7dff9b"), 16)
	elif combo >= 2:
		Fx.popup(self, global_position + Vector2(0, -34), "+%d  x%d" % [points * multiplier, multiplier], Color("ffd23f"), 12 + combo * 2)
	else:
		Fx.popup(self, global_position + Vector2(0, -30), "+%d" % points)


func _draw() -> void:
	if squashed:
		_draw_squashed()
	else:
		draw_set_transform(Vector2.ZERO, 0.0, squash)
		_draw_body()


func _draw_body() -> void:
	pass


func _draw_squashed() -> void:
	draw_rect(Rect2(-16, -6, 32, 6), OUTLINE)
	draw_rect(Rect2(-15, -5, 30, 4), burst_color)


## Ojos con contorno que miran hacia donde va el enemigo. angry = cejas fruncidas.
func draw_eyes(center: Vector2, spacing: float, radius: float, angry := false) -> void:
	for side in [-1.0, 1.0]:
		var eye := center + Vector2(side * spacing, 0)
		draw_circle(eye, radius + 1.0, OUTLINE)
		draw_circle(eye, radius, Color.WHITE)
		draw_circle(eye + Vector2(direction * radius * 0.4, radius * 0.15), radius * 0.55, OUTLINE)
		if angry:
			var brow := eye + Vector2(0, -radius - 2.5)
			draw_line(brow + Vector2(-side * 3.5, -1.5), brow + Vector2(side * 3.0, 1.5), OUTLINE, 2.0, true)
