# Chalk

App iOS personal y de código abierto para dar seguimiento a tu rutina de gimnasio. Tú tienes tu rutina en un Excel;
un agente la convierte al formato de la app y tú solo marcas lo que haces.

- **Mi día**: ejercicios del día con series, repeticiones, RIR y descanso, ✓ / ✕, peso editable que se vuelve tu default, racha, anillos de progreso, sección de extras que se reacomodan si no los haces, reposición de días en días libres y notas.
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

Las calorías mostradas son una estimación (MET 5.0 × peso corporal × tiempo estimado), no una medición.
