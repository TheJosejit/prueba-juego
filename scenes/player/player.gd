extends CharacterBody2D
## Pip, el personaje del jugador: un robotito con botas cohete. El origen del nodo está en sus pies.

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

const OUTLINE := Color("1c1a22")
const PEARL := Color("f4f2ee") # blanco perla del cuerpo
const METAL := Color("b9bec8") # gris cálido (sombras, manos, antena)
const ACCENT := Color("3d5a80") # azul pizarra de las botas y la franja
const ACCENT_WARM := Color("f28c28") # luz de estado del pecho
const LED := Color("8ff3ff") # ojos y boca
const LED_HURT := Color("ff6b74")
const ANTENNA_LIGHT := Color("ffb347")
const BODY_COLOR := Color("bcd4ea") # color de la estela y de las partículas al morir

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
# Modo demo (menú principal): Pip se mueve solo, sin cámara ni sonidos
var demo := false
var demo_dir := 1.0
var demo_run := false
var demo_jump_pressed := false # se pone a true un fotograma para saltar
var demo_jump_hold := 0.0 # segundos que "mantiene" el salto
var _jump_cut_done := false
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
var antenna_lag := Vector2.ZERO # la punta de la antena se retrasa con la inercia

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
	if demo:
		demo_jump_hold = maxf(demo_jump_hold - delta, 0.0)
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

	if not demo:
		position.x = maxf(position.x, 10.0)
	if position.y > fall_limit:
		die()


func _move_horizontal(delta: float, on_floor: bool) -> void:
	var dir := 0.0 if finished else _input_dir()
	var speed := RUN_SPEED if _run_held() else WALK_SPEED
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
			_sfx("skid", 0.05)
			Fx.dust(self, global_position + Vector2(facing * 6.0, 0), 7)
	else:
		skidding = false
	velocity.x = move_toward(velocity.x, dir * speed, accel * delta)
	facing = signf(dir)


func _apply_gravity(delta: float, on_floor: bool) -> void:
	gliding = power == Powers.Kind.FEATHER and not on_floor and velocity.y > 0.0 \
			and _jump_held() and not finished
	var gravity := GRAVITY
	if velocity.y > 0.0:
		gravity *= FALL_GRAVITY
	elif absf(velocity.y) < APEX_SPEED and _jump_held():
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
	var jump_pressed := _jump_just_pressed() and not finished
	jump_buffer = JUMP_BUFFER if jump_pressed else jump_buffer - get_physics_process_delta_time()
	if jump_buffer > 0.0 and coyote > 0.0:
		_jump(JUMP_VELOCITY)
	elif jump_pressed and air_jumps > 0:
		air_jumps -= 1
		_jump(AIR_JUMP_VELOCITY, true)
	if not _jump_held() and velocity.y < 0.0 and not spring_launch and not _jump_cut_done:
		velocity.y *= JUMP_CUT
		_jump_cut_done = true


# --- Entrada (teclado/mando, o el modo demo del menú) ---

func _input_dir() -> float:
	return demo_dir if demo else Input.get_axis("move_left", "move_right")


func _run_held() -> bool:
	return demo_run if demo else Input.is_action_pressed("run")


func _jump_just_pressed() -> bool:
	if demo:
		var pressed := demo_jump_pressed
		demo_jump_pressed = false
		return pressed
	return Input.is_action_just_pressed("jump")


func _jump_held() -> bool:
	return demo_jump_hold > 0.0 if demo else Input.is_action_pressed("jump")


func _sfx(sound: String, pitch_variation := 0.0, pitch := 1.0) -> void:
	if not demo:
		Sfx.play(sound, pitch_variation, pitch)


func _jump(jump_velocity: float, in_air := false) -> void:
	velocity.y = jump_velocity
	_jump_cut_done = false
	jump_buffer = 0.0
	coyote = 0.0
	spring_launch = false
	skidding = false
	squash = Vector2(0.7, 1.3)
	idle_time = 0.0
	if in_air:
		_sfx("double_jump", 0.05)
		Fx.burst(self, global_position, Color.WHITE, 8, 90.0)
		Fx.ring(self, global_position + Vector2(0, -4), Color.WHITE, 22.0)
	else:
		_sfx("jump", 0.05)
		Fx.dust(self, global_position)


