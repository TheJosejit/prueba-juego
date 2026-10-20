extends Level
## Nivel 3: Islas del Cielo. Sin suelo continuo: plataformas móviles, muelles y la pluma para planear.
## Edita el mapa para cambiar el nivel (la leyenda está en level.gd).


func get_theme_id() -> String:
	return "sky"


func get_map() -> PackedStringArray:
	return PackedStringArray([
		"",
		"",
		"                                                  C                                                              CCCCC",
		"                                                 CCC                                                             =====",
		"",
		"                                                               CCC",
		"                                                               ===                        CCCCC",
		"                    CCC                                                  B*B                                                          V",
		"      w             ===   C * C                      V                                       R                                V B*B*B",
		"                                                          ===                            ########   >>>           ===",
		"               ===            E      >>>                              K      E     vvv   ########             S",
		"  P     CC               ##########               S                 #############        ########         #######                 E       E     F",
		"#############            ##########          ###########            #############        ########         #######       ##############################",
		"#############            ##########          ###########            #############        ########         #######       ##############################",
		"#############            ##########          ###########            #############        ########         #######       ##############################",
		"#############            ##########          ###########            #############        ########         #######       ##############################",
	])
