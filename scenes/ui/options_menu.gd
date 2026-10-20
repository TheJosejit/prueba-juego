extends Control
## Panel de opciones. Lo usan el menú principal y el menú de pausa.
## Los cambios se aplican al momento y se guardan al cerrar.

signal closed

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var shake_check: CheckButton = %ShakeCheck
@onready var back_button: Button = %BackButton


func _ready() -> void:
	hide()
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	shake_check.toggled.connect(func(on: bool) -> void: Settings.screen_shake = on)
	back_button.pressed.connect(close)


func open() -> void:
	music_slider.set_value_no_signal(Settings.music_volume)
	sfx_slider.set_value_no_signal(Settings.sfx_volume)
	fullscreen_check.set_pressed_no_signal(Settings.fullscreen)
	shake_check.set_pressed_no_signal(Settings.screen_shake)
	show()
	music_slider.grab_focus()


func close() -> void:
	Settings.save_settings()
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()


func _on_music_changed(value: float) -> void:
	Settings.music_volume = value
	Settings.apply()


func _on_sfx_changed(value: float) -> void:
	Settings.sfx_volume = value
	Settings.apply()
	Sfx.play("coin") # para oír cómo queda


func _on_fullscreen_toggled(on: bool) -> void:
	Settings.fullscreen = on
	Settings.apply()
