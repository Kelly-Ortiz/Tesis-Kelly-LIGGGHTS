#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#   CONFIGURAR LIGGGHTS (sin sudo) — CON RESPALDO AUTOMATICO
#   ───────────────────────────────────────────────────────────────
#   Lo ejecuta Kelly despues de que el admin instalo Docker/git/screen
#   y la agrego al grupo docker.
#
#     1. git clone https://github.com/Kelly-Ortiz/Tesis-Kelly-LIGGGHTS.git ~/repo
#     2. bash ~/repo/configurar.sh
#     3. source ~/.bashrc
#     4. screen -S sim   ;   correr NOMBRE_DE_CARPETA
#
#   Si una corrida se interrumpe (reinicio, falta de memoria, pausa),
#   basta volver a ejecutar  correr NOMBRE  y RETOMA donde se quedo.
# ═══════════════════════════════════════════════════════════════════
set -e
REPO_URL="https://github.com/Kelly-Ortiz/Tesis-Kelly-LIGGGHTS.git"

echo ""; echo ">>> Detectando motor de contenedores..."
if docker ps >/dev/null 2>&1; then MOTOR="docker"
elif command -v podman >/dev/null 2>&1; then MOTOR="podman"
else
    echo "  ERROR: No puedo usar Docker ni Podman sin sudo."
    echo "  Cierra sesion, reconectate y vuelve a intentar (docker run hello-world)."
    exit 1
fi
echo "    Motor: $MOTOR"

echo ">>> [1/3] Descargando los dos contenedores..."
$MOTOR pull cesarsant2000/liggghts-motor
$MOTOR pull cesarsant2000/liggghts-motor-v2

echo ">>> [2/3] Actualizando el repositorio..."
cd "$HOME"
if [ -d "$HOME/repo/.git" ]; then cd "$HOME/repo" && git pull && cd "$HOME"
else rm -rf "$HOME/repo"; git clone "$REPO_URL" "$HOME/repo"; fi

echo ">>> [3/3] Instalando comandos 'correr' y 'correr-todas'..."
mkdir -p "$HOME/bin"

cat > "$HOME/bin/correr" << 'CORRER_EOF'
#!/bin/bash
# Uso: correr NOMBRE_CARPETA [num_cores] [v1|v2]
# RESPALDO AUTOMATICO: si se interrumpe, ejecuta el mismo comando y RETOMA.
CARPETA="$1"; FORZAR_CORES="$2"; VERSION="${3:-v2}"
REPO="$HOME/repo"; RUNS="$HOME/runs"; GB_POR_PROCESO=5

if [ "$VERSION" = "v1" ]; then IMAGEN="cesarsant2000/liggghts-motor"
else IMAGEN="cesarsant2000/liggghts-motor-v2"; fi
if docker ps >/dev/null 2>&1; then MOTOR="docker"
elif command -v podman >/dev/null 2>&1; then MOTOR="podman"
else echo "ERROR: ni docker ni podman sin sudo."; exit 1; fi

if [ -z "$CARPETA" ]; then
    echo ""; echo "  Uso: correr NOMBRE_CARPETA [num_cores] [v1|v2]"; echo ""
    echo "  Disponibles:"
    find "$REPO" -name 'in.*' -type f | sed 's|.*/\([^/]*\)/in\..*|    - \1|' | sort -u
    echo ""; exit 1
fi
RUTA=$(find "$REPO" -type d -name "$CARPETA" | head -1)
[ -z "$RUTA" ] && { echo "  ERROR: no existe '$CARPETA'."; exit 1; }
ARCHIVO=$(find "$RUTA" -name 'in.*' -type f | head -1)
[ -z "$ARCHIVO" ] && { echo "  ERROR: '$CARPETA' sin in.*"; exit 1; }
NOMBRE=$(basename "$ARCHIVO")

FIS=$(lscpu -p=Core,Socket 2>/dev/null | grep -v '^#' | sort -u | wc -l)
{ [ -z "$FIS" ] || [ "$FIS" -lt 1 ]; } && FIS=$(nproc)
RAM_MB=$(free -m | awk '/^Mem:/{print $2}'); RAM_GB=$((RAM_MB/1024))
CAP=$((RAM_GB/GB_POR_PROCESO)); [ "$CAP" -lt 1 ] && CAP=1
CORES=$FIS; [ "$CAP" -lt "$CORES" ] && CORES=$CAP
[ -n "$FORZAR_CORES" ] && CORES=$FORZAR_CORES

RUNDIR="$RUNS/$CARPETA"; RA="$RUNDIR/restart.continuar.a"; RB="$RUNDIR/restart.continuar.b"
NEWEST=""
for f in "$RA" "$RB"; do [ -s "$f" ] || continue; { [ -z "$NEWEST" ] || [ "$f" -nt "$NEWEST" ]; } && NEWEST="$f"; done

DT=$(grep -iE "variable[[:space:]]+dt[[:space:]]+equal" "$ARCHIVO" | head -1 | awk '{print $NF}')
SP=$(grep -iE "variable[[:space:]]+screwPeriod[[:space:]]+equal" "$ARCHIVO" | head -1 | awk '{print $NF}')
if [ -n "$DT" ] && [ -n "$SP" ]; then STEPS=$(awk -v sp="$SP" -v dt="$DT" 'BEGIN{printf "%d", sp/dt}'); else STEPS=1000000; fi
{ [ -z "$STEPS" ] || [ "$STEPS" -lt 1 ]; } && STEPS=1000000

echo "======================================================"
echo "  Simulacion : $CARPETA ($NOMBRE)"
echo "  Motor/Img  : $MOTOR / $IMAGEN"
echo "  Maquina    : $FIS cores, ${RAM_GB} GB RAM -> $CORES procesos"
echo "  Checkpoint : cada $STEPS pasos (1 vuelta del tornillo)"

