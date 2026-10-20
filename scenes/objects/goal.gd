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
	for color in [Color("ffd23f"), Color("2ec4b6"), Color("ff8c42"), Color("9b5de5")]:
		Fx.burst(self, global_position + Vector2(0, -POLE_HEIGHT), color, 12, 220.0)
	Game.level_complete()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var outline := Color("1e1428")
	# Base
	draw_rect(Rect2(-14, -14, 28, 14), outline)
	draw_rect(Rect2(-13, -13, 26, 12), Color("8d7f74"))
	draw_rect(Rect2(-13, -13, 26, 3), Color("b3a69b"))
	# Mástil
	draw_rect(Rect2(-3, -POLE_HEIGHT, 6, POLE_HEIGHT - 13), outline)
	draw_rect(Rect2(-2, -POLE_HEIGHT, 4, POLE_HEIGHT - 13), Color("e6edf3"))
	draw_rect(Rect2(-2, -POLE_HEIGHT, 1.5, POLE_HEIGHT - 13), Color.WHITE)
	draw_circle(Vector2(0, -POLE_HEIGHT), 7.0, outline)
	draw_circle(Vector2(0, -POLE_HEIGHT), 6.0, Color("ffd23f"))
	draw_circle(Vector2(-2, -POLE_HEIGHT - 2), 2.0, Color("fff1a8"))
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
	var flag := top_edge + bottom_edge
	var flag_outline := flag.duplicate()
	flag_outline.append(flag[0])
	draw_colored_polygon(flag, Color("2ec4b6"))
	draw_polyline(flag_outline, outline, 1.5, true)
	# Estrella
	var center := Vector2(19, flag_y + 12 + sin(t * 6.0 - 3.0) * 1.2)
	var star := PackedVector2Array()
	for i in 10:
		var r := 6.0 if i % 2 == 0 else 2.6
		var a := -PI / 2.0 + i * PI / 5.0
		star.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(star, Color.WHITE)
