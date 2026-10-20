extends CanvasLayer
## Marcador: monedas, puntos, mejora actual y vidas. También muestra mensajes grandes
## en el centro y el nombre del nivel al empezar (flash). Los números "saltan" al cambiar
## y la puntuación sube contando.

@onready var coins_label: Label = %Coins
@onready var score_label: Label = %Score
@onready var lives_label: Label = %Lives
@onready var coin_icon: Control = $Left/CoinIcon
@onready var heart_icon: Control = $Right/HeartIcon
@onready var power_icon: Control = %PowerIcon
@onready var message: Label = %Message
@onready var title: Label = %Title

var shown_score := 0.0
var _last := {}


func _ready() -> void:
	Game.stats_changed.connect(_refresh)
	Game.message.connect(_show_message)
	message.text = ""
	title.modulate.a = 0.0
	shown_score = Game.score
	_last = {"coins": Game.coins, "lives": Game.lives, "power": Game.power}
	_refresh()


func _process(delta: float) -> void:
	if shown_score != Game.score:
		var diff := Game.score - shown_score
		shown_score = move_toward(shown_score, Game.score, maxf(absf(diff) * 8.0, 60.0) * delta)
		score_label.text = "%07d" % int(shown_score)


func _refresh() -> void:
	coins_label.text = "x%02d" % Game.coins
	lives_label.text = "x%d" % Game.lives
	power_icon.power = Game.power
	if Game.coins != _last.coins:
		_pop(coins_label, 1.5)
		coin_icon.spin()
	if Game.lives != _last.lives:
		_pop(lives_label, 1.8)
		_pop(heart_icon, 1.6)
	if Game.power != _last.power and Game.power != Powers.Kind.NONE:
		_pop(power_icon, 2.0)
	_last = {"coins": Game.coins, "lives": Game.lives, "power": Game.power}


func _pop(control: Control, amount: float) -> void:
	control.pivot_offset = control.size / 2.0
	control.scale = Vector2(amount, amount)
	create_tween().tween_property(control, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_message(text: String) -> void:
	message.text = text
	if text != "":
		_pop(message, 1.6)


## Rótulo que aparece y se desvanece (nombre del nivel).
func flash(text: String) -> void:
	title.text = text
	title.pivot_offset = title.size / 2.0
	title.scale = Vector2(0.6, 0.6)
	var tween := create_tween()
	tween.tween_property(title, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(title, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.6)
	tween.tween_property(title, "modulate:a", 0.0, 0.6)