AWKPROG='
BEGIN { in_cont = 0 }
{
    line = $0
    if (in_cont == 1) { print "# [resume] " line; if (line ~ /&[ \t]*$/) in_cont=1; else in_cont=0; next }
    if (line ~ /^[ \t]*create_box/) { print "read_restart " ARCHIVO_RESTART; next }
    if (line ~ /particletemplate/ || line ~ /particledistribution/ || line ~ /mesh\/surface\/planar/ || line ~ /insert\/stream/) {
        print "# [resume] " line; if (line ~ /&[ \t]*$/) in_cont=1; next }
    if (line ~ /^[ \t]*unfix[ \t]+ins[ \t]*$/) { print "# [resume] " line; next }
    if (line ~ /^[ \t]*run[ \t]+\$\{fillsteps\}/) { print "# [resume] " line; next }
    if (line ~ /^[ \t]*run[ \t]+\$\{dischargesteps\}/) {
        print "variable totalsteps equal ${fillsteps}+${dischargesteps}"
        print "restart " STEPSV " restart.continuar.a restart.continuar.b"
        print "run ${totalsteps} upto"; next }
    print line
}'

if [ -n "$NEWEST" ]; then
    echo "  MODO       : REANUDAR desde $(basename $NEWEST)"
    echo "======================================================"
    RFILE=$(basename "$NEWEST")
    awk -v ARCHIVO_RESTART="$RFILE" -v STEPSV="$STEPS" "$AWKPROG" "$ARCHIVO" > "$RUNDIR/$NOMBRE"
    sed -i "s/^processors.*/processors $CORES 1 1/" "$RUNDIR/$NOMBRE"
    [ -f "$RUNDIR/massflow.csv" ] && cp "$RUNDIR/massflow.csv" "$RUNDIR/massflow.$(date +%s).csv"
else
    echo "  MODO       : INICIO desde cero"
    echo "======================================================"
    rm -rf "$RUNDIR"; mkdir -p "$RUNDIR/post"; cp -r "$RUTA"/. "$RUNDIR/"
    sed -i "s/^processors.*/processors $CORES 1 1/" "$RUNDIR/$NOMBRE"
    if grep -q 'run[[:space:]]*${dischargesteps}' "$RUNDIR/$NOMBRE"; then
        sed -i "/run[[:space:]]*\${dischargesteps}/i restart $STEPS restart.continuar.a restart.continuar.b" "$RUNDIR/$NOMBRE"
    fi
fi

echo "  Inicio: $(date '+%H:%M:%S %d-%m-%Y')"
$MOTOR run --rm -v "$RUNDIR":/simulaciones "$IMAGEN" \
    mpirun -np $CORES --allow-run-as-root --bind-to none --oversubscribe \
    lmp380 -in /simulaciones/$NOMBRE -log /simulaciones/log_sim.txt
EXITO=$?

DEST="$RUTA/resultados"; mkdir -p "$DEST"
cp -r "$RUNDIR/post" "$DEST/" 2>/dev/null
cp "$RUNDIR"/*.csv "$DEST/" 2>/dev/null
cp "$RUNDIR"/rt_*.txt "$DEST/" 2>/dev/null
cp "$RUNDIR/log_sim.txt" "$DEST/" 2>/dev/null

echo "  Fin: $(date '+%H:%M:%S %d-%m-%Y')"
if [ $EXITO -eq 0 ]; then
    echo "  ESTADO: COMPLETADA. Resultados en $DEST"
    echo "  (para liberar espacio: rm -rf $RUNDIR)"
else
    echo "  ESTADO: interrumpida. Para RETOMAR ejecuta de nuevo: correr $CARPETA"
fi
CORRER_EOF
chmod +x "$HOME/bin/correr"

cat > "$HOME/bin/correr-todas" << 'TODAS_EOF'
#!/bin/bash
REPO="$HOME/repo"
mapfile -t CARPETAS < <(find "$REPO" -name 'in.*' -type f -exec dirname {} \; | sort -u | xargs -n1 basename)
TOTAL=${#CARPETAS[@]}; N=0
for C in "${CARPETAS[@]}"; do
    N=$((N+1)); RUTA=$(find "$REPO" -type d -name "$C" | head -1)
    if [ -d "$RUTA/resultados" ] && [ "$(ls -A "$RUTA/resultados" 2>/dev/null)" ]; then
        echo ">> [$N/$TOTAL] $C ya tiene resultados, saltando."; continue; fi
    echo ""; echo ">> [$N/$TOTAL] Corriendo $C ..."; correr "$C"
done
echo ""; echo "=== Todas terminadas ==="
TODAS_EOF
chmod +x "$HOME/bin/correr-todas"

grep -q 'HOME/bin' "$HOME/.bashrc" 2>/dev/null || echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
export PATH="$HOME/bin:$PATH"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║              CONFIGURACION COMPLETA                       ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Activa los comandos:   source ~/.bashrc                 ║"
echo "║                                                          ║"
echo "║  Correr:   screen -S sim                                 ║"
echo "║            correr NOMBRE_DE_CARPETA                       ║"
echo "║            (Ctrl+A luego D para salir sin cortar)        ║"
echo "║                                                          ║"
echo "║  Si se interrumpe (reinicio/OOM/pausa):                  ║"
echo "║            correr NOMBRE_DE_CARPETA   (RETOMA solo)      ║"
echo "║                                                          ║"
echo "║  Ver avance:  screen -r sim                              ║"
echo "║  Resultados:  ~/repo/NOMBRE/resultados/                  ║"
echo "╚══════════════════════════════════════════════════════════╝"
