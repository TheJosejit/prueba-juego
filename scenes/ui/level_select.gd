extends Control
## Selector de niveles. Los niveles se desbloquean al completar el anterior.
## Ejecutando el juego desde el editor (versión de desarrollo) todos están desbloqueados, para probarlos.

signal closed

@onready var list: VBoxContainer = %List
@onready var back_button: Button = %BackButton


func _ready() -> void:
	hide()
	back_button.pressed.connect(close)


func open() -> void:
	for child in list.get_children():
		child.queue_free()
	var unlocked := Game.LEVELS.size() if OS.is_debug_build() else Game.unlocked_levels
	var first: Button = null
	for i in Game.LEVELS.size():
		var button := Button.new()
		if i < unlocked:
			button.text = "%d · %s" % [i + 1, Game.level_name(i)]
			button.pressed.connect(Game.start_level.bind(i))
		else:
			button.text = "%d · ???  (bloqueado)" % (i + 1)
			button.disabled = true
		list.add_child(button)
		if not first:
			first = button
	Sfx.wire_ui(self)
	show()
	first.grab_focus()


func close() -> void:
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()
