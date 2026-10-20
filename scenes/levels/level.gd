class_name Level
extends Node2D
## Base de todos los niveles: construye el nivel a partir de un mapa de texto.
## Cada nivel hereda de este script y define get_map() y get_theme_id() ("meadow", "cave", "sky", "volcano").
##
## Leyenda del mapa (cada carácter es una casilla de 32x32):
##   #  suelo                       =  plataforma (se atraviesa desde abajo)
##   B  ladrillo (el casco lo rompe)  *  bloque sorpresa con moneda
##   h  bloque con CASCO            w  bloque con PLUMA            m  bloque con IMÁN
##   C  moneda                      ^  pinchos                     L  lava
##   E  Blob                        R  Erizo (no se puede pisar)   V  Murciélago
##   >  plataforma móvil horizontal v  plataforma móvil vertical   (varios seguidos = más ancha)
##   S  muelle                      K  punto de control
##   P  inicio del jugador          F  bandera de meta             (espacio) vacío

const TILE := 32
const Terrain := preload("res://scenes/levels/terrain.gd")
const Platforms := preload("res://scenes/levels/platforms.gd")
const Lava := preload("res://scenes/levels/lava.gd")
const Decor := preload("res://scenes/levels/decor.gd")
const Scenery := preload("res://scenes/levels/scenery.gd")
const MovingPlatform := preload("res://scenes/objects/moving_platform.gd")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const BLOCK_SCENE := preload("res://scenes/objects/block.tscn")
const COIN_SCENE := preload("res://scenes/objects/coin.tscn")
const SPIKES_SCENE := preload("res://scenes/objects/spikes.tscn")
const SPRING_SCENE := preload("res://scenes/objects/spring.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/objects/checkpoint.tscn")
const GOAL_SCENE := preload("res://scenes/objects/goal.tscn")
const PAUSE_MENU_SCENE := preload("res://scenes/ui/pause_menu.tscn")
const ENEMY_SCENES := {
	"E": preload("res://scenes/enemies/blob.tscn"),
	"R": preload("res://scenes/enemies/hedgehog.tscn"),
	"V": preload("res://scenes/enemies/bat.tscn"),
}
const ITEM_BLOCKS := {"h": Powers.Kind.HELMET, "w": Powers.Kind.FEATHER, "m": Powers.Kind.MAGNET}

var theme: Dictionary
var level_index := -1


func get_map() -> PackedStringArray:
	return PackedStringArray()


func get_theme_id() -> String:
	return "meadow"


func _ready() -> void:
	theme = Themes.get_theme(get_theme_id())
	level_index = Game.enter_level(scene_file_path)
	Sfx.play_music(theme.music)
	add_child(PAUSE_MENU_SCENE.instantiate())

	var map := get_map()
	var map_size := Vector2i(0, map.size())
	for row in map:
		map_size.x = maxi(map_size.x, row.length())
	var bounds := Rect2(Vector2.ZERO, Vector2(map_size * TILE))
	_build_background(bounds)

	var terrain := Terrain.new()
	var platforms := Platforms.new()
	var lava := Lava.new()
	for layer in [terrain, platforms, lava]:
		layer.theme = theme
		add_child(layer)

	var player: Node = null
	var checkpoints: Array[Node] = []
	for y in map.size():
		var row := map[y]
		var x := 0
		while x < row.length():
			var ch := row[x]
			var cell := Vector2i(x, y)
			var center := Vector2(x + 0.5, y + 0.5) * TILE
			var feet := Vector2((x + 0.5) * TILE, (y + 1) * TILE)
			match ch:
				"#": terrain.add_cell(cell)
				"=": platforms.add_cell(cell)
				"L": lava.add_cell(cell)
				"B": _spawn_block(center, Block.Content.NONE)
				"*": _spawn_block(center, Block.Content.COIN)
				"h", "w", "m": _spawn_block(center, Block.Content.ITEM, ITEM_BLOCKS[ch])
				"C": _spawn(COIN_SCENE, center)
				"^": _spawn(SPIKES_SCENE, center)
				"S": _spawn(SPRING_SCENE, feet)
				"K": checkpoints.append(_spawn(CHECKPOINT_SCENE, feet))
				"E", "R", "V": _spawn(ENEMY_SCENES[ch], feet)
				"F": _spawn(GOAL_SCENE, feet)
				"P": player = _spawn(PLAYER_SCENE, feet)
				">", "v":
					var run := 1
					while x + run < row.length() and row[x + run] == ch:
						run += 1
					_spawn_moving_platform(cell, run, Vector2.RIGHT if ch == ">" else Vector2.DOWN)
					x += run
					continue
			x += 1
	terrain.build()
	platforms.build()
	lava.build()
	var decor := Decor.new()
	decor.theme = theme
	decor.setup(terrain.cells)
	add_child(decor)

	if not player:
		push_error("El mapa no tiene casilla 'P' de inicio del jugador.")
		return
	if Game.has_checkpoint():
		player.position = Game.checkpoint_pos
		player.reset_physics_interpolation()
		for checkpoint in checkpoints:
			if checkpoint.position.distance_to(Game.checkpoint_pos) < 1.0:
				checkpoint.set_active_silently()
	player.set_level_bounds(bounds)
	decor.player = player
	_add_ambient_particles(player)

	var hud := get_node_or_null("HUD")
	if hud and level_index >= 0 and Game.announce_level(level_index):
		hud.flash("%d · %s" % [level_index + 1, Game.level_name(level_index)])


