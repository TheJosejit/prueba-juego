extends Area2D
## Bandera de meta. El origen del nodo está en la base del mástil.

const POLE_HEIGHT := 256.0

var reached := false
var flag_y := -POLE_HEIGHT + 12.0:
	set(value):
		flag_y = value
		queue_redraw()


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if reached or not body.is_in_group("player") or body.dead:
		return
	reached = true
	body.win()
	create_tween().tween_property(self, "flag_y", -40.0, 0.8)
	Game.level_complete()
	_fireworks()


## Fuegos artificiales de colores alrededor de la bandera.
func _fireworks() -> void:
	var colors := [Color("ffd23f"), Color("2ec4b6"), Color("ff8c42"), Color("9b5de5"), Color("ff4d6d")]
	for i in 6:
		var pos := global_position + Vector2(randf_range(-110, 110), -POLE_HEIGHT + randf_range(-60, 60))
		var color: Color = colors[i % colors.size()]
		Fx.burst(self, pos, color, 18, 200.0)
		Fx.sparkle(self, pos, Color.WHITE, 6)
		Fx.ring(self, pos, color, 40.0, 0.4)
		Sfx.play("firework", 0.15)
		await get_tree().create_timer(0.25, false).timeout


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	DrawKit.contact_shadow(self, Vector2.ZERO, 18.0, 0.25)
	DrawKit.shape(self, DrawKit.rounded_rect(Rect2(-14, -14, 28, 14), 3.0), Color("c2b6ab"), Color("7a6d62"), 1.6)
	draw_line(Vector2(-10, -12.5), Vector2(10, -12.5), Color(1, 1, 1, 0.4), 1.2)
	DrawKit.shape(self, DrawKit.rounded_rect(Rect2(-2.5, -POLE_HEIGHT, 5, POLE_HEIGHT - 13), 2.0), Color.WHITE, Color("aab4bf"), 1.4)
	var top := Vector2(0, -POLE_HEIGHT)
	draw_circle(top, 10.0, Color(1, 0.9, 0.4, 0.2))
	DrawKit.shape(self, DrawKit.circle(top, 6.0, 18), Color("fff1a8"), Color("e0a800"), 1.4)
	DrawKit.shine(self, top + Vector2(-2, -2), Vector2(1.8, 1.2), 0.8)
	# Bandera ondeando
	var t := Time.get_ticks_msec() / 1000.0
	var top_edge := PackedVector2Array()
	var bottom_edge := PackedVector2Array()
	for i in 9:
		var x := 3.0 + i * 4.5
		var wave := sin(t * 6.0 - i * 0.7) * 2.5 * (i / 8.0)
		top_edge.append(Vector2(x, flag_y + wave))
		bottom_edge.append(Vector2(x, flag_y + 26.0 - i * 1.2 + wave))
	bottom_edge.reverse()
	DrawKit.shape(self, top_edge + bottom_edge, Color("5fe0d3"), Color("1d9a8e"), 1.6)
	# Estrella
	var center := Vector2(19, flag_y + 12 + sin(t * 6.0 - 3.0) * 1.2)
	var star := PackedVector2Array()
	for i in 10:
		var r := 6.0 if i % 2 == 0 else 2.6
		var a := -PI / 2.0 + i * PI / 5.0
		star.append(center + Vector2(cos(a), sin(a)) * r)
	DrawKit.gradient_fill(self, star, Color.WHITE, Color("fff1a8"))
