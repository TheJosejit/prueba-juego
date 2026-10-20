extends Node
## Autoload "Game": estado global de la partida (puntos, monedas, vidas, mejora, punto de control),
## lista de niveles, guardado y controles.

signal stats_changed
signal message(text: String)

const START_LIVES := 3
const COINS_PER_LIFE := 50
const SAVE_PATH := "user://savegame.cfg"
const PROGRESS_PATH := "user://progress.cfg"
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
## Niveles en orden. Para añadir un nivel nuevo, añade aquí su escena y su nombre.
const LEVELS := [
	{"scene": "res://scenes/levels/level_1.tscn", "name": "Pradera Soleada"},
	{"scene": "res://scenes/levels/level_2.tscn", "name": "Cueva de Cristal"},
	{"scene": "res://scenes/levels/level_3.tscn", "name": "Islas del Cielo"},
	{"scene": "res://scenes/levels/level_4.tscn", "name": "Volcán Rugiente"},
]

var score := 0
var coins := 0
var lives := START_LIVES
var current_level := 0
var power: Powers.Kind = Powers.Kind.NONE
var checkpoint_level := -1
var checkpoint_pos := Vector2.ZERO
var unlocked_levels := 1 # cuántos niveles se pueden elegir en el menú


func _ready() -> void:
	_bind("move_left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], -1.0)
	_bind("move_right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], 1.0)
	_bind("jump", [KEY_SPACE, KEY_W, KEY_UP], [JOY_BUTTON_A])
	_bind("run", [KEY_SHIFT, KEY_J], [JOY_BUTTON_X])
	_bind("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START])
	_load_progress()


func reset() -> void:
	score = 0
	coins = 0
	lives = START_LIVES
	current_level = 0
	power = Powers.Kind.NONE
	clear_checkpoint()
	stats_changed.emit()


func add_score(points: int) -> void:
	score += points
	stats_changed.emit()


func add_coin() -> void:
	coins += 1
	score += 100
	Sfx.play("coin", 0.03)
	if coins >= COINS_PER_LIFE:
		coins -= COINS_PER_LIFE
		lives += 1
		Sfx.play("one_up")
		message.emit("¡VIDA EXTRA!")
		get_tree().create_timer(1.5, false).timeout.connect(func() -> void: message.emit(""))
	stats_changed.emit()


func set_power(kind: Powers.Kind) -> void:
	power = kind
	stats_changed.emit()


func set_checkpoint(pos: Vector2) -> void:
	checkpoint_level = current_level
	checkpoint_pos = pos


func clear_checkpoint() -> void:
	checkpoint_level = -1


func has_checkpoint() -> bool:
	return checkpoint_level == current_level


## Lo llama cada nivel al empezar. Devuelve su posición en LEVELS (o -1 si no está en la lista).
func enter_level(scene_path: String) -> int:
	for i in LEVELS.size():
		if LEVELS[i].scene == scene_path:
			if i != current_level: # p. ej. al probar un nivel suelto con F6
				current_level = i
				clear_checkpoint()
			return i
	return -1


func level_name(index: int) -> String:
	return LEVELS[index].name if index >= 0 and index < LEVELS.size() else ""


func player_died() -> void:
	lives -= 1
	power = Powers.Kind.NONE
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
	clear_checkpoint()
	Sfx.stop_music()
	Sfx.play("win")
	message.emit("¡NIVEL COMPLETADO!")
	_unlock(current_level + 1)
	await get_tree().create_timer(3.0, false).timeout
	if current_level + 1 < LEVELS.size():
		current_level += 1
		save_game() # autoguardado al pasar de nivel
		_change_scene(LEVELS[current_level].scene)
	else:
		message.emit("¡JUEGO COMPLETADO!")
		await get_tree().create_timer(3.0, false).timeout
		reset()
		go_to_menu()


# --- Partidas y escenas ---

func new_game() -> void:
	start_level(0)


## Empieza un nivel desde cero (puntos a 0 y 3 vidas). Lo usa el selector de niveles.
func start_level(index: int) -> void:
	reset()
	current_level = index
	_change_scene(LEVELS[index].scene)


func restart_level() -> void:
	clear_checkpoint()
	get_tree().paused = false
	get_tree().reload_current_scene()


func continue_game() -> void:
	if load_game():
		_change_scene(LEVELS[current_level].scene)


func go_to_menu() -> void:
	_change_scene(MENU_SCENE)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Guarda nivel, puntos, monedas, vidas y mejora. Al cargar se empieza desde el principio del nivel.
func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "level", current_level)
	cfg.set_value("game", "score", score)
	cfg.set_value("game", "coins", coins)
	cfg.set_value("game", "lives", lives)
	cfg.set_value("game", "power", power)
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
	power = clampi(cfg.get_value("game", "power", 0), 0, Powers.Kind.size() - 1) as Powers.Kind
	clear_checkpoint()
	stats_changed.emit()
	return true


## Texto corto para el menú, por ejemplo "Cueva de Cristal · 1200 pts · 3 vidas".
func save_summary() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return ""
	return "%s · %d pts · %d vidas" % [
		level_name(cfg.get_value("game", "level", 0)),
		cfg.get_value("game", "score", 0),
		cfg.get_value("game", "lives", START_LIVES),
	]


func _unlock(count: int) -> void:
	count = mini(count + 1, LEVELS.size())
	if count > unlocked_levels:
		unlocked_levels = count
		var cfg := ConfigFile.new()
		cfg.set_value("progress", "unlocked_levels", unlocked_levels)
		cfg.save(PROGRESS_PATH)


func _load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PROGRESS_PATH) == OK:
		unlocked_levels = clampi(cfg.get_value("progress", "unlocked_levels", 1), 1, LEVELS.size())


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
