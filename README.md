# PruebaJuego

Proyecto de Godot **4.7** (Forward Plus, Jolt Physics). Todo el equipo debe usar la misma versión de Godot.

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

| Persona | Área |
|---------|------|
|         |      |
|         |      |
|         |      |
