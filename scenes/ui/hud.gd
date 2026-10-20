extends CanvasLayer
## Marcador: puntos, monedas, vidas y mensajes grandes en el centro.

@onready var stats: Label = $Stats
@onready var message: Label = $Message


func _ready() -> void:
	Game.stats_changed.connect(_refresh)
	Game.message.connect(_show_message)
	message.text = ""
	_refresh()


func _refresh() -> void:
	stats.text = "PUNTOS %06d     MONEDAS %02d     VIDAS %d" % [Game.score, Game.coins, Game.lives]


func _show_message(text: String) -> void:
	message.text = text
