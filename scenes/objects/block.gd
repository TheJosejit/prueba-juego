class_name Block
extends StaticBody2D
## Bloque que se golpea desde abajo.
##   - Ladrillo (content NONE): rebota; con el CASCO se rompe.
##   - Bloque sorpresa: suelta una moneda (COIN) o una mejora (ITEM) una sola vez.
## Al golpearlo, los enemigos que estén encima salen despedidos.

enum Content { NONE, COIN, ITEM }

const CoinPop := preload("res://scenes/objects/coin_pop.gd")
const PICKUP_SCENE := preload("res://scenes/objects/pickup.tscn")
const BONUS := Color("8a5cf6")
const BONUS_LIGHT := Color("d7c8ff")
const USED := Color("8d7f74")
const OUTLINE := Color("1e1428")

var content := Content.NONE:
	set(value):
		content = value
		queue_redraw()
var item: Powers.Kind = Powers.Kind.NONE
var brick := Color("c0583c")
var mortar := Color("6e2a1a")
var used := false
var bump := 0.0:
	set(value):
		bump = value
		queue_redraw()


func is_bonus() -> bool:
	return content != Content.NONE


func hit_from_below(by: Node = null) -> void:
	if not is_bonus() and by and by.get("power") == Powers.Kind.HELMET:
		_break()
		return
	var tween := create_tween()
	tween.tween_property(self, "bump", 8.0, 0.06)
	tween.tween_property(self, "bump", 0.0, 0.08)
	Sfx.play("bump", 0.05)
	_hit_things_on_top()
	if not is_bonus() or used:
		Fx.burst(self, global_position + Vector2(0, -16), brick if not is_bonus() else USED, 4, 70.0)
		return
	used = true
	if content == Content.COIN:
		Fx.popup(self, global_position + Vector2(0, -60), "+100", Color("ffd23f"))
		var pop := CoinPop.new()
		pop.position = position + Vector2(0, -32)
		get_parent().add_child(pop)
		Game.add_coin()
	else:
		var pickup: Node2D = PICKUP_SCENE.instantiate()
		pickup.kind = item
		pickup.position = position + Vector2(0, 16)
		get_parent().add_child(pickup)
		Sfx.play("item_appear")
	Fx.burst(self, global_position + Vector2(0, -16), BONUS_LIGHT, 8, 90.0)


func _break() -> void:
	Sfx.play("break", 0.08)
	Fx.debris(self, global_position, brick, 10)
	Fx.popup(self, global_position + Vector2(0, -24), "+50")
	Game.add_score(50)
	_hit_things_on_top()
	queue_free()


## Los enemigos que estén justo encima del bloque salen despedidos.
func _hit_things_on_top() -> void:
	var top := global_position.y - 16.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.dead and absf(enemy.global_position.x - global_position.x) < 26.0 \
				and absf(enemy.global_position.y - top) < 6.0:
			enemy.knock_out()
	Fx.ring(self, global_position + Vector2(0, -16), Color(1, 1, 1, 0.8), 22.0, 0.2)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0 + bump * 0.02, 1.0 - bump * 0.012)) # se deforma al rebotar
	var o := Vector2(0, -bump)
	var r := Rect2(o + Vector2(-16, -16), Vector2(32, 32))
	if not is_bonus():
		draw_rect(r, mortar)
		for row in 2:
			var y := -16.0 + row * 16.0
			var xs := [-16.0, 0.0, 16.0] if row == 0 else [-16.0, -8.0, 8.0, 16.0]
			for i in xs.size() - 1:
				_brick(Rect2(o + Vector2(xs[i], y), Vector2(xs[i + 1] - xs[i], 16)))
		return
	if used:
		_bevel(r, USED)
		for corner in [Vector2(-10, -10), Vector2(10, -10), Vector2(-10, 10), Vector2(10, 10)]:
			draw_circle(o + corner, 2.0, USED.darkened(0.4))
		return
	_bevel(r, BONUS)
	var t := Time.get_ticks_msec() / 1000.0
	var pulse := 1.0 + sin(t * 5.0) * 0.1
	var gem := PackedVector2Array()
	for p in [Vector2(0, -9), Vector2(7, 0), Vector2(0, 9), Vector2(-7, 0)]:
		gem.append(o + p * pulse)
	var gem_outline := gem.duplicate()
	gem_outline.append(gem[0])
	draw_colored_polygon(gem, BONUS_LIGHT)
	draw_polyline(gem_outline, BONUS.darkened(0.5), 1.5, true)
	draw_colored_polygon(PackedVector2Array([o + Vector2(0, -9) * pulse, o + Vector2(7, 0) * pulse, o]), Color.WHITE)
	# Destello que recorre el bloque
	var shine := fmod(t * 0.8, 2.0) * 48.0 - 24.0
	if shine < 20.0:
		draw_line(o + Vector2(shine - 6, -13), o + Vector2(shine + 4, 13), Color(1, 1, 1, 0.35), 3.0)


func _brick(rect: Rect2) -> void:
	var inner := rect.grow(-1.0)
	draw_rect(inner, brick)
	draw_rect(Rect2(inner.position, Vector2(inner.size.x, 2)), brick.lightened(0.25))
	draw_rect(Rect2(inner.position + Vector2(0, inner.size.y - 2), Vector2(inner.size.x, 2)), brick.darkened(0.25))


func _bevel(r: Rect2, color: Color) -> void:
	draw_rect(r, OUTLINE)
	var inner := r.grow(-1.5)
	draw_rect(inner, color.darkened(0.25))
	draw_rect(Rect2(inner.position, inner.size - Vector2(3, 3)), color.lightened(0.2))
	draw_rect(Rect2(inner.position + Vector2(3, 3), inner.size - Vector2(6, 6)), color)


func _process(_delta: float) -> void:
	if is_bonus() and not used:
		queue_redraw()
