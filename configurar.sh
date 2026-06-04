#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#   CONFIGURAR LIGGGHTS — lo ejecuta Kelly, SIN sudo
#   ───────────────────────────────────────────────────────────────
#   REQUISITO PREVIO: el administrador ya instaló Docker (o Podman),
#   git y screen, y agregó a Kelly al grupo docker (ver LISTA-PARA-ADMIN).
#
#   COMO USARLO:
#     1. Conectarse por VPN/terminal
#     2. Ejecutar:   bash configurar.sh
#     3. Al terminar:   source ~/.bashrc    (o reconectarse)
#     4. Usar:   correr NOMBRE_DE_CARPETA
# ═══════════════════════════════════════════════════════════════════

set -e

REPO_URL="https://github.com/Kelly-Ortiz/Tesis-Kelly-LIGGGHTS.git"
IMG1="cesarsant2000/liggghts-motor"
IMG2="cesarsant2000/liggghts-motor-v2"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   Configurando LIGGGHTS (sin sudo) — Kelly       ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ─────────────────────────────────────────────────────────────
# 0. Detectar el motor de contenedores (docker o podman)
# ─────────────────────────────────────────────────────────────
echo ">>> Detectando motor de contenedores..."
if docker ps >/dev/null 2>&1; then
    MOTOR="docker"
elif command -v podman >/dev/null 2>&1; then
    MOTOR="podman"
else
    echo ""
    echo "  ❌ ERROR: No puedo usar Docker ni Podman sin sudo."
    echo ""
    echo "  Posibles causas:"
    echo "   - El admin aún no instaló Docker/Podman, o"
    echo "   - Te agregaron al grupo docker pero NO te has reconectado."
    echo ""
    echo "  Solución: cierra sesión, vuelve a conectarte y corre esto otra vez."
    echo "  Para verificar:   docker run hello-world"
    exit 1
fi
echo "    Motor detectado: $MOTOR"

# ─────────────────────────────────────────────────────────────
# 1. Descargar los dos contenedores
# ─────────────────────────────────────────────────────────────
echo ">>> [1/3] Descargando los dos contenedores (puede tardar)..."
$MOTOR pull "$IMG1"
$MOTOR pull "$IMG2"
echo "    OK"

# ─────────────────────────────────────────────────────────────
# 2. Clonar / actualizar el repositorio
# ─────────────────────────────────────────────────────────────
echo ">>> [2/3] Descargando el repositorio de simulaciones..."
cd "$HOME"
if [ -d "$HOME/repo/.git" ]; then
    cd "$HOME/repo" && git pull && cd "$HOME"
else
    rm -rf "$HOME/repo"
    git clone "$REPO_URL" "$HOME/repo"
fi
echo "    OK"

# ─────────────────────────────────────────────────────────────
# 3. Instalar los comandos en ~/bin (no necesita sudo)
# ─────────────────────────────────────────────────────────────
echo ">>> [3/3] Instalando los comandos 'correr' y 'correr-todas'..."
mkdir -p "$HOME/bin"

# ---- Comando: correr ----
cat > "$HOME/bin/correr" << 'CORRER_EOF'
#!/bin/bash
# Uso:  correr NOMBRE_CARPETA [num_cores] [v1|v2]
CARPETA="$1"
FORZAR_CORES="$2"
VERSION="${3:-v2}"

REPO="$HOME/repo"
GB_POR_PROCESO=5     # RAM reservada por proceso (subir si hay OOM, bajar si sobra RAM)

if [ "$VERSION" = "v1" ]; then
    IMAGEN="cesarsant2000/liggghts-motor"
else
    IMAGEN="cesarsant2000/liggghts-motor-v2"
fi

# Motor: docker o podman
if docker ps >/dev/null 2>&1; then MOTOR="docker"
elif command -v podman >/dev/null 2>&1; then MOTOR="podman"
else echo "ERROR: ni docker ni podman disponibles sin sudo."; exit 1
fi

if [ -z "$CARPETA" ]; then
    echo ""
    echo "  Uso:  correr NOMBRE_CARPETA [num_cores] [v1|v2]"
    echo ""
    echo "  Simulaciones disponibles:"
    find "$REPO" -name 'in.*' -type f | sed 's|.*/\([^/]*\)/in\..*|    - \1|' | sort -u
    echo ""
    exit 1
fi

RUTA=$(find "$REPO" -type d -name "$CARPETA" | head -1)
if [ -z "$RUTA" ]; then echo "  ERROR: No existe la carpeta '$CARPETA'."; exit 1; fi
ARCHIVO=$(find "$RUTA" -name 'in.*' -type f | head -1)
if [ -z "$ARCHIVO" ]; then echo "  ERROR: '$CARPETA' no tiene archivo in.*"; exit 1; fi
NOMBRE=$(basename "$ARCHIVO")

