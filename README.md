# PruebaJuego

Proyecto de Godot **4.7** (Forward Plus, Jolt Physics). Todo el equipo debe usar la misma versión de Godot.

## El juego

Plataformas 2D: lleva a **Pip** hasta la bandera de meta. Recoge monedas (50 = vida extra), pisa a los **Blobs** y evita los pinchos y los huecos. Los bloques morados sueltan una moneda si los golpeas desde abajo.

| Acción | Teclado | Mando |
|--------|---------|-------|
| Moverse | A / D o ← / → | Cruceta o stick |
| Saltar (mantener = más alto) | Espacio, W o ↑ | A |
| Correr | Shift o J | X |

## Estructura

```
scripts/game.gd          Autoload "Game": puntos, monedas, vidas y controles
scenes/player/           Pip (movimiento, salto, muerte)
scenes/enemies/          Blob
scenes/objects/          Bloques, monedas, pinchos y bandera de meta
scenes/levels/           Construcción de niveles, suelo, fondo y level_1
scenes/ui/               Marcador (HUD)
```

Los gráficos se dibujan por código (`_draw()`), así que no hacen falta imágenes. Si añadís sprites, sustituid el `_draw()` de cada escena.

### Cómo editar un nivel

Los niveles son mapas de texto. Abre [level_1.gd](scenes/levels/level_1.gd) y cambia los caracteres. Cada carácter es una casilla de 32×32:

| Carácter | Qué es |
|----------|--------|
| `#` | Suelo |
| `B` | Ladrillo |
| `*` | Bloque sorpresa (moneda) |
| `C` | Moneda |
| `E` | Enemigo (Blob) |
| `^` | Pinchos |
| `P` | Inicio del jugador |
| `F` | Bandera de meta |

Para crear un nivel nuevo, duplica `level_1.gd` y `level_1.tscn`, cambia el mapa y haz que el `.tscn` nuevo use el script nuevo.

### Capas de colisión

| Capa | Nombre | Quién |
|------|--------|-------|
| 1 | mundo | Suelo y bloques |
| 2 | jugador | Pip |
| 3 | enemigos | Blobs |
| 4 | objetos | Monedas, pinchos, meta |

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
|         | Jugador y controles (power-ups, animaciones, sonidos) | `scenes/player/`, `scripts/` |
|         | Enemigos y objetos (nuevos enemigos, bloques, ítems) | `scenes/enemies/`, `scenes/objects/` |
|         | Niveles e interfaz (nuevos niveles, menú, pantalla de inicio) | `scenes/levels/`, `scenes/ui/` |
