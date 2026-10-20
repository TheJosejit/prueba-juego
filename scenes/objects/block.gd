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


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED # para el grano de los ladrillos


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0 + bump * 0.02, 1.0 - bump * 0.012)) # se deforma al rebotar
	var o := Vector2(0, -bump)
	var r := Rect2(o + Vector2(-16, -16), Vector2(32, 32))
	if not is_bonus():
		draw_colored_polygon(DrawKit.rounded_rect(r, 3.0), mortar)
		for row in 2:
			var y := -16.0 + row * 16.0
			var xs := [-16.0, 0.0, 16.0] if row == 0 else [-16.0, -8.0, 8.0, 16.0]
			for i in xs.size() - 1:
				_brick(Rect2(o + Vector2(xs[i], y), Vector2(xs[i + 1] - xs[i], 16)))
		DrawKit.grain(self, r.grow(-1.0), 0.35)
		draw_polyline(_closed(DrawKit.rounded_rect(r, 3.0)), OUTLINE, 1.5, true)
		return
	if used:
		DrawKit.shape(self, DrawKit.rounded_rect(r.grow(-0.5), 4.0), USED.lightened(0.15), USED.darkened(0.2), 1.5)
		DrawKit.grain(self, r.grow(-2.0), 0.25)
		_rivets(o, USED.darkened(0.35))
		return
	var t := Time.get_ticks_msec() / 1000.0
	# Resplandor que late detrás del bloque
	draw_colored_polygon(DrawKit.rounded_rect(r.grow(3.0 + sin(t * 4.0)), 7.0), Color(BONUS_LIGHT, 0.18))
	DrawKit.shape(self, DrawKit.rounded_rect(r.grow(-0.5), 4.0), BONUS.lightened(0.25), BONUS.darkened(0.25), 1.5)
	draw_polyline(DrawKit.rounded_rect(r.grow(-3.5), 2.5).slice(0, 12), Color(1, 1, 1, 0.35), 1.5, true) # bisel claro
	_rivets(o, BONUS.darkened(0.45))
	# Gema que palpita
	var pulse := 1.0 + sin(t * 5.0) * 0.1
	var gem := PackedVector2Array()
	for p in [Vector2(0, -9), Vector2(7, 0), Vector2(0, 9), Vector2(-7, 0)]:
		gem.append(o + p * pulse)
	DrawKit.shape(self, gem, Color.WHITE, BONUS_LIGHT, 1.5)
	draw_colored_polygon(PackedVector2Array([gem[0], gem[1], o]), Color(1, 1, 1, 0.9))
	draw_colored_polygon(PackedVector2Array([gem[2], gem[3], o]), Color(BONUS, 0.35))
	# Destello que recorre el bloque
	var shine := fmod(t * 0.8, 2.0) * 48.0 - 24.0
	if shine < 20.0:
		draw_line(o + Vector2(shine - 6, -13), o + Vector2(shine + 4, 13), Color(1, 1, 1, 0.3), 3.0)


func _brick(rect: Rect2) -> void:
	var inner := rect.grow(-1.0)
	DrawKit.gradient_fill(self, DrawKit.rounded_rect(inner, 2.0), brick.lightened(0.12), brick.darkened(0.18))
	draw_line(inner.position + Vector2(2, 1.2), Vector2(inner.end.x - 2, inner.position.y + 1.2), brick.lightened(0.35), 1.5)


func _rivets(o: Vector2, color: Color) -> void:
	for corner in [Vector2(-11, -11), Vector2(11, -11), Vector2(-11, 11), Vector2(11, 11)]:
		draw_circle(o + corner, 2.2, color)
		draw_circle(o + corner + Vector2(-0.6, -0.6), 0.9, Color(1, 1, 1, 0.5))


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	result.append(points[0])
	return result


func _process(_delta: float) -> void:
	if is_bonus() and not used:
		queue_redraw()
