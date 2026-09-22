#!/usr/bin/env bash
# Descarga el GIF y el detalle (instrucciones en español) de cada gifId de la rutina.
# Fuente: https://github.com/JahelCuadrado/ExerciseGymGifsDB (vía jsDelivr).
# Los ids `chalk/...` vienen del catálogo propio (Catalog/) y no se descargan.
# Uso: Scripts/fetch-media.sh [ruta/a/routine.json]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROUTINE="${1:-$ROOT/Routine/routine.json}"
MEDIA="$ROOT/Routine/media"
BASE="https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0"

[[ -f "$ROUTINE" ]] || { echo "No existe $ROUTINE"; exit 1; }
mkdir -p "$MEDIA"

ids=$(python3 -c '
import json,sys
r=json.load(open(sys.argv[1]))
blocks=r["days"]+r.get("extras",[])
print("\n".join(sorted({e["gifId"] for b in blocks for e in b["exercises"] if e.get("gifId") and not e["gifId"].startswith("chalk/")})))
' "$ROUTINE")

ok=0; fail=0
for id in $ids; do
  mkdir -p "$MEDIA/$(dirname "$id")"
  if curl -fsSL "$BASE/$id.gif" -o "$MEDIA/$id.gif" \
     && curl -fsSL "$BASE/api/es/exercises/$id.json" -o "$MEDIA/$id.json"; then
    ok=$((ok+1)); echo "✓ $id"
  else
    fail=$((fail+1)); echo "✗ $id (no se pudo descargar)"; rm -f "$MEDIA/$id.gif" "$MEDIA/$id.json"
  fi
done
echo "Descargados: $ok · Fallidos: $fail"
[[ $fail -eq 0 ]]
