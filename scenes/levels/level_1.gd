extends Level
## Nivel 1: Pradera Soleada. Presenta el casco, los muelles y el punto de control.
## Edita el mapa para cambiar el nivel (la leyenda está en level.gd).


func get_theme_id() -> String:
	return "meadow"


func get_map() -> PackedStringArray:
	return PackedStringArray([
		"",
		"",
		"",
		"                                                                                                    CCC",
		"                                                                                                    C C",
		"                                                                                                                #",
		"                                                          CCCCC                                                ##",
		"                                                          BBBBB                               BBBBB           ###",
		"                                                                                              BCCCB          ####",
		"        CCC   h                  B*B*B              CCCC       ===               #   #        BB*BB         #####",
		"                                                    BBBB                        ##   ##                    ######",
		"                            ##                                                 ###   ###                  #######",
		"  P               E         ##           E             K        ^^^ E         ####   ####   E     E  S   ########     F",
		"######################   ####################   #######################   ########   ########################################",
		"######################   ####################   #######################   ########   ########################################",
	])
