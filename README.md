# PruebaJuego

Proyecto de Godot **4.7** (Forward Plus, Jolt Physics). Todo el equipo debe usar la misma versión de Godot.

## El juego

Plataformas 2D: lleva a **Pip** a través de cuatro mundos hasta la bandera de meta de cada uno.

| Nivel | Tema | Novedades |
|-------|------|-----------|
| 1 · Pradera Soleada | Hierba | Casco, muelles, punto de control, caja secreta de ladrillos |
| 2 · Cueva de Cristal | Piedra | Erizos, murciélagos, túnel de techo bajo, plataformas que suben y bajan |
| 3 · Islas del Cielo | Nubes | Sin suelo continuo: plataformas móviles, muelles y la pluma |
| 4 · Volcán Rugiente | Roca y lava | Lava, plataformas sobre la lava, muchos erizos |

Recoge monedas (50 = vida extra), pisa a los enemigos y llega a la meta. Al completar un nivel se desbloquea el siguiente en **Elegir nivel**.

### Controles

| Acción | Teclado | Mando |
|--------|---------|-------|
| Moverse | A / D o ← / → | Cruceta o stick |
| Saltar (mantener = más alto) | Espacio, W o ↑ | A |
| Correr | Shift o J | X |
| Pausa (guardar, reiniciar, opciones) | Esc o P | Start |
| Silenciar / activar sonido | M | |
| Pantalla completa / ventana | F11 o Alt+Enter | |

### Mejoras (poderes)

Salen de los bloques sorpresa con un icono especial. **Cualquier mejora te protege de un golpe**: si te tocan, la pierdes y parpadeas un momento en vez de morir. La lava y las caídas matan siempre.

| Mejora | Qué hace |
|--------|----------|
| 🪖 **Casco** | Rompe los ladrillos al golpearlos desde abajo |
| 🪶 **Pluma** | Doble salto, y planear manteniendo el salto mientras caes |
| 🧲 **Imán** | Atrae las monedas cercanas |

### Enemigos

| Enemigo | Cómo vencerlo |
|---------|---------------|
| **Blob** (morado) | Pisándolo |
| **Murciélago** | Pisándolo (vuela y atraviesa paredes) |
| **Erizo** | ¡No se puede pisar! Golpea desde abajo el bloque en el que esté |

Golpear un bloque desde abajo lanza por los aires a cualquier enemigo que esté encima.

**Guardar partida:** desde el menú de pausa se guardan el nivel, los puntos, las monedas, las vidas y la mejora; también se guarda solo al pasar de nivel. Al continuar se empieza desde el principio del nivel guardado. Las opciones (volumen de música y efectos, pantalla completa, temblor de cámara) se guardan solas. Todo está en la carpeta de datos de Godot (`%APPDATA%\Godot\app_userdata\PruebaJuego` en Windows).

## Estructura

```
scripts/game.gd          Autoload "Game": puntos, vidas, mejora, punto de control, lista de niveles, guardado y controles
scripts/settings.gd      Autoload "Settings": opciones del jugador
scripts/sfx.gd           Autoload "Sfx": sonidos y música (sintetizados por código)
scripts/fx.gd            Clase "Fx": partículas, escombros y textos flotantes
scripts/powers.gd        Clase "Powers": las mejoras y su icono
scripts/themes.gd        Clase "Themes": colores y música de cada tipo de nivel
scenes/player/           Pip (movimiento, salto, mejoras, daño)
scenes/enemies/          enemy.gd (base común), Blob, Erizo y Murciélago
scenes/objects/          Bloques, mejora, monedas, pinchos, muelle, punto de control, plataforma móvil y meta
scenes/levels/           level.gd (construye niveles), suelo, plataformas, lava, fondo y los niveles 1-4
scenes/ui/               Marcador (HUD), menú principal, selector de niveles, pausa y opciones
```

Los gráficos se dibujan por código (`_draw()`), así que no hacen falta imágenes. Si añadís sprites, sustituid el `_draw()` de cada escena.

### Cómo editar o crear un nivel

Los niveles son mapas de texto. Abre por ejemplo [level_1.gd](scenes/levels/level_1.gd) y cambia los caracteres. Cada carácter es una casilla de 32×32:

