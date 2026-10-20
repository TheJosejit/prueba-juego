extends CanvasLayer
## Marcador: monedas, puntos, mejora actual y vidas. También muestra mensajes grandes
## en el centro y el nombre del nivel al empezar (flash).

@onready var coins_label: Label = %Coins
@onready var score_label: Label = %Score
@onready var lives_label: Label = %Lives
@onready var power_icon: Control = %PowerIcon
@onready var message: Label = %Message
@onready var title: Label = %Title


func _ready() -> void:
	Game.stats_changed.connect(_refresh)
	Game.message.connect(_show_message)
	message.text = ""
	title.modulate.a = 0.0
	_refresh()


func _refresh() -> void:
	coins_label.text = "x%02d" % Game.coins
	score_label.text = "%07d" % Game.score
	lives_label.text = "x%d" % Game.lives
	power_icon.power = Game.power


func _show_message(text: String) -> void:
	message.text = text
	if text != "":
		message.pivot_offset = message.size / 2.0
		message.scale = Vector2(1.4, 1.4)
		create_tween().tween_property(message, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Rótulo que aparece y se desvanece (nombre del nivel).
func flash(text: String) -> void:
	title.text = text
	var tween := create_tween()
	tween.tween_property(title, "modulate:a", 1.0, 0.3)
	tween.tween_interval(1.8)
	tween.tween_property(title, "modulate:a", 0.0, 0.6)
