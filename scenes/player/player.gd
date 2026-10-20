extends CharacterBody2D
## Pip, el personaje del jugador. El origen del nodo está en sus pies.

const WALK_SPEED := 160.0
const RUN_SPEED := 260.0
const ACCEL := 1200.0
const TURN_ACCEL := 2600.0 # al cambiar de sentido frena mucho más rápido: giros más ágiles
const FRICTION := 1400.0
const AIR_ACCEL := 900.0
const GRAVITY := 1500.0
const FALL_GRAVITY := 1.15 # cae algo más rápido de lo que sube: el salto se siente más firme
const APEX_GRAVITY := 0.55 # en lo más alto del salto (manteniendo el botón) flota un poco: más control
const APEX_SPEED := 90.0
const MAX_FALL_SPEED := 700.0
const GLIDE_FALL_SPEED := 110.0 # con la PLUMA, manteniendo el salto al caer
const JUMP_VELOCITY := -650.0
const AIR_JUMP_VELOCITY := -560.0 # doble salto con la PLUMA
const JUMP_CUT := 0.45 # al soltar el salto antes de tiempo, el salto es más bajo
const STOMP_BOUNCE := -380.0
const SPRING_VELOCITY := -1000.0
const COYOTE_TIME := 0.1 # margen para saltar justo después de salir de un borde
const JUMP_BUFFER := 0.12 # margen para pulsar salto justo antes de aterrizar
const CORNER_CORRECTION := 7 # si la cabeza roza una esquina por pocos píxeles, se desliza en vez de chocar
const SKID_SPEED := 170.0 # a partir de esta velocidad, girar en el suelo hace derrapar
const INVINCIBLE_TIME := 2.0 # tras perder una mejora
const MAGNET_RADIUS := 130.0
const LOOK_AHEAD := 56.0 # la cámara se adelanta hacia donde corre Pip
const SLEEP_TIME := 6.0 # segundos quieto hasta que se duerme

const OUTLINE := Color("3a1f14")
const BODY_COLOR := Color("ff8c42")
const BODY_SHADE := Color("e0682a")
const BODY_LIGHT := Color("ffb57f")
const BELLY_COLOR := Color("ffe0bd")
const SCARF_COLOR := Color("2ec4b6")
const SCARF_DARK := Color("1d8f84")
const FEET_COLOR := Color("6b3e26")
const CHEEK_COLOR := Color(1.0, 0.45, 0.45, 0.5)

var facing := 1.0
var dead := false
var finished := false
var fall_limit := INF
var coyote := 0.0
var jump_buffer := 0.0
var spring_launch := false # tras un muelle, soltar el salto no corta la subida
var power: Powers.Kind = Powers.Kind.NONE
var air_jumps := 0
var gliding := false
var skidding := false
var invincible := 0.0
var stomp_combo := 0 # enemigos pisados seguidos sin tocar el suelo
var death_camera_pos := Vector2.ZERO
var shake := 0.0
# Animación
var squash := Vector2.ONE
var flip := 1.0 # va de -1 a 1 al girar (Pip "se da la vuelta" en vez de cambiar de golpe)
var anim_time := 0.0
var idle_time := 0.0
var blink := 0.0
var next_blink := 2.5
var step_phase := 0.0
var run_dust_timer := 0.0
var ghost_timer := 0.0

@onready var hurtbox: Area2D = $Hurtbox
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	power = Game.power


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

	if invincible > 0.0:
		invincible -= delta
		if invincible <= 0.0:
			_check_overlaps() # por si sigue tocando a un enemigo o unos pinchos

	var on_floor := is_on_floor()
	_move_horizontal(delta, on_floor)
	_apply_gravity(delta, on_floor)
	_handle_jump(on_floor)

	if velocity.y < 0.0:
		_correct_corners(delta)
	var fall_speed := velocity.y
	move_and_slide()
	if is_on_floor() and not on_floor:
		_land(fall_speed)

	# Golpear bloques con la cabeza
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collision.get_normal().y > 0.7:
			squash = Vector2(1.15, 0.85)
			if collider and collider.has_method("hit_from_below"):
				collider.hit_from_below(self)

	_trail_effects(delta)
	if power == Powers.Kind.MAGNET:
		for coin in get_tree().get_nodes_in_group("coins"):
			if global_position.distance_to(coin.global_position) < MAGNET_RADIUS:
				coin.attract(self)

	# La cámara se adelanta hacia donde corre
	var look := facing * LOOK_AHEAD * clampf(absf(velocity.x) / RUN_SPEED, 0.0, 1.0)
	camera.position.x = move_toward(camera.position.x, look, 90.0 * delta)

	position.x = maxf(position.x, 10.0)
	if position.y > fall_limit:
		die()


