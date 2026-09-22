# Chalk

App iOS personal y de código abierto para dar seguimiento a tu rutina de gimnasio. Tú tienes tu rutina en un Excel;
un agente la convierte al formato de la app y tú solo marcas lo que haces.

- **Mi día**: ejercicios del día con series, repeticiones, RIR y descanso, ✓ / ✕, peso editable que se vuelve tu default, racha, anillos de progreso, sección de extras que se reacomodan si no los haces, reposición de días en días libres y notas.
- **Glosario**: RIR, ROM, MYOreps, dropset y demás términos aparecen como enlaces en el detalle de cada ejercicio.
- **Entrenamiento en vivo**: "Iniciar entrenamiento" abre una Live Activity con el ejercicio actual en la pantalla de bloqueo y la Dynamic Island (series, repeticiones, descanso, peso y el siguiente). El botón ✓ lo marca como hecho y pasa al siguiente.
- **Plan**: tu semana de lunes a domingo, con los ejercicios de cada día en carrusel. Toca uno para ver el GIF animado e instrucciones.
- **Perfil**: nombre, peso, fotos de progreso con comparador, check-in semanal, log de notas y gráficas (calorías estimadas, adherencia, progresión de carga y peso corporal).

Todo se guarda en el teléfono con SwiftData. No hay backend ni cuentas.

## Requisitos

- Xcode 26 o superior, iOS 26 (Liquid Glass)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Cargar tu rutina

1. Clona el repo y abre un agente (por ejemplo Claude Code) en la carpeta.
2. Pídele: *"Convierte mi rutina `~/Downloads/mi-rutina.xlsx` al formato de Chalk"*. El agente sigue [CLAUDE.md](CLAUDE.md).
3. El agente genera `Routine/routine.json`, descarga los GIFs con `Scripts/fetch-media.sh` y valida con `swift Scripts/validate-routine.swift`.
4. `xcodegen generate && open Chalk.xcodeproj`, elige tu equipo de firma y corre en tu iPhone.

Tu rutina y los GIFs descargados están en `.gitignore`. Sin rutina propia, la app usa `Routine/routine.example.json`.

## Créditos

Los GIFs e instrucciones de ejercicios provienen de **[ExerciseGymGifsDB](https://github.com/JahelCuadrado/ExerciseGymGifsDB)**, creado por **Jahel Cuadrado**.
Según ese proyecto, los GIFs pertenecen a sus respectivos autores y ni ExerciseGymGifsDB ni Chalk poseen derechos sobre ellos.
Por eso este repo no incluye los GIFs: cada persona los descarga localmente para su uso personal.

Los ejercicios que no están en ExerciseGymGifsDB vienen del catálogo propio en `Catalog/`, con descripciones escritas para Chalk
y GIFs de Fitcron. Los créditos y licencias de cada imagen están en [Catalog/CREDITS.md](Catalog/CREDITS.md).

### Fuente del splash

El splash escribe "Chalk" a mano, trazo por trazo, con una técnica inspirada en [Tegaki](https://github.com/gkurt/tegaki) de Gokhan Kurt:
cada letra se rasteriza, se reduce a su esqueleto con el algoritmo de Zhang-Suen y se dibuja en orden de escritura.
Si pones una fuente en `Chalk/Resources/Fonts/` (ignorada por git) con el nombre PostScript `RealChalk`, se usa esa;
si no, se usa Chalkduster, que viene con iOS. Real Chalk es de [JSH Creates](https://www.jshcreates.com/) y su licencia no permite redistribuirla.

Las calorías mostradas son una estimación (MET 5.0 × peso corporal × tiempo estimado), no una medición.
