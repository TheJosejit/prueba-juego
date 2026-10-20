extends Node
## Autoload "Settings": opciones del jugador. Se guardan en user://settings.cfg.
## F11 o Alt+Enter cambian entre pantalla completa y ventana en cualquier momento.

const PATH := "user://settings.cfg"

var music_volume := 0.8
var sfx_volume := 0.8
var fullscreen := true # pantalla completa sin bordes (en el monitor actual)
var screen_shake := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var alt_enter: bool = event.physical_keycode == KEY_ENTER and event.alt_pressed
		var toggle: bool = event.physical_keycode == KEY_F11 or alt_enter
		if toggle:
			fullscreen = not fullscreen
			apply()
			save_settings()
			get_viewport().set_input_as_handled()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	music_volume = cfg.get_value("audio", "music_volume", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx_volume", sfx_volume)
	fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	screen_shake = cfg.get_value("video", "screen_shake", screen_shake)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "screen_shake", screen_shake)
	cfg.save(PATH)


func apply() -> void:
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func _set_bus_volume(bus_name: String, volume: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus == -1:
		return
	AudioServer.set_bus_mute(bus, volume <= 0.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))
