extends Node
## Autoload "Game": estado global de la partida (puntos, monedas, vidas), guardado y controles.

signal stats_changed
signal message(text: String)

const START_LIVES := 3
const COINS_PER_LIFE := 50
const SAVE_PATH := "user://savegame.cfg"
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
## Niveles en orden. Para añadir un nivel nuevo, añade aquí su escena.
const LEVELS := [
	"res://scenes/levels/level_1.tscn",
]

var score := 0
var coins := 0
var lives := START_LIVES
var current_level := 0


func _ready() -> void:
	_bind("move_left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], -1.0)
	_bind("move_right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], 1.0)
	_bind("jump", [KEY_SPACE, KEY_W, KEY_UP], [JOY_BUTTON_A])
	_bind("run", [KEY_SHIFT, KEY_J], [JOY_BUTTON_X])
	_bind("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START])


func reset() -> void:
	score = 0
	coins = 0
	lives = START_LIVES
	current_level = 0
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
		await get_tree().create_timer(2.5, false).timeout
		reset()
		go_to_menu()
	else:
		get_tree().reload_current_scene()


func level_complete() -> void:
	add_score(1000)
	Sfx.stop_music()
	Sfx.play("win")
	message.emit("¡NIVEL COMPLETADO!")
	await get_tree().create_timer(3.0, false).timeout
	if current_level + 1 < LEVELS.size():
		current_level += 1
		save_game() # autoguardado al pasar de nivel
		_change_scene(LEVELS[current_level])
	else:
		message.emit("¡JUEGO COMPLETADO!")
		await get_tree().create_timer(2.5, false).timeout
		reset()
		go_to_menu()


# --- Partidas y escenas ---

func new_game() -> void:
	reset()
	_change_scene(LEVELS[0])


func continue_game() -> void:
	if load_game():
		_change_scene(LEVELS[current_level])


func go_to_menu() -> void:
	_change_scene(MENU_SCENE)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Guarda nivel, puntos, monedas y vidas. Al cargar se empieza desde el principio del nivel.
func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "level", current_level)
	cfg.set_value("game", "score", score)
	cfg.set_value("game", "coins", coins)
	cfg.set_value("game", "lives", lives)
	cfg.set_value("game", "saved_at", Time.get_datetime_string_from_system(false, true))
	cfg.save(SAVE_PATH)


func load_game() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	current_level = clampi(cfg.get_value("game", "level", 0), 0, LEVELS.size() - 1)
	score = cfg.get_value("game", "score", 0)
	coins = cfg.get_value("game", "coins", 0)
	lives = maxi(cfg.get_value("game", "lives", START_LIVES), 1)
	stats_changed.emit()
	return true


## Texto corto para el menú, por ejemplo "Nivel 1 · 1200 pts · 3 vidas".
func save_summary() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return ""
	return "Nivel %d · %d pts · %d vidas" % [
		cfg.get_value("game", "level", 0) + 1,
		cfg.get_value("game", "score", 0),
		cfg.get_value("game", "lives", START_LIVES),
	]


func _change_scene(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)


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
