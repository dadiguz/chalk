# Chalk: instrucciones para agentes

Chalk es una app iOS (SwiftUI, iOS 26, Liquid Glass, SwiftData) para dar seguimiento a una rutina de gimnasio.
Todo es local. La rutina de cada persona vive en `Routine/routine.json`, que **está en .gitignore y nunca se commitea**.

Tu trabajo más común aquí: **convertir la rutina de la persona (Excel, PDF, foto, texto) a `Routine/routine.json`**.

## 1. Leer la rutina de la persona

- Excel: léelo con Python y `openpyxl` (crea un venv en un directorio temporal si no está instalado). Revisa **todas** las hojas; muchas rutinas repiten la misma semana en varias hojas.
- Identifica: nombre, fecha de inicio, objetivo, notas generales, días (Día 1, Día 2… o Push/Pull/Legs), y por ejercicio: series, repeticiones, RIR/RPE, descanso e indicaciones.
- Busca tablas y notas al final o a los lados de la hoja: escalas de esfuerzo (RPE/RIR) van en `meta.effortScale`, términos que el coach define (por ejemplo su versión de "MYOreps") en `meta.glossary`, e indicaciones generales en `meta.generalNotes`. La app las muestra en la Guía (engrane de Mi día), pestaña "Tu coach".
- Busca trabajo "extra" sin día fijo (por ejemplo "abdominales 3 veces por semana"). Va en `extras` con `timesPerWeek`.

## 2. Escribir `Routine/routine.json`

El formato está en `Routine/schema.json` y hay un ejemplo en `Routine/routine.example.json`. Reglas:

- `id` de ejercicio: kebab-case, **único en todo el archivo** y estable. Es la llave del historial, pesos y notas. Si un ejercicio se repite en dos días, usa ids distintos (`curl-sentado-maquina`, `curl-sentado-maquina-d5`).
- `reps`, `rir` y `rest` son texto libre, respetando el original: `"8 a 10"`, `"0 a 1"`, `"90 seg"`, `"2 min"`.
- `sets` es entero. Si dice "3-4 series", usa el mayor y deja el rango en `notes`.
- `notes`: las indicaciones del coach tal cual. Usa `null` si la celda está vacía o es solo un punto.
- `defaultWeightKg`: solo si el archivo trae peso. Si no, `null`.
- `schedule`: asigna cada `days[].id` y `extras[].id` a lunes…domingo. Si el archivo no dice qué día, propón (Día 1–5 → lunes a viernes, fin de semana libre, extras repartidos) y **pide confirmación a la persona**. Un día con lista vacía es día libre y en la app se puede usar para reponer.

## 3. Asociar GIFs (ExerciseGymGifsDB)

