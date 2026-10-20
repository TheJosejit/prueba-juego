class_name Level
extends Node2D
## Base de todos los niveles: construye el nivel a partir de un mapa de texto.
## Cada nivel hereda de este script y solo define get_map().
##
## Leyenda del mapa (cada carácter es una casilla de 32x32):
##   #  suelo            B  ladrillo         *  bloque sorpresa (moneda)
##   C  moneda           E  enemigo (Blob)   ^  pinchos
##   P  inicio jugador   F  bandera de meta  (espacio) vacío

const TILE := 32
const SKY_COLOR := Color("8fd3ff")
const Terrain := preload("res://scenes/levels/terrain.gd")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const BLOB_SCENE := preload("res://scenes/enemies/blob.tscn")
const BLOCK_SCENE := preload("res://scenes/objects/block.tscn")
const COIN_SCENE := preload("res://scenes/objects/coin.tscn")
const SPIKES_SCENE := preload("res://scenes/objects/spikes.tscn")
const GOAL_SCENE := preload("res://scenes/objects/goal.tscn")


func get_map() -> PackedStringArray:
	return PackedStringArray()


func _ready() -> void:
	RenderingServer.set_default_clear_color(SKY_COLOR)
	Sfx.play_music()
	var map := get_map()
	var map_size := Vector2i(0, map.size())
	for row in map:
		map_size.x = maxi(map_size.x, row.length())

	var terrain := Terrain.new()
	add_child(terrain)
	var player: Node = null
	for y in map.size():
		var row := map[y]
		for x in row.length():
			var center := Vector2(x + 0.5, y + 0.5) * TILE
			var feet := Vector2((x + 0.5) * TILE, (y + 1) * TILE)
			match row[x]:
				"#": terrain.add_cell(Vector2i(x, y))
				"B": _spawn(BLOCK_SCENE, center)
				"*": _spawn(BLOCK_SCENE, center).has_coin = true
				"C": _spawn(COIN_SCENE, center)
				"^": _spawn(SPIKES_SCENE, center)
				"E": _spawn(BLOB_SCENE, feet)
				"F": _spawn(GOAL_SCENE, feet)
				"P": player = _spawn(PLAYER_SCENE, feet)
	terrain.build()

	var bounds := Rect2(Vector2.ZERO, Vector2(map_size * TILE))
	if player:
		player.set_level_bounds(bounds)
	else:
		push_error("El mapa no tiene casilla 'P' de inicio del jugador.")
	var scenery := get_node_or_null("Background/Scenery")
	if scenery:
		scenery.width = bounds.size.x + 700.0
		scenery.ground_y = bounds.end.y - 2 * TILE


func _spawn(scene: PackedScene, pos: Vector2):
	var node: Node2D = scene.instantiate()
	node.position = pos
	add_child(node)
	return node
