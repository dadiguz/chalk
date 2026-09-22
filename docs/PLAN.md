# Chalk — Plan de desarrollo

App personal iOS para dar seguimiento a una rutina de gimnasio que viene de un Excel.
Todo local, sin backend. Código abierto: cualquiera clona el repo, le pide a un agente
que convierta su rutina al formato de la app, y compila.

---

## 1. Decisiones base

| Tema | Decisión |
|---|---|
| Plataforma | iOS 26+, Swift 6, SwiftUI, Liquid Glass y componentes nativos. Sin dependencias externas. |
| Persistencia | SwiftData (registros, perfil, pesos, notas, fotos). La rutina NO vive en la DB: se lee de un JSON. |
| Rutina | `Routine/routine.json` (ignorado por git). El repo incluye `Routine/routine.example.json` con una rutina ficticia para que el proyecto compile. |
| GIFs e instrucciones | Se toman de [ExerciseGymGifsDB](https://github.com/JahelCuadrado/ExerciseGymGifsDB). Un script descarga solo los GIFs que la rutina referencia a `Routine/media/` (ignorado). La app es 100% offline después. |
| Créditos | README y pantalla "Acerca de" en Perfil acreditan a JahelCuadrado/ExerciseGymGifsDB y aclaran que los GIFs pertenecen a sus autores. |
| Idioma | UI en español. |
| Navegación | `TabView` con 3 tabs: **Mi día** (default), **Plan**, **Perfil**. |

---

## 2. Estructura del repo

```
chalk/
├── CLAUDE.md                    # Instrucciones para el agente que importa la rutina
├── README.md                    # Qué es, cómo cargar tu rutina, créditos
├── docs/PLAN.md                 # Este archivo
├── Routine/
│   ├── schema.json              # JSON Schema de la rutina
│   ├── routine.example.json     # Rutina de ejemplo (commiteada)
│   ├── routine.json             # TU rutina (gitignore)
│   └── media/                   # GIFs + detalle JSON descargados (gitignore)
├── Scripts/
│   ├── fetch-media.sh           # Descarga GIF + instrucciones por cada gifId de routine.json
│   └── validate-routine.swift   # Valida el JSON contra el schema y reporta gifIds sin match
└── Chalk/                       # Proyecto Xcode
    ├── App/                     # ChalkApp, RootTabView, ModelContainer
    ├── Routine/                 # Modelos Codable + RoutineLoader
    ├── Data/                    # Modelos SwiftData + repositorios
    ├── Features/
    │   ├── Today/               # Mi día
    │   ├── Plan/                # Semana
    │   ├── ExerciseDetail/      # Detalle + GIF
    │   ├── Profile/             # Perfil, wizard, check-in semanal, fotos, notas
    │   └── Charts/
    ├── Components/              # Anillos, pills, GlassCard, AnimatedGIFView
    └── Resources/
```

`.gitignore` incluye: `Routine/routine.json`, `Routine/media/`, `xcuserdata/`, `*.xcuserstate`, `.DS_Store`, `DerivedData/`.

---

## 3. Formato de la rutina (`routine.json`)

Diseñado a partir del Excel real: días numerados (no fechas), series, reps como texto ("8 a 10"),
RIR, descanso, indicaciones, y trabajo extra que se hace N veces por semana sin día fijo.

```json
{
  "version": 1,
  "meta": {
    "athlete": "Nombre",
    "startDate": "2026-09-21",
    "goal": "Enfoque en deltoides y piernas",
    "generalNotes": ["2-3 series de aproximación en el primer ejercicio..."]
  },
  "days": [
    {
      "id": "day-1",
      "name": "Día 1",
      "focus": "Upper body",
      "exercises": [
        {
          "id": "press-hombro-mancuerna",
          "name": "Press de hombro con mancuerna",
          "sets": 3,
          "reps": "5 a 8",
          "rir": "1 a 2",
          "rest": "2 min",
          "notes": "ROM completo, carga elevada manteniendo buena técnica.",
          "defaultWeightKg": null,
          "gifId": "delts/dumbbell-seated-shoulder-press"
        }
      ]
    }
  ],
  "extras": [
    {
      "id": "abs",
      "name": "Trabajo abdominal",
      "timesPerWeek": 3,
      "exercises": [ { "id": "crunch", "name": "Crunch acostado", "sets": 4, "reps": "30", "gifId": "abs/crunch-floor" } ]
    }
  ],
  "schedule": {
    "monday": ["day-1", "abs"],
    "tuesday": ["day-2"],
    "wednesday": ["day-3", "abs"],
    "thursday": ["day-4"],
    "friday": ["day-5", "abs"],
    "saturday": [],
    "sunday": []
  }
}
```

Reglas:
- `gifId` es el `id` exacto del ejercicio en la API (`<muscle>/<slug>`) o `null` si no hay match razonable. La app muestra "Sin demostración disponible" en ese caso, nunca un GIF equivocado.
- `id` de ejercicio es estable y único en todo el archivo: es la llave para pesos, logs y notas. Si cambias el nombre pero conservas el id, no pierdes historial.
- `defaultWeightKg` viene del archivo si existe; si no, `null`. En cuanto el usuario lo cambia en la app, el valor de la DB manda.
- `reps` y `rir` son texto libre para respetar rangos ("8 a 10", "0 a 1").

---

## 4. Modelo de datos (SwiftData)

| Modelo | Campos | Para qué |
|---|---|---|
| `UserProfile` | name, createdAt, lastCheckInAt | Perfil y disparador del check-in semanal |
| `BodyWeightEntry` | date, kg | Gráfica de peso corporal |
| `ProgressPhoto` | date, fileName (en Documents), note | Histórico para compararse |
| `ExerciseSetting` | exerciseId, defaultWeightKg, updatedAt | Peso por defecto que sobreescribe al del JSON |
| `WorkoutEntry` | date (día), exerciseId, dayId, status (`done`/`skipped`/`pending`), weightKg, completedSets | Un registro por ejercicio por fecha. Base de la racha y gráficas |
| `Note` | date, exerciseId?, text | Notas del día o de un ejercicio; log completo en Perfil |
| `MakeupSession` | date, dayId | Un día de rutina repuesto en un día libre (ej. Día 3 hecho el sábado) |

Reglas derivadas (se calculan, no se guardan):
- **Racha**: días consecutivos con al menos un `WorkoutEntry` en `done`. Los días libres sin actividad no la rompen.
- **Qué toca hoy**: `schedule[weekday]` + `MakeupSession` de esa fecha + extras pendientes (ver 5.1).

Racha: días consecutivos con al menos un `WorkoutEntry` en `done`. Los días sin nada programado
(`schedule` vacío) no rompen la racha. Se calcula, no se guarda.

---

## 5. Pantallas

### 5.1 Mi día (tab principal, réplica del layout de Avena)
- **Header**: pill con 🔥 racha a la izquierda, centro con "Hoy / 22 sep 2026" y flechas ◀ ▶ para navegar días (hacia atrás sin límite, hacia adelante hasta hoy), avatar a la derecha que abre Perfil.
- **Anillos** (4, en tarjeta glass): Ejercicios %, Series completadas %, Extras de la semana (ej. 2/3) y Calorías estimadas del día.
- **Bloques** por cada `dayId` programado ese día (ej. "Upper body", luego "Abdominales"). Cada bloque tiene un título con botones ✕ / ✓ globales (marcar todo).
- **Fila de ejercicio**: thumbnail del GIF (o placeholder), nombre, "3 × 8 a 10 · RIR 1-2 · 90 seg", campo de peso (kg) editable inline, y botones ✕ / ✓. Tap en la fila → detalle.
- Al final del día: botón "Nota del día" con icono; abre editor de texto.
- **Sección Extra** (abs, talones): tarjeta separada visualmente del bloque principal, con etiqueta "Extra · 2/3 esta semana". Aparece en sus días preferidos del `schedule`.
  - ✓ → cuenta para la cuota semanal.
  - ✕ → queda **pendiente** y se muestra al día siguiente (incluidos días libres) con badge "Pendiente de ayer" hasta que se haga o termine la semana. La cuota se reinicia cada lunes.
  - Si ya se cumplió la cuota, deja de aparecer esa semana.
- **Día libre** (sábado, domingo o cualquier día sin bloque): estado vacío con la racha intacta y botón **"Reponer un día"**. Abre una lista de los días de la semana en curso que no se completaron (o todos, por si quieres repetir). Al elegir uno se crea un `MakeupSession` y el día se pinta como un día normal con badge "Repuesto · Día 3".
- Un día programado que se saltó por completo muestra al día siguiente un aviso discreto: "Ayer no hiciste Día 2. Puedes reponerlo el fin de semana."
- Día pasado: se ve tal cual quedó, editable por si olvidaste marcar.

### 5.2 Plan
- Lista vertical Lunes → Domingo. Cada fila: nombre del día, foco, y un `ScrollView(.horizontal)` con tarjetas cuadradas por ejercicio (thumbnail + nombre + "3×8-10").
- Tap en tarjeta → detalle. Sin calendario, sin edición.

### 5.3 Detalle de ejercicio (sheet, desde Mi día o Plan)
- GIF animado grande (reproducción nativa con `CGImageSource`, sin librerías). Si no hay: placeholder con texto "Sin demostración. Este ejercicio no tiene GIF asociado."
- Nombre, series, reps, RIR, descanso, indicaciones del coach.
- Peso por defecto editable (se guarda en `ExerciseSetting`).
- Instrucciones paso a paso de la API (español), equipo y músculo principal.
- Historial corto: últimos 5 registros (fecha, peso) y mini gráfica de peso.
- Notas del ejercicio.

### 5.4 Perfil
- **Wizard inicial** (primera apertura): nombre → peso corporal → foto opcional. 3 pasos con `NavigationStack`.
- **Check-in semanal**: al abrir la app, si pasaron ≥7 días desde `lastCheckInAt`, sheet: "¿Actualizamos tu peso y foto?" con Sí / Ahora no. Nunca bloquea.
- Secciones: datos (nombre, peso actual), **Fotos** (grid cronológico, vista comparar 2 fotos lado a lado con slider), **Mis notas** (log completo agrupado por fecha, con el ejercicio si aplica), **Progreso** (gráficas), **Acerca de** (créditos a ExerciseGymGifsDB, versión).

### 5.5 Gráficas (Swift Charts)
Cuatro gráficas, en Perfil → Progreso. Derivadas solo de lo que hay en el archivo y en los logs:

1. **Calorías estimadas** por día y acumulado semanal. Fórmula: MET de fuerza (5.0) × peso corporal (kg) × horas. Duración por ejercicio = series × (tiempo de serie ~45 s + descanso). Se muestra con "≈" y una nota de que es aproximación; el peso corporal sale del último `BodyWeightEntry`.
2. **Adherencia semanal**: ejercicios completados / programados por semana, últimas 8 semanas (barras). Los repuestos cuentan como completados. Los extras se muestran como una segunda serie más tenue.
3. **Progresión de carga por ejercicio**: selector de ejercicio y línea con el peso registrado por fecha. Es la que responde "¿estoy subiendo?".
4. **Peso corporal**: línea con los check-ins semanales, con marca en las fechas que tienen foto para saltar a compararlas.

Extra si sobra tiempo: **tonelaje semanal** (kg × reps × series) como barra apilada por grupo muscular.

---

## 6. CLAUDE.md (para quien clone el repo)

Contendrá, en este orden:
1. Qué es la app y qué archivo espera (`Routine/routine.json`).
2. Cómo leer el archivo del usuario (xlsx, pdf, foto, texto) y mapearlo al schema. Reglas: un `id` por ejercicio, reps/RIR como texto, días numerados y luego `schedule` propuesto que el usuario confirma.
3. Cómo buscar el GIF: descargar `api/es/search.json` de la API, buscar por nombre en español e inglés, sinónimos comunes (jalón = pulldown, prensa = leg press, multipower = smith, polea = cable, mancuerna = dumbbell). Si hay duda, preguntar al usuario mostrando 2-3 candidatos con su `gifUrl`. Si no hay match, `gifId: null` y avisarlo en la respuesta final.
4. Ejecutar `Scripts/validate-routine.swift` y `Scripts/fetch-media.sh`.
5. Compilar en Xcode. Recordatorio: `routine.json` y `media/` están ignorados, no commitear.
6. Créditos obligatorios que no deben quitarse.

Se usa `CLAUDE.md` (lo lee Claude Code automáticamente) con un `AGENTS.md` que solo dice "ver CLAUDE.md" para otros agentes.

---

## 7. Fases de desarrollo

| Fase | Entregable | Criterio de hecho |
|---|---|---|
| 0. Base | Proyecto Xcode, tabs vacíos con Liquid Glass, `.gitignore`, README con créditos, `schema.json`, `routine.example.json` | Compila y corre |
| 1. Rutina | Modelos Codable, `RoutineLoader` (carga `routine.json`, si no existe usa el example), scripts de validación y descarga de media | Tu rutina real cargada en el simulador con GIFs |
| 2. Mi día | Header, navegación de fechas, bloques, filas, ✓/✕, peso inline, racha, anillos | Puedes registrar un entrenamiento completo |
| 3. Detalle | Sheet con GIF animado, datos, instrucciones, peso por defecto, placeholder sin GIF | Todos los ejercicios abren, con o sin GIF |
| 4. Plan | Semana vertical con carruseles horizontales | Navegación a detalle funciona |
| 5. Perfil | Wizard, check-in semanal, fotos con comparación, notas | Primera apertura guía al usuario; a los 7 días pregunta |
| 6. Gráficas | Las 4 obligatorias + calorías opcional | Datos reales de tus logs |
| 7. Pulido | CLAUDE.md final, AGENTS.md, importar tu Excel con el propio CLAUDE.md como prueba de fuego | Un tercero puede clonar y cargar su rutina sin ayuda |

---

## 8. Decisiones confirmadas (22 sep 2026)

1. Día 1–5 → lunes a viernes. Sábado y domingo libres, con opción de **reponer** cualquier día no completado.
2. Abs lunes/miércoles/viernes, talones martes/viernes, como **sección Extra** independiente. Si se tachan, quedan pendientes y ruedan al día siguiente hasta cumplir la cuota semanal.
3. Gráficas: calorías estimadas, adherencia, progresión de carga y peso corporal.
4. Target iOS 26 con Liquid Glass.
5. Nombre: Chalk.

## 9. Estado (22 sep 2026)

Fases 0 a 7 implementadas en la primera iteración:

- Proyecto XcodeGen (`project.yml`), iOS 26, Swift 6 con aislamiento MainActor por defecto, sin dependencias.
- Rutina real importada del Excel: 5 días, 2 extras (abs 3×, talones 2×), 35 ejercicios, 33 con GIF. Sin GIF: "Hip thrust en máquina" y "Plancha abdominal".
- Mi día, Plan, detalle con GIF animado e instrucciones, Perfil con wizard, check-in semanal, fotos con comparador, notas y 4 gráficas.
- Pruebas unitarias de las reglas de extras pendientes, racha, días libres y reposiciones (`ChalkTests`).

Pendiente: ícono de la app, prueba en dispositivo físico y edición de la rutina desde la app (fuera de alcance por ahora).