Los GIFs e instrucciones vienen de [ExerciseGymGifsDB](https://github.com/JahelCuadrado/ExerciseGymGifsDB) de Jahel Cuadrado, versión fijada `v1.1.0`.

1. Descarga el catálogo en español:
   `https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0/api/es/exercises.json`
   Cada ejercicio tiene `id` (`<muscle>/<slug>`), `name` en español y un `slug` en inglés.
2. Busca por el **slug en inglés**; los nombres en español son traducciones automáticas y el match por texto es ruidoso. Equivalencias útiles:

   | Español | Slug |
   |---|---|
   | mancuerna | dumbbell |
   | barra | barbell |
   | barra Z | ez-barbell / ez-bar |
   | polea | cable |
   | máquina | lever / sled |
   | multipower | smith |
   | jalón | pulldown |
   | supinación / pronación | underhand / (default) |
   | prensa | leg-press (`sled-45-leg-press`) |
   | aperturas | fly |
   | posterior / deltoide trasero | reverse-fly / rear-delt |
   | elevación de talones | calf-raise |
   | sentadilla búlgara | split-squat |

3. Escribe el `id` exacto en `gifId`. Si no hay un equivalente fiel, busca primero en el catálogo propio (`Catalog/exercises.json`, ids `chalk/...`). Si tampoco está, puedes agregarlo al catálogo (ver abajo) o poner `gifId: null`. **Nunca pongas un GIF de otro ejercicio**: la app muestra "Sin demostración disponible" y eso es mejor que enseñar mal la técnica.
4. Si dudas entre candidatos, muéstrale 2–3 a la persona con su enlace `.gif` y deja que elija.

### Catálogo propio (`Catalog/`)

Para ejercicios que no existen en ExerciseGymGifsDB. Se commitea y lo comparten todos los usuarios del repo.

- Cada entrada tiene el mismo esquema que el detalle de ExerciseGymGifsDB más `description` e `image`.
- `id`: `chalk/<slug-en-ingles>`. Escribe descripción e instrucciones propias, claras y en español (4 a 6 pasos).
- Imagen (GIF animado de preferencia, o imagen fija): guárdala en `Catalog/images/` y llena `author`, `license`, `licenseUrl` y `sourceUrl`, y agrega la fila en `Catalog/CREDITS.md`.
- Por defecto busca imágenes con licencia libre (Wikimedia Commons CC0, CC BY o CC BY-SA vía su API). Usa imágenes con derechos reservados (por ejemplo, GIFs de Fitcron) solo si el dueño del repo te da la URL explícitamente, y siempre con su crédito.
- Si no hay imagen fiel, deja el ejercicio sin imagen antes que mostrar uno distinto.

## 4. Descargar media y validar

```bash
Scripts/fetch-media.sh                 # descarga GIF + instrucciones de cada gifId a Routine/media/ (ignorado)
swift Scripts/validate-routine.swift   # ids únicos, schedule válido, media presente, avisa de ejercicios sin GIF
```

Al terminar, dile a la persona **qué ejercicios quedaron sin GIF**.

## 5. Compilar

```bash
xcodegen generate   # el .xcodeproj se genera desde project.yml
open Chalk.xcodeproj
```

La app lee `Routine/routine.json` del bundle; si no existe usa `routine.example.json`. Cualquier cambio a la rutina requiere recompilar.

## Reglas del repo

- **Nunca commitees** `Routine/routine.json` ni `Routine/media/`.
- **Nunca commitees** `Chalk/Resources/Fonts/`: son fuentes con licencia propia. El splash cae a Chalkduster si no están.
- **No quites los créditos** a ExerciseGymGifsDB (README y pantalla Acerca de). Los GIFs pertenecen a sus autores.
- Live Activity: `ChalkWidgets/` (extensión) + `Shared/` (compilado en app y extensión: `WorkoutActivityAttributes`, `CompleteExerciseIntent`, vistas). El intent corre en el proceso de la app y llama a `WorkoutSession`; en la extensión su cuerpo queda vacío por `WIDGET_EXTENSION`. La app y el intent comparten `AppServices.modelContainer`.
- Glosario: los temas de `GuideTopic.training` tienen `keywords`; esas palabras se vuelven enlaces en el detalle de ejercicio. Al agregar un término nuevo, dale `key` y `keywords`.
- Código: SwiftUI nativo, sin dependencias de terceros, `@Observable` y SwiftData, un tipo por archivo, carpetas por feature (`Chalk/Features/...`).
- Colores en `Chalk/Resources/Assets.xcassets`: `Lime` (acento), `Lavender` (extras), `Canvas`/`Surface` (fondos).
- Tras agregar archivos Swift, corre `xcodegen generate`.
- Para revisar pantallas en el simulador (solo Debug): argumentos `-seedDemoData` (historial falso en una instalación limpia), `-tab plan|profile`, `-detail <exerciseId>`, `-profileRoute charts|notes|photos`, `-glossary <key>` (junto con `-detail`), `-startWorkout YES` (inicia la Live Activity), `-completeCurrent YES` (ejecuta el ✓ de la actividad), `-liveActivityPreview YES` (vista de pantalla de bloqueo en la app), `-guide Rutina|"Tu coach"|"La app"`.