| Carácter | Qué es | Carácter | Qué es |
|----------|--------|----------|--------|
| `#` | Suelo | `=` | Plataforma (se atraviesa desde abajo) |
| `B` | Ladrillo (el casco lo rompe) | `*` | Bloque sorpresa con moneda |
| `h` | Bloque con **casco** | `w` | Bloque con **pluma** |
| `m` | Bloque con **imán** | `C` | Moneda |
| `E` | Blob | `R` | Erizo |
| `V` | Murciélago | `^` | Pinchos |
| `L` | Lava | `S` | Muelle |
| `>` | Plataforma móvil horizontal | `v` | Plataforma móvil vertical |
| `K` | Punto de control | `P` | Inicio del jugador |
| `F` | Bandera de meta | (espacio) | Vacío |

Varios `>` o `v` seguidos forman una plataforma móvil más ancha (se mueve 3 casillas a cada lado).

Medidas útiles para diseñar: Pip salta unas **4 casillas de alto** y cruza unos **4 huecos andando o 6 corriendo**; un muelle lanza unas **10 casillas**.

Para crear un nivel nuevo:
1. Duplica `level_1.gd` y `level_1.tscn` (por ejemplo `level_5`), y haz que el `.tscn` nuevo use el script nuevo.
2. En el script, cambia el mapa y el tema en `get_theme_id()`: `"meadow"`, `"cave"`, `"sky"` o `"volcano"`.
3. Añade la escena y su nombre a la lista `LEVELS` de [game.gd](scripts/game.gd).

Ejecutando el juego desde el editor todos los niveles aparecen desbloqueados en **Elegir nivel**, para poder probarlos.

### Cómo editar la música y los sonidos

Todo el audio se genera por código en [sfx.gd](scripts/sfx.gd). Para lanzar un efecto: `Sfx.play("jump")`. Para la música: `Sfx.play_music("meadow")`.

- **Canciones** (`SONGS`): cada una tiene tempo (`bpm`), acordes por compás (`"C"`, `"Am"`...), melodía (`"C5:2"` = Do5 durante 2 corcheas, `R` = silencio) y un patrón de batería de 16 pasos (`K` bombo, `S` caja, `h` charles).
- Las canciones se generan en segundo plano la primera vez y se guardan en caché; si cambias una, su caché se regenera sola.
- **Efectos**: están en `_build_sounds()`. Para usar archivos `.wav`/`.ogg`, basta con guardarlos en el diccionario `sounds`.

### Capas de colisión

| Capa | Nombre | Quién |
|------|--------|-------|
| 1 | mundo | Suelo, bloques y plataformas |
| 2 | jugador | Pip |
| 3 | enemigos | Blob, Erizo, Murciélago |
| 4 | objetos | Monedas, pinchos, muelles, puntos de control, meta |

## Empezar

```bash
git clone https://github.com/TheJosejit/prueba-juego.git
```

Abre la carpeta desde Godot (Importar → `project.godot`).

## Forma de trabajar

1. Nunca trabajes directamente en `main`.
2. Antes de empezar, trae lo último:
   ```bash
   git checkout main
   git pull
   ```
3. Crea una rama para tu tarea:
   ```bash
   git checkout -b nombre-de-la-tarea
   ```
4. Haz commits pequeños y frecuentes:
   ```bash
   git add .
   git commit -m "Describe el cambio"
   git push -u origin nombre-de-la-tarea
   ```
5. Abre un **Pull Request** en GitHub. Otra persona lo revisa y lo fusiona en `main`.

## Normas para Godot

- **Una escena, una persona.** Los `.tscn` se fusionan mal: no editéis la misma escena a la vez. Dividid el juego en escenas pequeñas (jugador, enemigos, nivel, UI) e instanciadlas.
- **Sí se suben** los archivos `.import` y `.uid`.
- **No se sube** la carpeta `.godot/` (ya está en `.gitignore`).
- Las tareas se reparten en **Issues** de GitHub; asígnate la tuya antes de empezar.

## Reparto de tareas

Propuesta (cada área toca carpetas distintas, así casi no habrá conflictos):

| Persona | Área | Carpetas |
|---------|------|----------|
|         | Jugador y mejoras (nuevos poderes, animaciones) | `scenes/player/`, `scripts/powers.gd` |
|         | Enemigos y objetos (nuevos enemigos, bloques, ítems) | `scenes/enemies/`, `scenes/objects/` |
|         | Niveles, música e interfaz (nuevos niveles, temas, menús) | `scenes/levels/`, `scenes/ui/`, `scripts/themes.gd`, `scripts/sfx.gd` |