func _move_horizontal(delta: float, on_floor: bool) -> void:
	var dir := 0.0 if finished else Input.get_axis("move_left", "move_right")
	var speed := RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
	if dir == 0.0:
		skidding = false
		velocity.x = move_toward(velocity.x, 0.0, (FRICTION if on_floor else AIR_ACCEL * 0.5) * delta)
		return
	var accel := ACCEL if on_floor else AIR_ACCEL
	var turning := velocity.x != 0.0 and signf(velocity.x) != dir
	if turning:
		accel = TURN_ACCEL if on_floor else AIR_ACCEL * 1.6
		if on_floor and absf(velocity.x) > SKID_SPEED and not skidding:
			skidding = true
			Sfx.play("skid", 0.05)
			Fx.dust(self, global_position + Vector2(facing * 6.0, 0), 7)
	else:
		skidding = false
	velocity.x = move_toward(velocity.x, dir * speed, accel * delta)
	facing = signf(dir)


func _apply_gravity(delta: float, on_floor: bool) -> void:
	gliding = power == Powers.Kind.FEATHER and not on_floor and velocity.y > 0.0 \
			and Input.is_action_pressed("jump") and not finished
	var gravity := GRAVITY
	if velocity.y > 0.0:
		gravity *= FALL_GRAVITY
	elif absf(velocity.y) < APEX_SPEED and Input.is_action_pressed("jump"):
		gravity *= APEX_GRAVITY
	velocity.y += gravity * delta
	var max_fall := GLIDE_FALL_SPEED if gliding else MAX_FALL_SPEED
	if velocity.y > max_fall:
		velocity.y = move_toward(velocity.y, max_fall, 3000.0 * delta)


func _handle_jump(on_floor: bool) -> void:
	if on_floor:
		air_jumps = 1 if power == Powers.Kind.FEATHER else 0
		spring_launch = false
		stomp_combo = 0
	coyote = COYOTE_TIME if on_floor else coyote - get_physics_process_delta_time()
	var jump_pressed := Input.is_action_just_pressed("jump") and not finished
	jump_buffer = JUMP_BUFFER if jump_pressed else jump_buffer - get_physics_process_delta_time()
	if jump_buffer > 0.0 and coyote > 0.0:
		_jump(JUMP_VELOCITY)
	elif jump_pressed and air_jumps > 0:
		air_jumps -= 1
		_jump(AIR_JUMP_VELOCITY, true)
	if Input.is_action_just_released("jump") and velocity.y < 0.0 and not spring_launch:
		velocity.y *= JUMP_CUT


func _jump(jump_velocity: float, in_air := false) -> void:
	velocity.y = jump_velocity
	jump_buffer = 0.0
	coyote = 0.0
	spring_launch = false
	skidding = false
	squash = Vector2(0.7, 1.3)
	idle_time = 0.0
	if in_air:
		Sfx.play("double_jump", 0.05)
		Fx.burst(self, global_position, Color.WHITE, 8, 90.0)
		Fx.ring(self, global_position + Vector2(0, -4), Color.WHITE, 22.0)
	else:
		Sfx.play("jump", 0.05)
		Fx.dust(self, global_position)


func _land(impact: float) -> void:
	var k := clampf(impact / MAX_FALL_SPEED, 0.0, 1.0)
	squash = Vector2(1.0 + 0.4 * k, 1.0 - 0.35 * k)
	Fx.dust(self, global_position, 4 + int(10.0 * k))
	if k > 0.35:
		Sfx.play("land", 0.08, 1.2 - k * 0.3)
	if k > 0.95:
		shake = maxf(shake, 3.0)