func _land(impact: float) -> void:
	var k := clampf(impact / MAX_FALL_SPEED, 0.0, 1.0)
	squash = Vector2(1.0 + 0.4 * k, 1.0 - 0.35 * k)
	Fx.dust(self, global_position, 4 + int(10.0 * k))
	if k > 0.35:
		_sfx("land", 0.08, 1.2 - k * 0.3)
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
			_sfx("step", 0.15, 1.0 if running else 0.85)
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
	var antenna_target := Vector2(clampf(-velocity.x / 60.0, -4.0, 4.0), clampf(velocity.y / 250.0, -1.5, 2.5))
	antenna_lag = antenna_lag.lerp(antenna_target + Vector2(sin(anim_time * 3.0) * 0.4, 0), minf(delta * 10.0, 1.0))
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
		velocity.y = JUMP_VELOCITY if _jump_held() else STOMP_BOUNCE
		_jump_cut_done = not _jump_held() # el rebote sin mantener el salto no se corta
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
	_sfx("power_up")
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
	_jump_cut_done = true
	shake = 6.0
	squash = Vector2(1.3, 0.7)
	_sfx("power_down")
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
	_sfx("die")
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
		_jump_cut_done = true
	var tween := create_tween()
	tween.tween_property(camera, "zoom", Vector2(1.15, 1.15), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# --- Dibujo: Pip es un robotito (estilo cartoon pulido; ver DrawKit) ---
# Cuerpo blanco metálico, visor oscuro con ojos LED que cambian según la expresión,
# antena con luz que se balancea, y botas cohete que echan llamas en el aire.

func _draw() -> void:
	var dir := signf(flip) if flip != 0.0 else facing
	if dead:
		draw_set_transform(Vector2(0, -14), PI, Vector2.ONE)
		_draw_body(Vector2(0, 14), dir)
		return
	if is_on_floor():
		DrawKit.contact_shadow(self, Vector2(0, 0), 13.0 * squash.x, 0.3)
	var lean := clampf(velocity.x / RUN_SPEED, -1.0, 1.0) * (0.1 if is_on_floor() else 0.05)
	if skidding:
		lean = -facing * 0.2
	var breathe := 1.0 + sin(anim_time * 2.5) * 0.02 if idle_time > 0.5 else 1.0
	var turn := 0.5 + 0.5 * absf(flip) # se estrecha al darse la vuelta
	draw_set_transform(Vector2.ZERO, lean, Vector2(squash.x * turn, squash.y * breathe))
	_draw_body(Vector2.ZERO, dir)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if idle_time > SLEEP_TIME:
		var font := ThemeDB.fallback_font
		for i in 3:
			var phase := fmod(anim_time * 0.5 + i / 3.0, 1.0)
			var pos := Vector2(10 + phase * 12.0, -44 - phase * 22.0)
			var size := int(8 + 6 * phase)
			draw_string_outline(font, pos, "z", HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, Color(OUTLINE, 1.0 - phase))
			draw_string(font, pos, "z", HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(LED, 1.0 - phase))


func _draw_body(origin: Vector2, f: float) -> void:
	var on_floor := is_on_floor()
	var running := absf(velocity.x) > WALK_SPEED + 20.0
	var walking := on_floor and absf(velocity.x) > 10.0
	var cycle := anim_time * (22.0 if running else 16.0)
	var step := sin(cycle) * 3.0 if walking else 0.0
	var bob := -absf(cos(cycle)) * 1.5 if walking else 0.0
	if not on_floor:
		step = 1.5
	var body := origin + Vector2(0, bob)

	# Llamas de las botas cohete (en el aire)
	if not on_floor and not dead:
		var power_flame := 1.0 if velocity.y < 0.0 or gliding else 0.55
		for x in [-5.5, 5.5]:
			var length := (6.0 + sin(anim_time * 40.0 + x) * 2.0) * power_flame
			var flame := PackedVector2Array([origin + Vector2(x - 3.2, -1), origin + Vector2(x, length + 1.0), origin + Vector2(x + 3.2, -1)])
			DrawKit.gradient_fill(self, flame, Color("fff6c2"), Color(1.0, 0.45, 0.1, 0.0))
			var core := PackedVector2Array([origin + Vector2(x - 1.6, -1), origin + Vector2(x, length * 0.55), origin + Vector2(x + 1.6, -1)])
			draw_colored_polygon(core, Color(1, 1, 1, 0.9))

	# Alas de la PLUMA (detrás del cuerpo)
	if power == Powers.Kind.FEATHER and not dead:
		var flap := sin(anim_time * (22.0 if gliding else 6.0)) * (6.0 if not on_floor else 2.0)
		for side in [-1.0, 1.0]:
			var wing := PackedVector2Array([
				body + Vector2(side * 9.0, -20),
				body + Vector2(side * 17.0, -26 - flap * 0.7),
				body + Vector2(side * 23.0, -28 - flap),
				body + Vector2(side * 22.0, -21 - flap * 0.5),
				body + Vector2(side * 18.0, -15),
				body + Vector2(side * 11.0, -14),
			])
			DrawKit.shape(self, wing, Color.WHITE, Color("cfe3f7"), 1.5)
			draw_line(body + Vector2(side * 12.0, -18), body + Vector2(side * 20.0, -24 - flap * 0.8), Color("a9c6e6"), 1.0, true)

	# Manos: se balancean al andar, arriba al saltar
	var swing := sin(cycle) * 4.0 if walking else 0.0
	var back_hand := body + Vector2(-f * 11.5 - f * swing * 0.5, -12 + swing * 0.3)
	var front_hand := body + Vector2(f * 11.5 + f * swing * 0.5, -12 - swing * 0.3)
	if not on_floor and not dead:
		var up := 4.0 if velocity.y < 0.0 else 0.0
		back_hand = body + Vector2(-f * 14.0, -23 - up)
		front_hand = body + Vector2(f * 14.0, -23 - up)
	elif skidding:
		back_hand = body + Vector2(f * 10.0, -21)
		front_hand = body + Vector2(f * 14.0, -17)
	_draw_hand(back_hand)

	# Botas estilizadas con suela oscura
	for foot in [Vector2(-5.0, -maxf(step, 0.0)), Vector2(5.0, -maxf(-step, 0.0))]:
		var boot_pos: Vector2 = origin + foot
		var boot := DrawKit.rounded_rect(Rect2(boot_pos + Vector2(-4.2 + f, -5.6), Vector2(8.4, 5.6)), 2.5, 1.2)
		DrawKit.shape(self, boot, ACCENT.lightened(0.2), ACCENT.darkened(0.25), 1.4)
		draw_rect(Rect2(boot_pos + Vector2(-3.6 + f, -1.4), Vector2(7.2, 1.2)), Color(OUTLINE, 0.7))
		draw_line(boot_pos + Vector2(-2.6 + f, -4.6), boot_pos + Vector2(1.2 + f, -4.6), Color(1, 1, 1, 0.35), 0.9)

	# Cuerpo: más alto y sobrio, con juntas, rejilla y una franja de color
	var shape := DrawKit.rounded_rect(Rect2(body + Vector2(-10.5, -33), Vector2(21, 28)), 6.0, 4.0)
	DrawKit.shape(self, shape, PEARL, METAL.darkened(0.08), 1.7)
	draw_polygon(PackedVector2Array([body + Vector2(-f * 10.0, -30), body + Vector2(-f * 6.5, -30), body + Vector2(-f * 6.5, -6), body + Vector2(-f * 10.0, -6)]),
		PackedColorArray([Color(0, 0, 0, 0.1), Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.1)])) # lado en sombra
	DrawKit.shape(self, DrawKit.rounded_rect(Rect2(body + Vector2(-10.5, -15.5), Vector2(21, 2.6)), 0.8), ACCENT.lightened(0.1), ACCENT.darkened(0.2), 0.0)
	draw_line(body + Vector2(-10, -12.2), body + Vector2(10, -12.2), Color(OUTLINE, 0.25), 0.8) # junta
	for k in 3: # rejilla de ventilación
		var y := -10.5 + k * 1.6
		draw_line(body + Vector2(-f * 8.0, y), body + Vector2(-f * 4.5, y), Color(OUTLINE, 0.35), 0.8)
	draw_circle(body + Vector2(f * 5.0, -9.5), 1.9, Color(OUTLINE, 0.6))
	draw_circle(body + Vector2(f * 5.0, -9.5), 1.1, ACCENT_WARM if fmod(anim_time, 1.6) < 1.3 or dead else ACCENT_WARM.darkened(0.5))
	draw_arc(body + Vector2(0, -24), 8.5, PI * 1.15, PI * 1.4, 8, Color(1, 1, 1, 0.55), 1.4, true)
	DrawKit.shine(self, body + Vector2(-6.5, -29.5), Vector2(2.0, 1.1), 0.75)
	# Articulaciones de los hombros
	for side in [-1.0, 1.0]:
		draw_circle(body + Vector2(side * 10.0, -19.5), 1.9, METAL.darkened(0.35))
		draw_circle(body + Vector2(side * 10.0, -19.5), 1.0, METAL)

	# Visor estrecho con reflejo
	var visor_center := body + Vector2(f * 1.5, -24.0)
	var visor := DrawKit.rounded_rect(Rect2(visor_center + Vector2(-8.5, -3.8), Vector2(17, 7.6)), 3.5)
	DrawKit.shape(self, visor, Color("2b3242"), Color("0e1118"), 1.3)
	_draw_face(visor_center, f, on_floor)
	draw_colored_polygon(PackedVector2Array([visor_center + Vector2(-7.5, -3.0), visor_center + Vector2(-4.5, -3.0), visor_center + Vector2(-7.0, 2.5), visor_center + Vector2(-8.0, 1.0)]),
		Color(1, 1, 1, 0.1)) # reflejo
	draw_line(visor_center + Vector2(-6.0, -3.1), visor_center + Vector2(6.0, -3.1), Color(1, 1, 1, 0.18), 0.8)

	_draw_hand(front_hand)

	# Mejoras
	if not dead:
		match power:
			Powers.Kind.HELMET:
				Powers.draw_dome(self, body + Vector2(0, -29), 12.5, Powers.HELMET_COLOR)
				var brim := DrawKit.rounded_rect(Rect2(body + Vector2(-13.5, -30.5), Vector2(27, 3.6)), 1.6)
				DrawKit.shape(self, brim, Powers.HELMET_COLOR, Powers.HELMET_COLOR.darkened(0.3), 1.4)
			Powers.Kind.MAGNET:
				Powers.draw_icon(self, Powers.Kind.MAGNET, body + Vector2(0, -50), 0.55)
				var pulse := fmod(anim_time, 1.0)
				draw_arc(body + Vector2(0, -18), 14.0 + pulse * 20.0, 0.0, TAU, 32, Color(1, 0.3, 0.35, 0.35 * (1.0 - pulse)), 1.2, true)

	# Antena fina: se balancea con inercia y tiene una luz pequeña que late
	var base := body + Vector2(-f * 4.0, -33 if power != Powers.Kind.HELMET else -41)
	var tip := base + Vector2(0, -6) + antenna_lag * 0.8
	draw_line(base, tip, OUTLINE, 1.8, true)
	draw_line(base, tip, METAL, 0.8, true)
	var glow := 0.6 + 0.4 * sin(anim_time * 5.0)
	var light := ANTENNA_LIGHT if not dead else Color("666a73")
	draw_circle(tip, 3.6, Color(light, 0.25 * glow))
	draw_circle(tip, 1.8, OUTLINE)
	draw_circle(tip, 1.2, light.lightened(0.2 * glow))


