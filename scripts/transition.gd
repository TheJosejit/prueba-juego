extends CanvasLayer
## Autoload "Transition": la pantalla se cierra en un círculo (centrado en Pip si está en pantalla),
## cambia de escena y se vuelve a abrir. Uso: Transition.change_scene("res://...") o
## Transition.change_scene() para recargar la escena actual.

const OPEN_RADIUS := 2.2
const SHADER_CODE := """
shader_type canvas_item;
uniform float radius = 2.2;
uniform vec2 center = vec2(0.5, 0.5);
uniform float aspect = 1.7778;
uniform vec4 color : source_color = vec4(0.07, 0.04, 0.12, 1.0);

void fragment() {
	vec2 d = UV - center;
	d.x *= aspect;
	float alpha = smoothstep(radius - 0.01, radius, length(d));
	COLOR = vec4(color.rgb, color.a * alpha);
}
"""

var busy := false
var _rect: ColorRect
var _material: ShaderMaterial


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shader := Shader.new()
	shader.code = SHADER_CODE
	_material = ShaderMaterial.new()
	_material.shader = shader
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _material
	add_child(_rect)
	_set_radius(OPEN_RADIUS)


func change_scene(path := "") -> void:
	if busy:
		return
	busy = true
	_aim_at_player()
	await _animate(OPEN_RADIUS, 0.0, 0.35)
	get_tree().paused = false
	if path == "":
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	_aim_at_player()
	await _animate(0.0, OPEN_RADIUS, 0.45)
	busy = false


func _animate(from: float, to: float, time: float) -> void:
	var tween := create_tween().set_ignore_time_scale(true)
	tween.tween_method(_set_radius, from, to, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func _set_radius(value: float) -> void:
	_material.set_shader_parameter("radius", value)
	_rect.visible = value < OPEN_RADIUS


func _aim_at_player() -> void:
	var size := get_viewport().get_visible_rect().size
	var center := Vector2(0.5, 0.5)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		center = (player.get_global_transform_with_canvas().origin + Vector2(0, -16)) / size
		center = center.clamp(Vector2(0.05, 0.05), Vector2(0.95, 0.95))
	_material.set_shader_parameter("center", center)
	_material.set_shader_parameter("aspect", size.x / size.y)
