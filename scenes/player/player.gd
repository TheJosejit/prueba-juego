extends CharacterBody2D
## Pip, el personaje del jugador. El origen del nodo está en sus pies.

const WALK_SPEED := 160.0
const RUN_SPEED := 260.0
const ACCEL := 1200.0
const FRICTION := 1400.0
const AIR_ACCEL := 900.0
const GRAVITY := 1500.0
const MAX_FALL_SPEED := 700.0
const JUMP_VELOCITY := -650.0
const JUMP_CUT := 0.45 # al soltar el salto antes de tiempo, el salto es más bajo
const STOMP_BOUNCE := -380.0
const COYOTE_TIME := 0.1 # margen para saltar justo después de salir de un borde
const JUMP_BUFFER := 0.12 # margen para pulsar salto justo antes de aterrizar

const BODY_COLOR := Color("ff8c42")
const BELLY_COLOR := Color("ffd0a1")
const SCARF_COLOR := Color("2ec4b6")
const FEET_COLOR := Color("6b3e26")

var facing := 1.0
var dead := false
var finished := false
var fall_limit := INF
var coyote := 0.0
var jump_buffer := 0.0
var squash := Vector2.ONE
var anim_time := 0.0
var death_camera_pos := Vector2.ZERO

@onready var hurtbox: Area2D = $Hurtbox
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)


func set_level_bounds(bounds: Rect2) -> void:
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
	camera.reset_smoothing()
	fall_limit = bounds.end.y + 64.0


func _physics_process(delta: float) -> void:
	if dead:
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
		position += velocity * delta
		camera.global_position = death_camera_pos
		return

	var dir := 0.0 if finished else Input.get_axis("move_left", "move_right")
	var speed := RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
	if dir != 0.0:
		var accel := ACCEL if is_on_floor() else AIR_ACCEL
		velocity.x = move_toward(velocity.x, dir * speed, accel * delta)
		facing = signf(dir)
	else:
		var friction := FRICTION if is_on_floor() else AIR_ACCEL * 0.5
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)

	coyote = COYOTE_TIME if is_on_floor() else coyote - delta
	if Input.is_action_just_pressed("jump") and not finished:
		jump_buffer = JUMP_BUFFER
	else:
		jump_buffer -= delta
	if jump_buffer > 0.0 and coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buffer = 0.0
		coyote = 0.0
		squash = Vector2(0.75, 1.25)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	var was_on_floor := is_on_floor()
	move_and_slide()
	if is_on_floor() and not was_on_floor:
		squash = Vector2(1.25, 0.8)

	# Golpear bloques con la cabeza.
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collision.get_normal().y > 0.7 and collider.has_method("hit_from_below"):
			collider.hit_from_below()

	position.x = maxf(position.x, 10.0)
	if position.y > fall_limit:
		die()


func _process(delta: float) -> void:
	anim_time += delta
	squash = squash.lerp(Vector2.ONE, minf(delta * 12.0, 1.0))
	queue_redraw()


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if dead or not body.is_in_group("enemies") or body.dead:
		return
	var landed_on_top := velocity.y > 0.0 and global_position.y < body.global_position.y - 8.0
	if landed_on_top:
		body.stomp()
		velocity.y = JUMP_VELOCITY if Input.is_action_pressed("jump") else STOMP_BOUNCE
		squash = Vector2(1.2, 0.85)
	else:
		die()


func die() -> void:
	if dead or finished:
		return
	dead = true
	death_camera_pos = camera.global_position
	velocity = Vector2(0.0, -450.0)
	$CollisionShape2D.set_deferred("disabled", true)
	hurtbox.set_deferred("monitoring", false)
	await get_tree().create_timer(1.2).timeout
	Game.player_died()


func win() -> void:
	finished = true


func _draw() -> void:
	if dead:
		draw_set_transform(Vector2(0, -14), PI, Vector2.ONE)
		_draw_body(Vector2(0, 14))
		return
	draw_set_transform(Vector2.ZERO, 0.0, squash)
	_draw_body(Vector2.ZERO)


func _draw_body(origin: Vector2) -> void:
	var walking := is_on_floor() and absf(velocity.x) > 10.0
	var step := sin(anim_time * 18.0) * 3.0 if walking else 0.0
	if not is_on_floor():
		step = 2.0
	# Pies
	draw_rect(Rect2(origin + Vector2(-10, -5 - maxf(step, 0.0)), Vector2(8, 5)), FEET_COLOR)
	draw_rect(Rect2(origin + Vector2(2, -5 - maxf(-step, 0.0)), Vector2(8, 5)), FEET_COLOR)
	# Cuerpo redondo
	draw_rect(Rect2(origin + Vector2(-11, -20), Vector2(22, 16)), BODY_COLOR)
	draw_circle(origin + Vector2(0, -20), 11.0, BODY_COLOR)
	draw_circle(origin + Vector2(facing * 2.0, -10), 6.0, BELLY_COLOR)
	# Bufanda
	draw_rect(Rect2(origin + Vector2(-11, -17), Vector2(22, 4)), SCARF_COLOR)
	draw_rect(Rect2(origin + Vector2(-facing * 11.0 - 3.0, -17), Vector2(6, 8)), SCARF_COLOR)
	# Ojos
	for side in [-1.0, 1.0]:
		var eye := origin + Vector2(facing * 3.0 + side * 4.0, -23)
		if dead:
			draw_line(eye - Vector2(2, 2), eye + Vector2(2, 2), Color.BLACK, 1.5)
			draw_line(eye + Vector2(-2, 2), eye + Vector2(2, -2), Color.BLACK, 1.5)
		else:
			draw_circle(eye, 3.0, Color.WHITE)
			draw_circle(eye + Vector2(facing * 1.2, 0), 1.6, Color.BLACK)
