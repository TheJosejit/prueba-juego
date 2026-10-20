extends Area2D
## Moneda: suma puntos al tocarla.

var anim_time := 0.0


func _ready() -> void:
	anim_time = position.x * 0.01 # cada moneda gira desfasada
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Game.add_coin()
		queue_free()


func _draw() -> void:
	var width := maxf(absf(cos(anim_time * 3.0)), 0.15)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(width, 1.0))
	draw_circle(Vector2.ZERO, 9.0, Color("ffd23f"))
	draw_circle(Vector2.ZERO, 6.0, Color("ffe98a"))
	draw_rect(Rect2(-1.5, -5, 3, 10), Color("e0a800"))
