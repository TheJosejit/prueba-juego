class_name Themes
## Paletas de colores, estilo del suelo y música de cada tipo de nivel.
## Para crear un tema nuevo, copia uno, cambia los colores y añádelo a ALL.

const MEADOW := {
	"style": "grass",
	"music": "meadow",
	"sky_top": Color("4aa8f0"), "sky_bottom": Color("c4ebff"),
	"far": Color("8fbfd8"), "far_light": Color("e8f6ff"),
	"near": Color("6cc070"), "near_alt": Color("8fd394"),
	"clouds": Color(1, 1, 1, 0.92),
	"top": Color("5cc85c"), "top_dark": Color("3c9a48"),
	"fill": Color("b5734a"), "fill_dark": Color("8f5536"), "fill_deep": Color("6e3f27"),
	"brick": Color("c0583c"), "mortar": Color("6e2a1a"),
	"plank": Color("c98a4b"), "plank_dark": Color("7d5229"),
	"lava": Color("ff7a1a"), "lava_light": Color("ffd04a"),
}

const CAVE := {
	"style": "stone",
	"music": "cave",
	"sky_top": Color("0d0a1a"), "sky_bottom": Color("2a2145"),
	"far": Color("1f1836"), "far_light": Color("2e2550"),
	"near": Color("2c2349"), "near_alt": Color("372c5a"),
	"clouds": Color(0, 0, 0, 0),
	"crystal": Color("7ef0ff"), "crystal_alt": Color("e07bff"),
	"top": Color("948bc0"), "top_dark": Color("6a5f96"),
	"fill": Color("4f4475"), "fill_dark": Color("3d335f"), "fill_deep": Color("2b2446"),
	"brick": Color("6d7fa8"), "mortar": Color("323a58"),
	"plank": Color("8a6a4c"), "plank_dark": Color("4d3a29"),
	"lava": Color("ff7a1a"), "lava_light": Color("ffd04a"),
}

const SKY := {
	"style": "cloud",
	"music": "sky",
	"sky_top": Color("5aa9ff"), "sky_bottom": Color("ffd6ea"),
	"far": Color(1, 1, 1, 0.55), "far_light": Color(1, 1, 1, 0.8),
	"near": Color("f6faff"), "near_alt": Color("e3eeff"),
	"clouds": Color(1, 1, 1, 0.95),
	"top": Color("ffffff"), "top_dark": Color("dbe7fb"),
	"fill": Color("eef4ff"), "fill_dark": Color("d4e2f8"), "fill_deep": Color("bccfee"),
	"brick": Color("e39b6f"), "mortar": Color("9c5b3c"),
	"plank": Color("ffffff"), "plank_dark": Color("c3d6f2"),
	"lava": Color("ff7a1a"), "lava_light": Color("ffd04a"),
}

const VOLCANO := {
	"style": "rock",
	"music": "volcano",
	"sky_top": Color("1a080a"), "sky_bottom": Color("7a2716"),
	"far": Color("3a1512"), "far_light": Color("ff6a1a"),
	"near": Color("4a1b16"), "near_alt": Color("5a2219"),
	"clouds": Color(0.25, 0.17, 0.17, 0.55),
	"top": Color("5e4741"), "top_dark": Color("3a2c29"),
	"fill": Color("3d2c29"), "fill_dark": Color("2c201d"), "fill_deep": Color("1f1614"),
	"brick": Color("7a3b2e"), "mortar": Color("2e130e"),
	"plank": Color("5e4d46"), "plank_dark": Color("2e2522"),
	"lava": Color("ff6a14"), "lava_light": Color("ffd04a"),
}

const ALL := {"meadow": MEADOW, "cave": CAVE, "sky": SKY, "volcano": VOLCANO}


static func get_theme(id: String) -> Dictionary:
	return ALL.get(id, MEADOW)
