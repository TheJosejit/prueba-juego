extends Level
## Nivel 4: Volcán Rugiente. Lava, erizos y plataformas sobre la lava.
## Edita el mapa para cambiar el nivel (la leyenda está en level.gd).


func get_theme_id() -> String:
	return "volcano"


func get_map() -> PackedStringArray:
	return PackedStringArray([
		"",
		"",
		"",
		"",
		"",
		"                                                                                                  V",
		"                                                                                                C C C C                                           CCCC",
		"                                                                                                                                                 #####",
		"                                                            CCCCC    C  C                           E                                   V       ######",
		"    CC  m  CC                              h     vv         BBBBB    ====                     ###########                     B*B              #######",
		"                                                                                             ############       ==                            ########",
		"                              ##                                                  >>>       #############                                    #########",
		"  P            R              ##    E   ^^              K         R     R   ^^              #############             K     R   ^^  E       ##########    F",
		"#####################LLLL#####################LLLLLLLL###########################LLLLLL########################LLLLL############################################",
		"#####################LLLL#####################LLLLLLLL###########################LLLLLL########################LLLLL############################################",
	])
