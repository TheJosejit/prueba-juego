extends Node
## Autoload "Game": estado global de la partida (puntos, monedas, vidas) y controles.

signal stats_changed
signal message(text: String)

const START_LIVES := 3
const COINS_PER_LIFE := 50

var score := 0
var coins := 0
var lives := START_LIVES


func _ready() -> void:
	_bind("move_left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], -1.0)
	_bind("move_right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], 1.0)
	_bind("jump", [KEY_SPACE, KEY_W, KEY_UP], [JOY_BUTTON_A])
	_bind("run", [KEY_SHIFT, KEY_J], [JOY_BUTTON_X])


func reset() -> void:
	score = 0
	coins = 0
	lives = START_LIVES
	stats_changed.emit()


func add_score(points: int) -> void:
	score += points
	stats_changed.emit()


func add_coin() -> void:
	coins += 1
	score += 100
	Sfx.play("coin")
	if coins >= COINS_PER_LIFE:
		coins -= COINS_PER_LIFE
		lives += 1
		Sfx.play("one_up")
	stats_changed.emit()


func player_died() -> void:
	lives -= 1
	stats_changed.emit()
	if lives <= 0:
		message.emit("GAME OVER")
		Sfx.play("game_over")
		await get_tree().create_timer(2.5).timeout
		reset()
	get_tree().reload_current_scene()


func level_complete() -> void:
	add_score(1000)
	Sfx.stop_music()
	Sfx.play("win")
	message.emit("¡NIVEL COMPLETADO!")
	await get_tree().create_timer(3.0).timeout
	reset()
	get_tree().reload_current_scene()


# Las acciones se crean por código para no tener que tocar el mapa de entrada del proyecto.
func _bind(action: StringName, keys: Array[Key], buttons: Array[JoyButton], axis_dir := 0.0) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)
	for button in buttons:
		var ev := InputEventJoypadButton.new()
		ev.button_index = button
		InputMap.action_add_event(action, ev)
	if axis_dir != 0.0:
		var ev := InputEventJoypadMotion.new()
		ev.axis = JOY_AXIS_LEFT_X
		ev.axis_value = axis_dir
		InputMap.action_add_event(action, ev)
