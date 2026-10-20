extends StaticBody2D
## Bloque de ladrillo. Si has_coin es true es un bloque sorpresa: suelta una moneda al golpearlo desde abajo.

const CoinPop := preload("res://scenes/objects/coin_pop.gd")
const BRICK := Color("c0583c")
const MORTAR := Color("7a2f1d")
const BONUS := Color("8a5cf6")
const BONUS_LIGHT := Color("c9b5ff")
const USED := Color("8d7f74")

var has_coin := false:
	set(value):
		has_coin = value
		queue_redraw()
var used := false
var bump := 0.0:
	set(value):
		bump = value
		queue_redraw()


func hit_from_below() -> void:
	var tween := create_tween()
	tween.tween_property(self, "bump", 8.0, 0.06)
	tween.tween_property(self, "bump", 0.0, 0.08)
	if has_coin and not used:
		used = true
		var pop := CoinPop.new()
		pop.position = position + Vector2(0, -32)
		get_parent().add_child(pop)
		Game.add_coin()


func _draw() -> void:
	var r := Rect2(-16, -16 - bump, 32, 32)
	if not has_coin:
		draw_rect(r, BRICK)
		draw_rect(r, MORTAR, false, 2.0)
		draw_line(Vector2(-16, -bump), Vector2(16, -bump), MORTAR, 2.0)
		draw_line(Vector2(0, -16 - bump), Vector2(0, -bump), MORTAR, 2.0)
		draw_line(Vector2(-8, -bump), Vector2(-8, 16 - bump), MORTAR, 2.0)
		draw_line(Vector2(8, -bump), Vector2(8, 16 - bump), MORTAR, 2.0)
	elif used:
		draw_rect(r, USED)
		draw_rect(r, USED.darkened(0.4), false, 2.0)
	else:
		draw_rect(r, BONUS)
		draw_rect(r, BONUS.darkened(0.4), false, 2.0)
		var pulse := 1.0 + sin(Time.get_ticks_msec() / 200.0) * 0.12
		var gem := PackedVector2Array([
			Vector2(0, -9) * pulse, Vector2(7, 0) * pulse, Vector2(0, 9) * pulse, Vector2(-7, 0) * pulse,
		])
		for i in gem.size():
			gem[i].y -= bump
		draw_colored_polygon(gem, BONUS_LIGHT)


func _process(_delta: float) -> void:
	if has_coin and not used:
		queue_redraw()
