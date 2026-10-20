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


func _draw() -> void:
	draw_rect(Rect2(-12, -12, 24, 12), Color("6e7781"))
	draw_rect(Rect2(-2, -POLE_HEIGHT, 4, POLE_HEIGHT - 12), Color("e6edf3"))
	draw_circle(Vector2(0, -POLE_HEIGHT), 6.0, Color("ffd23f"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(2, flag_y), Vector2(34, flag_y + 12), Vector2(2, flag_y + 24),
	]), Color("2ec4b6"))
