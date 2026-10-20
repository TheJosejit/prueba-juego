extends Control
## Menú principal: continuar la partida guardada, empezar una nueva, opciones y salir.

@onready var continue_button: Button = %ContinueButton
@onready var new_game_button: Button = %NewGameButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var buttons: Control = %Buttons
@onready var options: Control = $OptionsMenu
@onready var scenery: Node2D = $Scenery
@onready var title: Control = %Title


func _ready() -> void:
	Sfx.play_music()
	title.physics_interpolation_mode = PHYSICS_INTERPOLATION_MODE_OFF # se anima cada fotograma
	var screen := get_viewport_rect().size
	scenery.ground_y = screen.y
	scenery.width = screen.x + 200.0

	continue_button.visible = Game.has_save()
	if Game.has_save():
		continue_button.text = "Continuar  (%s)" % Game.save_summary()
	quit_button.visible = not OS.has_feature("web")

	continue_button.pressed.connect(Game.continue_game)
	new_game_button.pressed.connect(Game.new_game)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(get_tree().quit)
	options.closed.connect(_on_options_closed)

	(continue_button if continue_button.visible else new_game_button).grab_focus()


func _process(_delta: float) -> void:
	title.position.y = sin(Time.get_ticks_msec() / 300.0) * 4.0


func _on_options_pressed() -> void:
	buttons.hide()
	options.open()


func _on_options_closed() -> void:
	buttons.show()
	options_button.grab_focus()