## Polvo al correr, pasos y estela cuando va muy rápido.
func _trail_effects(delta: float) -> void:
	var on_floor := is_on_floor()
	var running := absf(velocity.x) > WALK_SPEED + 40.0
	run_dust_timer -= delta
	if on_floor and running and run_dust_timer <= 0.0:
		run_dust_timer = 0.15
		Fx.dust(self, global_position + Vector2(-facing * 8.0, 0), 2)
	if on_floor and absf(velocity.x) > 40.0:
		var s := sin(anim_time * (22.0 if running else 16.0))
		if signf(s) != signf(step_phase):
			Sfx.play("step", 0.15, 1.0 if running else 0.85)
		step_phase = s
	ghost_timer -= delta
	if ghost_timer <= 0.0 and (absf(velocity.x) > RUN_SPEED * 0.92 or spring_launch):
		ghost_timer = 0.05
		Fx.afterimage(self, global_position, squash, BODY_COLOR)


## Si al subir la cabeza roza el borde de un bloque, desplaza a Pip unos píxeles para que pase.
func _correct_corners(delta: float) -> void:
	var motion := Vector2(0, velocity.y * delta)
	if not test_move(global_transform, motion):
		return
	for offset in range(1, CORNER_CORRECTION + 1):
		for side in [-1, 1]:
			var shifted := global_transform.translated(Vector2(offset * side, 0))
			if not test_move(global_transform, Vector2(offset * side, 0)) and not test_move(shifted, motion):
				position.x += offset * side
				return


func _process(delta: float) -> void:
	anim_time += delta
	squash = squash.lerp(Vector2.ONE, minf(delta * 12.0, 1.0))
	flip = move_toward(flip, facing, delta * 9.0)
	shake = move_toward(shake, 0.0, delta * 20.0)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake if Settings.screen_shake else Vector2.ZERO
	if is_on_floor() and absf(velocity.x) < 5.0 and not finished and not dead:
		idle_time += delta
	else:
		idle_time = 0.0
	next_blink -= delta
	if next_blink <= 0.0:
		blink = 0.12
		next_blink = randf_range(2.0, 4.5)
	blink = maxf(blink - delta, 0.0)
	modulate.a = 0.35 if invincible > 0.0 and int(invincible * 16.0) % 2 == 0 else 1.0
	queue_redraw()


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if dead or not body.is_in_group("enemies") or body.dead:
		return
	var landed_on_top := velocity.y > 0.0 and global_position.y < body.global_position.y - 8.0
	if landed_on_top and not body.spiky:
		stomp_combo += 1
		body.stomp(stomp_combo)
		velocity.y = JUMP_VELOCITY if Input.is_action_pressed("jump") else STOMP_BOUNCE
		air_jumps = 1 if power == Powers.Kind.FEATHER else 0
		squash = Vector2(1.3, 0.75)
		shake = 3.0 + stomp_combo
		Game.hitstop(0.05)
		if stomp_combo >= 2:
			zoom_punch(0.03 * mini(stomp_combo, 4))
	else:
		hurt()


func _check_overlaps() -> void:
	for body in hurtbox.get_overlapping_bodies():
		_on_hurtbox_body_entered(body)
	for area in hurtbox.get_overlapping_areas():
		if area.is_in_group("hazards"):
			hurt()


func give_power(kind: Powers.Kind) -> void:
	_set_power(kind)
	Sfx.play("power_up")
	Game.add_score(500)
	Fx.burst(self, global_position + Vector2(0, -14), Color("ffd23f"), 16, 180.0)
	Fx.sparkle(self, global_position + Vector2(0, -16), Color("fff1a8"), 12)
	Fx.ring(self, global_position + Vector2(0, -16), Color("ffd23f"), 40.0, 0.4)
	Fx.popup(self, global_position + Vector2(0, -44), Powers.HINTS[kind], Color("ffd23f"), 14)
	squash = Vector2(0.7, 1.35)
	zoom_punch(0.1)


