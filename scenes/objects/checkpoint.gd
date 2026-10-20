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
	DrawKit.contact_shadow(self, Vector2.ZERO, 12.0, 0.22)
	DrawKit.shape(self, DrawKit.rounded_rect(Rect2(-9, -6, 18, 6), 2.0), Color("b3a69b"), Color("6f6359"), 1.4)
	DrawKit.shape(self, DrawKit.rounded_rect(Rect2(-1.8, -63, 3.6, 57), 1.5), Color.WHITE, Color("aab4bf"), 1.2)
	var y := lerpf(-20.0, -60.0, flag_raise)
	var color := Color("38d26b") if active else Color("9aa4ad")
	var t := Time.get_ticks_msec() / 1000.0
	var top_edge := PackedVector2Array()
	var bottom_edge := PackedVector2Array()
	for i in 6:
		var x := 2.0 + i * 4.0
		var wave := sin(t * 7.0 - i * 0.8) * 1.6 * (i / 5.0) if active else 0.0
		top_edge.append(Vector2(x, y + i * 1.2 + wave))
		bottom_edge.append(Vector2(x, y + 13.0 - i * 1.2 + wave))
	bottom_edge.reverse()
	DrawKit.shape(self, top_edge + bottom_edge, color.lightened(0.25), color.darkened(0.15), 1.4)
	var ball := Vector2(0, -64)
	DrawKit.shape(self, DrawKit.circle(ball, 3.6, 14), Color("fff1a8") if active else Color.WHITE,
		Color("e0a800") if active else Color("aab4bf"), 1.2)
	if active:
		draw_circle(ball, 7.0, Color(1, 0.95, 0.6, 0.2 + 0.1 * sin(t * 5.0)))