func _spawn(scene: PackedScene, pos: Vector2):
	var node: Node2D = scene.instantiate()
	node.position = pos
	add_child(node)
	return node


func _spawn_block(pos: Vector2, content: Block.Content, item: Powers.Kind = Powers.Kind.NONE) -> void:
	var block: Block = BLOCK_SCENE.instantiate()
	block.position = pos
	block.content = content
	block.item = item
	block.brick = theme.brick
	block.mortar = theme.mortar
	add_child(block)


func _spawn_moving_platform(cell: Vector2i, width_tiles: int, axis: Vector2) -> void:
	var platform := MovingPlatform.new()
	platform.position = Vector2(cell) * TILE
	platform.width_tiles = width_tiles
	platform.axis = axis
	platform.plank = theme.plank
	platform.plank_dark = theme.plank_dark
	add_child(platform)


## Cielo degradado (fijo en pantalla) y tres capas de decorado que se mueven más despacio que el nivel.
func _build_background(bounds: Rect2) -> void:
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -100
	var sky := TextureRect.new()
	var gradient := GradientTexture2D.new()
	gradient.gradient = Gradient.new()
	gradient.gradient.set_color(0, theme.sky_top)
	gradient.gradient.set_color(1, theme.sky_bottom)
	gradient.fill_from = Vector2(0, 0)
	gradient.fill_to = Vector2(0, 1)
	sky.texture = gradient
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky_layer.add_child(sky)
	add_child(sky_layer)
	# Viñeteado: oscurece un poco los bordes de la pantalla para centrar la mirada
	var vignette_layer := CanvasLayer.new()
	vignette_layer.layer = 1
	var vignette := TextureRect.new()
	var radial := GradientTexture2D.new()
	radial.gradient = Gradient.new()
	radial.gradient.set_color(0, Color(0, 0, 0, 0))
	radial.gradient.set_color(1, Color(0.05, 0.02, 0.1, 0.28))
	radial.gradient.set_offset(0, 0.6)
	radial.fill = GradientTexture2D.FILL_RADIAL
	radial.fill_from = Vector2(0.5, 0.5)
	radial.fill_to = Vector2(1.05, 0.5)
	vignette.texture = radial
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette_layer.add_child(vignette)
	add_child(vignette_layer)
	var viewport_width := 1400.0
	for layer_info in [[Scenery.Layer.FAR, 0.15], [Scenery.Layer.NEAR, 0.4], [Scenery.Layer.CLOUDS, 0.08]]:
		var parallax := Parallax2D.new()
		parallax.scroll_scale = Vector2(layer_info[1], 1.0)
		var scenery := Scenery.new()
		scenery.layer = layer_info[0]
		scenery.theme = theme
		scenery.width = bounds.size.x * layer_info[1] + viewport_width
		scenery.ground_y = bounds.end.y - 2 * TILE
		parallax.add_child(scenery)
		add_child(parallax)


## Partículas que flotan por la pantalla según el tema: pétalos, polvo brillante, viento o ceniza.
## Van pegadas a la cámara, pero cada partícula se queda en su sitio del mundo.
func _add_ambient_particles(player: Node) -> void:
	var p := CPUParticles2D.new()
	p.texture = Fx.soft_texture()
	p.local_coords = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(420, 240)
	p.amount = 40
	p.lifetime = 8.0
	p.preprocess = 8.0
	p.z_index = 3
	p.spread = 180.0
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.2, Color.WHITE)
	fade.add_point(0.8, Color.WHITE)
	p.color_ramp = fade
	match theme.style:
		"grass": # pétalos que caen meciéndose
			p.color = Color("ffd6e8")
			p.gravity = Vector2(6, 10)
			p.initial_velocity_min = 8.0
			p.initial_velocity_max = 20.0
			p.tangential_accel_min = -6.0
			p.tangential_accel_max = 6.0
			p.scale_amount_min = 0.2
			p.scale_amount_max = 0.35
		"stone": # motas brillantes que suben despacio
			p.color = Color(theme.crystal, 0.8)
			p.gravity = Vector2(0, -4)
			p.initial_velocity_min = 2.0
			p.initial_velocity_max = 8.0
			p.scale_amount_min = 0.1
			p.scale_amount_max = 0.25
		"cloud": # ráfagas de viento
			p.amount = 25
			p.color = Color(1, 1, 1, 0.7)
			p.direction = Vector2.LEFT
			p.spread = 4.0
			p.initial_velocity_min = 60.0
			p.initial_velocity_max = 110.0
			p.gravity = Vector2.ZERO
			p.scale_amount_min = 0.12
			p.scale_amount_max = 0.2
		"rock": # ceniza
			p.color = Color(0.6, 0.55, 0.55, 0.7)
			p.gravity = Vector2(-4, 14)
			p.initial_velocity_min = 4.0
			p.initial_velocity_max = 12.0
			p.scale_amount_min = 0.12
			p.scale_amount_max = 0.3
	player.camera.add_child(p)
