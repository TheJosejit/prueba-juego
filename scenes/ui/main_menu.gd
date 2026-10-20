extends Control
## Menú principal: continuar la partida guardada, empezar una nueva, elegir nivel, opciones y salir.
## Detrás hay una escena viva: el paisaje se desplaza y Pip corre y salta solo, mostrando cada mejora.
## Al entrar, el título cae letra a letra y los botones aparecen uno tras otro
## (cualquier tecla o clic se salta la animación).

const Scenery := preload("res://scenes/levels/scenery.gd")
const Terrain := preload("res://scenes/levels/terrain.gd")
const Decor := preload("res://scenes/levels/decor.gd")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const DEMO_POWERS := [Powers.Kind.NONE, Powers.Kind.HELMET, Powers.Kind.FEATHER, Powers.Kind.MAGNET]
const GROUND_HEIGHT := 30.0 # parte del suelo que se ve abajo

@onready var continue_button: Button = %ContinueButton
@onready var new_game_button: Button = %NewGameButton
@onready var levels_button: Button = %LevelsButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var buttons: Control = %Buttons
@onready var title: Control = %Title
@onready var subtitle: Label = %Subtitle
@onready var save_info: Label = %SaveInfo
@onready var version: Label = %Version
@onready var hints: Label = %Hints
@onready var options: Control = $OptionsMenu
@onready var level_select: Control = $LevelSelect

var screen := Vector2.ZERO
var layers: Array = [] # [capa, velocidad de desplazamiento]
var pip: CharacterBody2D
var lap := 0
var ai_timer := 1.0
var turn_timer := 0.0
var double_jump_timer := 0.0
var intro_tween: Tween
var intro_done := false


func _ready() -> void:
	screen = get_viewport_rect().size
	Sfx.play_music("menu")
	_build_world()

	continue_button.visible = Game.has_save()
	save_info.visible = Game.has_save()
	if Game.has_save():
		save_info.text = "Partida guardada: " + Game.save_summary()
	quit_button.visible = not OS.has_feature("web")
	version.text = "v" + str(ProjectSettings.get_setting("application/config/version", "1.0"))

	continue_button.pressed.connect(Game.continue_game)
	new_game_button.pressed.connect(Game.new_game)
	levels_button.pressed.connect(_on_levels_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(get_tree().quit)
	options.closed.connect(_on_options_closed)
	level_select.closed.connect(_on_levels_closed)
	for button: Button in buttons.get_children():
		button.mouse_entered.connect(button.grab_focus)
		button.focus_entered.connect(_grow.bind(button, 1.07))
		button.focus_exited.connect(_grow.bind(button, 1.0))
	Sfx.wire_ui(self)
	_play_intro()


# --- Escena de fondo ---

func _build_world() -> void:
	var theme_data := Themes.MEADOW
	# Cielo degradado
	var sky := TextureRect.new()
	var gradient := GradientTexture2D.new()
	gradient.gradient = Gradient.new()
	gradient.gradient.set_color(0, theme_data.sky_top)
	gradient.gradient.set_color(1, theme_data.sky_bottom)
	gradient.fill_to = Vector2(0, 1)
	sky.texture = gradient
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)
	move_child(sky, 0)

	var world := Node2D.new()
	add_child(world)
	move_child(world, 1)
	var ground_top := screen.y - GROUND_HEIGHT
	# Capas del paisaje: [capa, velocidad en píxeles por segundo]
	for info in [[Scenery.Layer.FAR, 5.0], [Scenery.Layer.NEAR, 12.0], [Scenery.Layer.CLOUDS, 3.0]]:
		var layer := Scenery.new()
		layer.layer = info[0]
		layer.theme = theme_data
		layer.ground_y = ground_top + 6.0
		layer.width = screen.x + 9000.0
		world.add_child(layer)
		layers.append([layer, info[1]])

	# Suelo con hierba
	var ground := Node2D.new()
	ground.position = Vector2(0, ground_top)
	world.add_child(ground)
	var terrain := Terrain.new()
	terrain.theme = theme_data
	for x in range(-2, int(screen.x / 32.0) + 3):
		for y in 2:
			terrain.add_cell(Vector2i(x, y))
	ground.add_child(terrain)
	terrain.build()
	var decor := Decor.new()
	decor.theme = theme_data
	decor.setup(terrain.cells)
	ground.add_child(decor)

	# Pip en modo demo
	pip = PLAYER_SCENE.instantiate()
	pip.demo = true
	pip.get_node("Camera2D").enabled = false
	pip.position = Vector2(-20, 0)
	ground.add_child(pip)
	pip.power = Powers.Kind.NONE
	decor.player = pip