# Cores fisicos reales
FIS=$(lscpu -p=Core,Socket 2>/dev/null | grep -v '^#' | sort -u | wc -l)
if [ -z "$FIS" ] || [ "$FIS" -lt 1 ]; then FIS=$(nproc); fi
# RAM y tope por memoria
RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
RAM_GB=$((RAM_MB / 1024))
CAP=$((RAM_GB / GB_POR_PROCESO)); if [ "$CAP" -lt 1 ]; then CAP=1; fi
# Numero de procesos
CORES=$FIS; if [ "$CAP" -lt "$CORES" ]; then CORES=$CAP; fi
if [ -n "$FORZAR_CORES" ]; then CORES=$FORZAR_CORES; fi

echo "======================================================"
echo "  Simulacion : $CARPETA"
echo "  Archivo    : $NOMBRE"
echo "  Motor      : $MOTOR  |  Imagen: $IMAGEN"
echo "  Maquina    : $FIS cores fisicos, ${RAM_GB} GB RAM"
echo "  Usando     : $CORES procesos"
echo "  Inicio     : $(date '+%H:%M:%S del %d-%m-%Y')"
echo "======================================================"

TRABAJO="/tmp/trabajo_$USER/$CARPETA"
rm -rf "$TRABAJO"; mkdir -p "$TRABAJO/post"
cp -r "$RUTA"/. "$TRABAJO/"

if grep -q "^processors" "$TRABAJO/$NOMBRE"; then
    sed -i "s/^processors.*/processors $CORES 1 1/" "$TRABAJO/$NOMBRE"
else
    sed -i "/^create_box/a processors $CORES 1 1" "$TRABAJO/$NOMBRE"
fi

$MOTOR run --rm \
    -v "$TRABAJO":/simulaciones \
    "$IMAGEN" \
    mpirun -np $CORES --allow-run-as-root --bind-to none --oversubscribe \
    lmp380 -in /simulaciones/$NOMBRE -log /simulaciones/log_sim.txt
EXITO=$?

DESTINO="$RUTA/resultados"
mkdir -p "$DESTINO"
cp -r "$TRABAJO/post" "$DESTINO/" 2>/dev/null
cp "$TRABAJO"/*.csv "$DESTINO/" 2>/dev/null
cp "$TRABAJO"/rt_*.txt "$DESTINO/" 2>/dev/null
cp "$TRABAJO/log_sim.txt" "$DESTINO/" 2>/dev/null

echo "======================================================"
if [ $EXITO -eq 0 ]; then echo "  LISTO: $CARPETA"; else echo "  Termino con avisos (revisa el log): $CARPETA"; fi
echo "  Fin   : $(date '+%H:%M:%S del %d-%m-%Y')"
echo "  Resultados en: $DESTINO"
echo "======================================================"
CORRER_EOF
chmod +x "$HOME/bin/correr"

# ---- Comando: correr-todas ----
cat > "$HOME/bin/correr-todas" << 'TODAS_EOF'
#!/bin/bash
REPO="$HOME/repo"
mapfile -t CARPETAS < <(find "$REPO" -name 'in.*' -type f -exec dirname {} \; | sort -u | xargs -n1 basename)
TOTAL=${#CARPETAS[@]}; N=0
for C in "${CARPETAS[@]}"; do
    N=$((N+1))
    RUTA=$(find "$REPO" -type d -name "$C" | head -1)
    if [ -d "$RUTA/resultados" ] && [ "$(ls -A "$RUTA/resultados" 2>/dev/null)" ]; then
        echo ">> [$N/$TOTAL] $C ya tiene resultados, saltando."; continue
    fi
    echo ""; echo ">> [$N/$TOTAL] Corriendo $C ..."
    "$HOME/bin/correr" "$C"
done
echo ""; echo "=== Todas las simulaciones terminadas ==="
TODAS_EOF
chmod +x "$HOME/bin/correr-todas"

# Agregar ~/bin al PATH si no esta
if ! grep -q 'HOME/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
fi
export PATH="$HOME/bin:$PATH"
echo "    OK"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                  CONFIGURACION COMPLETA                   ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Activa los comandos con:   source ~/.bashrc             ║"
echo "║  (o simplemente reconectate)                             ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Ver lista de simulaciones:                              ║"
echo "║     correr                                               ║"
echo "║                                                          ║"
echo "║  Correr una:                                             ║"
echo "║     screen -S sim                                        ║"
echo "║     correr NOMBRE_DE_CARPETA                             ║"
echo "║     (Ctrl+A luego D para salir sin cortar)              ║"
echo "║                                                          ║"
echo "║  Correr todas en fila:                                   ║"
echo "║     screen -S sim                                        ║"
echo "║     correr-todas                                         ║"
echo "║                                                          ║"
echo "║  Ver avance:   screen -r sim                             ║"
echo "║  Resultados:   ~/repo/NOMBRE_CARPETA/resultados/         ║"
echo "╚══════════════════════════════════════════════════════════╝"
