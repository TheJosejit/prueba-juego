extends CharacterBody2D
## Mejora que sale de un bloque sorpresa. Sube desde el bloque y luego se desliza por el suelo
## (la pluma cae flotando). El jugador la coge al tocarla. El origen del nodo está en su base.

const SPEED := 70.0
const GRAVITY := 900.0

var kind: Powers.Kind = Powers.Kind.HELMET
var direction := 1.0
var emerging := true
var anim_time := 0.0
var sparkle_timer := 0.0


func _ready() -> void:
	$Grab.body_entered.connect(_on_grab_body_entered)
	z_index = -1 # sale "desde dentro" del bloque
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "position:y", position.y - 32.0, 0.45)
	tween.tween_callback(func() -> void:
		emerging = false
		z_index = 0
	)


func _physics_process(delta: float) -> void:
	if emerging:
		return
	var floaty := kind == Powers.Kind.FEATHER
	velocity.x = direction * SPEED * (0.7 if floaty else 1.0)
	velocity.y = minf(velocity.y + GRAVITY * (0.2 if floaty else 1.0) * delta, 90.0 if floaty else 600.0)
	move_and_slide()
	if is_on_wall():
		direction = signf(get_wall_normal().x)
	if position.y > 3000.0:
		queue_free()


func _process(delta: float) -> void:
	anim_time += delta
	sparkle_timer -= delta
	if sparkle_timer <= 0.0 and not emerging:
		sparkle_timer = 0.15
		Fx.sparkle(self, global_position + Vector2(randf_range(-8, 8), -14), Color("fff1a8"), 2)
	queue_redraw()


func _on_grab_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("give_power") and not body.dead:
		body.give_power(kind)
		queue_free()


func _draw() -> void:
	var center := Vector2(0, -14 + sin(anim_time * 5.0) * 1.5)
	var glow := 0.18 + sin(anim_time * 6.0) * 0.07
	for k in 3:
		draw_circle(center, 9.0 + k * 4.0, Color(1, 1, 0.8, glow * 0.6))
	if is_on_floor():
		DrawKit.contact_shadow(self, Vector2.ZERO, 9.0, 0.2)
	Powers.draw_icon(self, kind, center, 1.0)