func _process(delta: float) -> void:
	for info in layers:
		var layer: Node2D = info[0]
		layer.position.x -= info[1] * delta
		if layer.position.x < -(layer.width - screen.x - 100.0):
			layer.position.x = 0.0


## Pip corre solo: salta a ratos, a veces acelera o se da la vuelta, y al salir por la derecha
## vuelve a entrar por la izquierda con la siguiente mejora.
func _physics_process(delta: float) -> void:
	if not is_instance_valid(pip):
		return
	ai_timer -= delta
	if ai_timer <= 0.0:
		ai_timer = randf_range(0.6, 2.0)
		var roll := randf()
		if roll < 0.55 and pip.is_on_floor():
			pip.demo_jump_pressed = true
			pip.demo_jump_hold = randf_range(0.06, 0.25) # saltos bajos, por debajo de los botones
			if pip.power == Powers.Kind.FEATHER and randf() < 0.7:
				double_jump_timer = 0.4
		elif roll < 0.75:
			pip.demo_run = not pip.demo_run
		elif roll < 0.85 and pip.is_on_floor() and pip.demo_run:
			pip.demo_dir = -1.0 # media vuelta (derrapa)
			turn_timer = 0.4
	if turn_timer > 0.0:
		turn_timer -= delta
		if turn_timer <= 0.0:
			pip.demo_dir = 1.0
	if double_jump_timer > 0.0:
		double_jump_timer -= delta
		if double_jump_timer <= 0.0:
			pip.demo_jump_pressed = true
			pip.demo_jump_hold = 0.6 # mantiene el botón: planea
	if pip.position.x > screen.x + 40.0:
		lap += 1
		pip.position.x = -20.0
		pip.reset_physics_interpolation()
		pip.power = DEMO_POWERS[lap % DEMO_POWERS.size()]


# --- Entrada animada ---

func _play_intro() -> void:
	subtitle.modulate.a = 0.0
	save_info.modulate.a = 0.0
	version.modulate.a = 0.0
	hints.modulate.a = 0.0
	for button: Button in buttons.get_children():
		button.modulate.a = 0.0
	await get_tree().process_frame # espera a que los contenedores calculen los tamaños
	var start: float = title.intro_length()
	intro_tween = create_tween().set_parallel(true)
	intro_tween.tween_property(subtitle, "modulate:a", 1.0, 0.4).set_delay(start - 0.15)
	intro_tween.tween_property(save_info, "modulate:a", 1.0, 0.4).set_delay(start)
	var i := 0
	for button: Button in buttons.get_children():
		if not button.visible:
			continue
		button.pivot_offset = button.size / 2.0
		button.scale = Vector2(0.6, 0.6)
		var delay := start + 0.1 + i * 0.08
		intro_tween.tween_property(button, "modulate:a", 1.0, 0.25).set_delay(delay)
		intro_tween.tween_property(button, "scale", Vector2.ONE, 0.35).set_delay(delay) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1
	intro_tween.tween_property(version, "modulate:a", 0.8, 0.5).set_delay(start + 0.4)
	intro_tween.tween_property(hints, "modulate:a", 0.8, 0.5).set_delay(start + 0.4)
	intro_tween.chain().tween_callback(_finish_intro)


func _finish_intro() -> void:
	if intro_done:
		return
	intro_done = true
	(continue_button if continue_button.visible else new_game_button).grab_focus()


## Cualquier tecla, botón o clic durante la entrada la termina de golpe.
func _input(event: InputEvent) -> void:
	if intro_done or not (event.is_pressed() and not event.is_echo()):
		return
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()
		title.time = 10.0
		if intro_tween and intro_tween.is_valid():
			intro_tween.custom_step(100.0)
		_finish_intro()


func _grow(button: Button, amount: float) -> void:
	button.pivot_offset = button.size / 2.0
	create_tween().tween_property(button, "scale", Vector2(amount, amount), 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# --- Submenús ---

func _on_options_pressed() -> void:
	buttons.hide()
	options.open()


func _on_options_closed() -> void:
	buttons.show()
	options_button.grab_focus()


func _on_levels_pressed() -> void:
	buttons.hide()
	level_select.open()


func _on_levels_closed() -> void:
	buttons.show()
	levels_button.grab_focus()
