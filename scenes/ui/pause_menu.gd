extends CanvasLayer
## Menú de pausa (Esc / P / Start). Lo añade automáticamente cada nivel (ver level.gd).

@onready var panel: Control = $Panel
@onready var dim: Control = $Dim
@onready var resume_button: Button = %ResumeButton
@onready var save_button: Button = %SaveButton
@onready var options_button: Button = %OptionsButton
@onready var menu_button: Button = %MenuButton
@onready var status: Label = %Status
@onready var options: Control = $OptionsMenu


func _ready() -> void:
	_set_open(false)
	resume_button.pressed.connect(resume)
	save_button.pressed.connect(_on_save_pressed)
	options_button.pressed.connect(_on_options_pressed)
	menu_button.pressed.connect(Game.go_to_menu)
	options.closed.connect(_on_options_closed)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause") or options.visible:
		return
	get_viewport().set_input_as_handled()
	if panel.visible:
		resume()
	else:
		open()


func open() -> void:
	status.text = ""
	_set_open(true)
	get_tree().paused = true
	resume_button.grab_focus()


func resume() -> void:
	_set_open(false)
	get_tree().paused = false


func _set_open(open_menu: bool) -> void:
	panel.visible = open_menu
	dim.visible = open_menu


func _on_save_pressed() -> void:
	Game.save_game()
	status.text = "Partida guardada"


func _on_options_pressed() -> void:
	panel.hide()
	options.open()


func _on_options_closed() -> void:
	panel.show()
	options_button.grab_focus()
