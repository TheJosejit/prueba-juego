extends CharacterBody2D
## Blob: camina en línea recta, se da la vuelta al chocar con una pared y muere si lo pisan.
## El origen del nodo está en su base.

const SPEED := 50.0
const GRAVITY := 1500.0
const COLOR := Color("9b5de5")
const COLOR_DARK := Color("6a31b5")

var direction := -1.0
var active := false # empieza a moverse cuando entra en pantalla
var dead := false
var anim_time := 0.0


func _ready() -> void:
	var notifier := VisibleOnScreenNotifier2D.new()
	notifier.rect = Rect2(-16, -24, 32, 24)
	notifier.screen_entered.connect(func() -> void: active = true)
	add_child(notifier)


func _physics_process(delta: float) -> void:
	if not active or dead:
		return
	velocity.x = direction * SPEED
	velocity.y = minf(velocity.y + GRAVITY * delta, 700.0)
	move_and_slide()
	if is_on_wall():
		direction = signf(get_wall_normal().x)
	if position.y > 2000.0:
		queue_free()


func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()


func stomp() -> void:
	if dead:
		return
	dead = true
	$CollisionShape2D.set_deferred("disabled", true)
	Game.add_score(200)
	Sfx.play("stomp", 0.1)
	Fx.burst(self, global_position + Vector2(0, -8), COLOR, 12, 140.0)
	Fx.popup(self, global_position + Vector2(0, -28), "+200")
	await get_tree().create_timer(0.5, false).timeout
	queue_free()


func _draw() -> void:
	if dead:
		draw_rect(Rect2(-15, -5, 30, 5), COLOR_DARK)
		return
	var wobble := sin(anim_time * 10.0) * 1.5 if active else 0.0
	var points := PackedVector2Array()
	for i in 17:
		var angle := PI + PI * i / 16.0
		points.append(Vector2(cos(angle) * (14.0 + wobble), sin(angle) * (19.0 - wobble)))
	draw_colored_polygon(points, COLOR)
	draw_rect(Rect2(-14 - wobble, -3, 28 + wobble * 2.0, 3), COLOR_DARK)
	for side in [-1.0, 1.0]:
		var eye := Vector2(direction * 3.0 + side * 4.5, -11)
		draw_circle(eye, 3.5, Color.WHITE)
		draw_circle(eye + Vector2(direction * 1.3, 0.5), 1.8, Color.BLACK)
	# Cejas enfadadas
	draw_line(Vector2(direction * 3.0 - 8, -17), Vector2(direction * 3.0 - 2, -15), Color.BLACK, 1.5)
	draw_line(Vector2(direction * 3.0 + 8, -17), Vector2(direction * 3.0 + 2, -15), Color.BLACK, 1.5)