func _set_power(kind: Powers.Kind) -> void:
	power = kind
	air_jumps = 1 if kind == Powers.Kind.FEATHER else 0
	Game.set_power(kind)


## Daño: si tiene una mejora la pierde (y queda invencible un momento); si no, muere.
func hurt() -> void:
	if dead or finished or invincible > 0.0:
		return
	if power == Powers.Kind.NONE:
		die()
		return
	_set_power(Powers.Kind.NONE)
	invincible = INVINCIBLE_TIME
	velocity = Vector2(-facing * 180.0, -320.0)
	shake = 6.0
	squash = Vector2(1.3, 0.7)
	Sfx.play("power_down")
	Fx.burst(self, global_position + Vector2(0, -16), Color.WHITE, 12, 150.0)
	Fx.ring(self, global_position + Vector2(0, -16), Color("ff4d6d"), 36.0)
	Game.hitstop(0.12)
	zoom_punch(0.06)


func spring_bounce() -> void:
	velocity.y = SPRING_VELOCITY
	spring_launch = true
	air_jumps = 1 if power == Powers.Kind.FEATHER else 0
	squash = Vector2(0.6, 1.4)
	Fx.ring(self, global_position, Color.WHITE, 30.0)


## Efecto de "golpe" de cámara: se acerca un poco y vuelve.
func zoom_punch(amount: float) -> void:
	camera.zoom = Vector2.ONE * (1.0 + amount)
	var tween := create_tween()
	tween.tween_property(camera, "zoom", Vector2.ONE, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func die() -> void:
	if dead or finished:
		return
	dead = true
	modulate.a = 1.0
	death_camera_pos = camera.global_position
	velocity = Vector2(0.0, -450.0)
	shake = 8.0
	Sfx.stop_music()
	Sfx.play("die")
	Fx.burst(self, global_position + Vector2(0, -14), BODY_COLOR, 14, 160.0)
	Fx.ring(self, global_position + Vector2(0, -14), Color.WHITE, 48.0, 0.4)
	$CollisionShape2D.set_deferred("disabled", true)
	hurtbox.set_deferred("monitoring", false)
	Game.hitstop(0.3, 0.15)
	await get_tree().create_timer(1.2, false).timeout
	Game.player_died()


func win() -> void:
	finished = true
	invincible = 0.0
	if is_on_floor():
		velocity.y = -380.0 # saltito de alegría
	var tween := create_tween()
	tween.tween_property(camera, "zoom", Vector2(1.15, 1.15), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# --- Dibujo ---

func _draw() -> void:
	var dir := signf(flip) if flip != 0.0 else facing
	if dead:
		draw_set_transform(Vector2(0, -14), PI, Vector2.ONE)
		_draw_body(Vector2(0, 14), dir)
		return
	var lean := clampf(velocity.x / RUN_SPEED, -1.0, 1.0) * (0.1 if is_on_floor() else 0.05)
	if skidding:
		lean = -facing * 0.2
	var breathe := 1.0 + sin(anim_time * 2.5) * 0.03 if idle_time > 0.5 else 1.0
	var turn := 0.5 + 0.5 * absf(flip) # se estrecha al darse la vuelta
	draw_set_transform(Vector2.ZERO, lean, Vector2(squash.x * turn, squash.y * breathe))
	_draw_body(Vector2.ZERO, dir)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if idle_time > SLEEP_TIME:
		var font := ThemeDB.fallback_font
		for i in 3:
			var phase := fmod(anim_time * 0.5 + i / 3.0, 1.0)
			draw_string(font, Vector2(8 + phase * 12.0, -34 - phase * 22.0), "z",
				HORIZONTAL_ALIGNMENT_LEFT, -1, int(8 + 6 * phase), Color(1, 1, 1, 1.0 - phase))


func _draw_body(origin: Vector2, f: float) -> void:
	var on_floor := is_on_floor()
	var running := absf(velocity.x) > WALK_SPEED + 20.0
	var walking := on_floor and absf(velocity.x) > 10.0
	var cycle := anim_time * (22.0 if running else 16.0)
	var step := sin(cycle) * 3.0 if walking else 0.0
	var bob := -absf(cos(cycle)) * 1.5 if walking else 0.0
	if not on_floor:
		step = 2.5
	var body := origin + Vector2(0, bob)
	var sleeping := idle_time > SLEEP_TIME

	# Bufanda ondeando (detrás del cuerpo)
	var scarf_base := body + Vector2(-f * 8.0, -15)
	var scarf := PackedVector2Array()
	var length := 7.0 + minf(absf(velocity.x) / 22.0, 9.0) + (4.0 if not on_floor else 0.0)
	for i in 6:
		var t := i / 5.0
		var wave := sin(anim_time * 14.0 - i * 1.2) * 2.0 * t
		var lift := clampf(velocity.y / 300.0, -1.0, 1.0) * -4.0 * t
		scarf.append(scarf_base + Vector2(-f * t * length, t * 5.0 + wave + lift))
	draw_polyline(scarf, OUTLINE, 6.0, true)
	draw_polyline(scarf, SCARF_DARK, 4.0, true)

	# Alas de la PLUMA (detrás del cuerpo)
	if power == Powers.Kind.FEATHER and not dead:
		var flap := sin(anim_time * (22.0 if gliding else 6.0)) * (6.0 if not on_floor else 2.0)
		for side in [-1.0, 1.0]:
			var wing := PackedVector2Array([
				body + Vector2(side * 8.0, -16),
				body + Vector2(side * 21.0, -24 - flap),
				body + Vector2(side * 19.0, -16 - flap * 0.5),
				body + Vector2(side * 15.0, -11),
			])
			var wing_outline := wing.duplicate()
			wing_outline.append(wing[0])
			draw_colored_polygon(wing, Color.WHITE)
			draw_polyline(wing_outline, OUTLINE, 1.5, true)

	# Manos: se balancean al andar, arriba al saltar
	var swing := sin(cycle) * 4.0 if walking else 0.0
	var back_hand := body + Vector2(-f * 11.0 - f * swing * 0.5, -11 + swing * 0.3)
	var front_hand := body + Vector2(f * 11.0 + f * swing * 0.5, -11 - swing * 0.3)
	if not on_floor and not dead:
		var up := 4.0 if velocity.y < 0.0 else 0.0
		back_hand = body + Vector2(-f * 13.0, -22 - up)
		front_hand = body + Vector2(f * 13.0, -22 - up)
	elif skidding:
		back_hand = body + Vector2(f * 9.0, -20)
		front_hand = body + Vector2(f * 13.0, -16)
	_draw_hand(back_hand)

	# Pies
	for foot in [Vector2(-10, -5 - maxf(step, 0.0)), Vector2(2, -5 - maxf(-step, 0.0))]:
		draw_rect(Rect2(origin + foot - Vector2(1, 1), Vector2(10, 7)), OUTLINE)
		draw_rect(Rect2(origin + foot, Vector2(8, 5)), FEET_COLOR)

	# Cuerpo redondo con contorno, sombra y brillo
	draw_circle(body + Vector2(0, -20), 12.5, OUTLINE)
	draw_rect(Rect2(body + Vector2(-12.5, -20), Vector2(25, 16.5)), OUTLINE)
	draw_circle(body + Vector2(0, -20), 11.0, BODY_COLOR)
	draw_rect(Rect2(body + Vector2(-11, -20), Vector2(22, 15)), BODY_COLOR)
	draw_rect(Rect2(body + Vector2(-11, -9), Vector2(22, 4)), BODY_SHADE)
	draw_circle(body + Vector2(-5, -26), 3.0, BODY_LIGHT)
	draw_circle(body + Vector2(f * 2.0, -10), 6.0, BELLY_COLOR)
	# Mechón (se mueve con el salto)
	var tuft := clampf(-velocity.y / 400.0, -1.0, 1.0) * 2.0
	draw_colored_polygon(PackedVector2Array([
		body + Vector2(-3, -30), body + Vector2(-1 - tuft, -36 + absf(tuft)), body + Vector2(2, -31),
		body + Vector2(5 - tuft, -35 + absf(tuft)), body + Vector2(5, -29),
	]), BODY_COLOR)
	# Bufanda alrededor del cuello
	draw_rect(Rect2(body + Vector2(-12, -18), Vector2(24, 6)), OUTLINE)
	draw_rect(Rect2(body + Vector2(-11, -17), Vector2(22, 4)), SCARF_COLOR)

	# Cara
	var face := body + Vector2(f * 3.0, 0)
	draw_circle(face + Vector2(8.0, -18.5), 2.2, CHEEK_COLOR)
	draw_circle(face + Vector2(-8.0, -18.5), 2.2, CHEEK_COLOR)
	var look := Vector2(f * 1.1, clampf(velocity.y / 400.0, -1.0, 1.0) * 0.9)
	for side in [-1.0, 1.0]:
		var eye := face + Vector2(side * 4.0, -24)
		if dead:
			draw_line(eye - Vector2(2, 2), eye + Vector2(2, 2), OUTLINE, 1.5)
			draw_line(eye + Vector2(-2, 2), eye + Vector2(2, -2), OUTLINE, 1.5)
		elif finished:
			draw_arc(eye + Vector2(0, 1.5), 2.5, PI, TAU, 8, OUTLINE, 1.5, true) # ojos felices ^ ^
		elif sleeping or blink > 0.0:
			draw_line(eye - Vector2(2.5, -0.5), eye + Vector2(2.5, 0.5), OUTLINE, 1.5)
		elif invincible > 0.0:
			draw_polyline(PackedVector2Array([ # ojos apretados > <
				eye + Vector2(side * 2.5, -1.5), eye + Vector2(-side * 2.0, 0), eye + Vector2(side * 2.5, 1.5),
			]), OUTLINE, 1.5, true)
		else:
			draw_circle(eye, 3.4, OUTLINE)
			draw_circle(eye, 2.8, Color.WHITE)
			draw_circle(eye + look, 1.6, OUTLINE)
			draw_circle(eye + look * 0.4 + Vector2(-0.6, -0.9), 0.7, Color.WHITE)
	# Boca
	var mouth := face + Vector2(0, -19.5)
	if dead or invincible > 0.0:
		draw_arc(mouth + Vector2(0, 2.0), 2.0, PI + 0.4, TAU - 0.4, 6, OUTLINE, 1.2, true)
	elif finished:
		draw_arc(mouth + Vector2(0, -0.5), 2.8, 0.1, PI - 0.1, 8, OUTLINE, 1.6, true)
	elif sleeping or (not on_floor and absf(velocity.y) > 250.0):
		draw_circle(mouth + Vector2(0, 0.5), 1.4 + (0.4 * sin(anim_time * 2.5) if sleeping else 0.0), OUTLINE)
	else:
		draw_arc(mouth, 1.8, 0.3, PI - 0.3, 6, OUTLINE, 1.2, true)

	_draw_hand(front_hand)

	# Accesorios de las mejoras
	if dead:
		return
	match power:
		Powers.Kind.HELMET:
			Powers.draw_dome(self, body + Vector2(0, -24), 12.5, Powers.HELMET_COLOR)
			draw_rect(Rect2(body + Vector2(-14, -25), Vector2(28, 4)), Powers.OUTLINE)
			draw_rect(Rect2(body + Vector2(-13, -24.5), Vector2(26, 2.5)), Powers.HELMET_COLOR.darkened(0.25))
			draw_circle(body + Vector2(f * 5.0, -31), 3.0, Powers.OUTLINE)
			draw_circle(body + Vector2(f * 5.0, -31), 2.2, Color("fff6c2"))
		Powers.Kind.MAGNET:
			Powers.draw_icon(self, Powers.Kind.MAGNET, body + Vector2(0, -38), 0.6)
			var pulse := fmod(anim_time, 1.0)
			draw_arc(body + Vector2(0, -16), 14.0 + pulse * 20.0, 0.0, TAU, 32, Color(1, 0.3, 0.35, 0.4 * (1.0 - pulse)), 1.5, true)


func _draw_hand(pos: Vector2) -> void:
	draw_circle(pos, 4.0, OUTLINE)
	draw_circle(pos, 2.8, BODY_SHADE)