## Ojos LED dentro del visor; la boca solo aparece en algunas expresiones.
func _draw_face(center: Vector2, f: float, on_floor: bool) -> void:
	var sleeping := idle_time > SLEEP_TIME
	var hurt_face := invincible > 0.0
	var color := LED_HURT if (dead or hurt_face) else LED
	var look := Vector2(f * 0.8, clampf(velocity.y / 400.0, -1.0, 1.0) * 0.6)
	for side in [-1.0, 1.0]:
		var eye := center + Vector2(side * 3.7, -0.2)
		if dead:
			draw_line(eye + Vector2(-1.5, -1.5), eye + Vector2(1.5, 1.5), color, 1.2, true)
			draw_line(eye + Vector2(-1.5, 1.5), eye + Vector2(1.5, -1.5), color, 1.2, true)
		elif finished:
			draw_arc(eye + Vector2(0, 1.0), 1.8, PI, TAU, 8, color, 1.3, true) # ^ ^
		elif hurt_face:
			draw_polyline(PackedVector2Array([
				eye + Vector2(side * 1.7, -1.3), eye + Vector2(-side * 1.3, 0), eye + Vector2(side * 1.7, 1.3),
			]), color, 1.2, true)
		elif sleeping or blink > 0.0:
			draw_line(eye + Vector2(-1.6, 0.4), eye + Vector2(1.6, 0.4), Color(color, 0.5 if sleeping else 1.0), 1.1)
		else:
			var height := 3.4
			if not on_floor and velocity.y < -200.0:
				height = 4.2 # sorpresa al subir
			elif absf(velocity.x) > RUN_SPEED * 0.8:
				height = 2.4 # concentrado al correr
			var led := DrawKit.rounded_rect(Rect2(eye + look + Vector2(-1.1, -height / 2.0), Vector2(2.2, height)), 1.0)
			draw_colored_polygon(DrawKit.grow(led, 0.9), Color(color, 0.22))
			draw_colored_polygon(led, color)
	# Boca: solo en alegría, susto/daño o sorpresa
	var mouth := center + Vector2(0, 2.4)
	if dead or hurt_face:
		draw_arc(mouth + Vector2(0, 1.2), 1.3, PI + 0.4, TAU - 0.4, 6, color, 0.9, true)
	elif finished:
		draw_arc(mouth + Vector2(0, -0.6), 1.8, 0.2, PI - 0.2, 8, color, 1.0, true)
	elif not on_floor and absf(velocity.y) > 300.0:
		draw_arc(mouth, 0.8, 0.0, TAU, 8, color, 0.9, true)


func _draw_hand(pos: Vector2) -> void:
	DrawKit.shape(self, DrawKit.circle(pos, 2.6, 12), PEARL, METAL.darkened(0.15), 1.3)
	draw_circle(pos + Vector2(-0.7, -0.8), 0.7, Color(1, 1, 1, 0.7))
