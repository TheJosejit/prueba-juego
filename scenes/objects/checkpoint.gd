extends Area2D
## Punto de control: al tocarlo, si mueres reapareces aquí en vez de al principio del nivel.
## El origen está en la base del poste.

var active := false
var flag_raise := 0.0:
	set(value):
		flag_raise = value
		queue_redraw()


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	if active:
		queue_redraw() # la bandera ondea


## El nivel lo llama si ya estaba activado (al reaparecer).
func set_active_silently() -> void:
	active = true
	flag_raise = 1.0


func _on_body_entered(body: Node2D) -> void:
	if active or not body.is_in_group("player"):
		return
	active = true
	Game.set_checkpoint(global_position)
	Sfx.play("checkpoint")
	Fx.burst(self, global_position + Vector2(0, -60), Color("7dff9b"), 14, 160.0)
	Fx.ring(self, global_position + Vector2(0, -40), Color("7dff9b"), 50.0, 0.45)
	Fx.popup(self, global_position + Vector2(0, -80), "¡PUNTO DE CONTROL!", Color("7dff9b"))
	create_tween().tween_property(self, "flag_raise", 1.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var outline := Color("1e1428")
	draw_rect(Rect2(-10, -6, 20, 6), outline)
	draw_rect(Rect2(-9, -5, 18, 4), Color("8d7f74"))
	draw_rect(Rect2(-2.5, -64, 5, 58), outline)
	draw_rect(Rect2(-1.5, -63, 3, 57), Color("e6edf3"))
	var y := lerpf(-20.0, -60.0, flag_raise)
	var color := Color("38d26b") if active else Color("9aa4ad")
	var wave := sin(Time.get_ticks_msec() / 150.0) * 2.0 if active else 0.0
	var flag := PackedVector2Array([Vector2(2, y), Vector2(22, y + 6 + wave), Vector2(2, y + 12)])
	draw_colored_polygon(flag, color)
	draw_polyline(PackedVector2Array([flag[0], flag[1], flag[2]]), outline, 1.5, true)
	draw_circle(Vector2(0, -64), 3.5, Color("ffd23f") if active else Color("c9d1d9"))
