#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#   INSTALADOR LIGGGHTS — para la maquina Linux de Kelly
#   ───────────────────────────────────────────────────────────────
#   COMO USARLO (una sola vez, despues de conectarse por VPN/terminal):
#
#     1. Guardar este archivo como  instalar.sh
#     2. Ejecutar:   bash instalar.sh
#     3. Esperar a que termine (~15-20 min la primera vez)
#     4. CERRAR la terminal y volver a conectarse (para activar Docker)
#     5. Listo: usar el comando  correr NOMBRE_DE_CARPETA
#
#   Repo:  https://github.com/Kelly-Ortiz/Tesis-Kelly-LIGGGHTS  (publico)
# ═══════════════════════════════════════════════════════════════════

set -e

REPO_URL="https://github.com/Kelly-Ortiz/Tesis-Kelly-LIGGGHTS.git"
IMG1="cesarsant2000/liggghts-motor"
IMG2="cesarsant2000/liggghts-motor-v2"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║      INSTALADOR LIGGGHTS — Maquina de Kelly      ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ─────────────────────────────────────────────────────────────
# 1. Herramientas basicas (git, screen, curl)
# ─────────────────────────────────────────────────────────────
echo ">>> [1/5] Instalando herramientas basicas (git, screen, curl)..."
if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y git screen curl ca-certificates
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y git screen curl ca-certificates
elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y git screen curl ca-certificates
else
    echo "    AVISO: No reconoci el gestor de paquetes. Instala git y screen a mano."
fi
echo "    OK"

# ─────────────────────────────────────────────────────────────
# 2. Docker
# ─────────────────────────────────────────────────────────────
echo ">>> [2/5] Instalando Docker..."
if command -v docker >/dev/null 2>&1; then
    echo "    Docker ya estaba instalado."
else
    curl -fsSL https://get.docker.com | sudo bash
fi
# Permitir usar docker sin sudo (se activa al reconectar)
sudo groupadd docker 2>/dev/null || true
sudo usermod -aG docker "$USER"
# Arrancar el servicio Docker
sudo systemctl enable --now docker 2>/dev/null || sudo service docker start 2>/dev/null || true
echo "    OK"

# ─────────────────────────────────────────────────────────────
# 3. Descargar los DOS contenedores
# ─────────────────────────────────────────────────────────────
echo ">>> [3/5] Descargando los dos contenedores LIGGGHTS (puede tardar)..."
sudo docker pull "$IMG1"
sudo docker pull "$IMG2"
echo "    OK"

# ─────────────────────────────────────────────────────────────
# 4. Clonar el repositorio
# ─────────────────────────────────────────────────────────────
echo ">>> [4/5] Descargando el repositorio de simulaciones..."
cd "$HOME"
if [ -d "$HOME/repo/.git" ]; then
    echo "    El repo ya existe, actualizando..."
    cd "$HOME/repo" && git pull && cd "$HOME"
else
    rm -rf "$HOME/repo"
    git clone "$REPO_URL" "$HOME/repo"
fi
echo "    OK"

# ─────────────────────────────────────────────────────────────
# 5. Instalar los comandos 'correr' y 'correr-todas'
# ─────────────────────────────────────────────────────────────
echo ">>> [5/5] Instalando los comandos 'correr' y 'correr-todas'..."

# ---- Comando: correr ----
sudo tee /usr/local/bin/correr > /dev/null << 'CORRER_EOF'
#!/bin/bash
# Uso:  correr NOMBRE_CARPETA [num_cores] [v1|v2]
#   - num_cores: opcional. Si no se pone, se calcula solo segun CPU y RAM.
#   - v1|v2:     opcional. Imagen a usar. Por defecto v2.

CARPETA="$1"
FORZAR_CORES="$2"
VERSION="${3:-v2}"

REPO="$HOME/repo"
GB_POR_PROCESO=5     # cuanta RAM reservar por proceso (subir si hay OOM, bajar si sobra RAM)

# Elegir imagen
if [ "$VERSION" = "v1" ]; then
    IMAGEN="cesarsant2000/liggghts-motor"
else
    IMAGEN="cesarsant2000/liggghts-motor-v2"
fi

# docker o sudo docker?
if docker ps >/dev/null 2>&1; then DOCKER="docker"; else DOCKER="sudo docker"; fi

# Sin argumento: mostrar lista
if [ -z "$CARPETA" ]; then
    echo ""
    echo "  Uso:  correr NOMBRE_CARPETA [num_cores] [v1|v2]"
    echo ""
    echo "  Simulaciones disponibles en el repo:"
    find "$REPO" -name 'in.*' -type f | sed 's|.*/\([^/]*\)/in\..*|    - \1|' | sort -u
    echo ""
    exit 1
fi

RUTA=$(find "$REPO" -type d -name "$CARPETA" | head -1)
if [ -z "$RUTA" ]; then
    echo "  ERROR: No encontre la carpeta '$CARPETA' en el repo."
    exit 1
fi
ARCHIVO=$(find "$RUTA" -name 'in.*' -type f | head -1)
if [ -z "$ARCHIVO" ]; then
    echo "  ERROR: La carpeta '$CARPETA' no tiene archivo in.*"
    exit 1
fi
NOMBRE=$(basename "$ARCHIVO")

# --- Detectar cores fisicos reales ---
FIS=$(lscpu -p=Core,Socket 2>/dev/null | grep -v '^#' | sort -u | wc -l)
if [ -z "$FIS" ] || [ "$FIS" -lt 1 ]; then FIS=$(nproc); fi

# --- Detectar RAM y calcular tope por memoria ---
RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
RAM_GB=$((RAM_MB / 1024))
CAP=$((RAM_GB / GB_POR_PROCESO))
if [ "$CAP" -lt 1 ]; then CAP=1; fi

# --- Decidir numero de procesos ---
CORES=$FIS
if [ "$CAP" -lt "$CORES" ]; then CORES=$CAP; fi
if [ -n "$FORZAR_CORES" ]; then CORES=$FORZAR_CORES; fi

echo "======================================================"
echo "  Simulacion : $CARPETA"
echo "  Archivo    : $NOMBRE"
echo "  Imagen     : $IMAGEN"
echo "  Maquina    : $FIS cores fisicos, ${RAM_GB} GB RAM"
echo "  Usando     : $CORES procesos"
echo "  Inicio     : $(date '+%H:%M:%S del %d-%m-%Y')"
echo "======================================================"

# Copia de trabajo (no toca el original del repo)
TRABAJO="/tmp/trabajo/$CARPETA"
rm -rf "$TRABAJO"
mkdir -p "$TRABAJO/post"
cp -r "$RUTA"/. "$TRABAJO/"

# Ajustar 'processors' al numero de procesos (geometria del tornillo: en X)
if grep -q "^processors" "$TRABAJO/$NOMBRE"; then
    sed -i "s/^processors.*/processors $CORES 1 1/" "$TRABAJO/$NOMBRE"
else
    sed -i "/^create_box/a processors $CORES 1 1" "$TRABAJO/$NOMBRE"
fi

# Ejecutar
$DOCKER run --rm \
    -v "$TRABAJO":/simulaciones \
    "$IMAGEN" \
    mpirun -np $CORES --allow-run-as-root --bind-to none --oversubscribe \
    lmp380 -in /simulaciones/$NOMBRE -log /simulaciones/log_sim.txt

EXITO=$?

# Guardar resultados de vuelta en la carpeta del repo
DESTINO="$RUTA/resultados"
mkdir -p "$DESTINO"
cp -r "$TRABAJO/post" "$DESTINO/" 2>/dev/null
cp "$TRABAJO"/*.csv "$DESTINO/" 2>/dev/null
cp "$TRABAJO"/rt_*.txt "$DESTINO/" 2>/dev/null
cp "$TRABAJO/log_sim.txt" "$DESTINO/" 2>/dev/null

echo "======================================================"
if [ $EXITO -eq 0 ]; then
    echo "  LISTO: $CARPETA"
else
    echo "  TERMINO CON AVISOS (revisa el log): $CARPETA"
fi
echo "  Fin   : $(date '+%H:%M:%S del %d-%m-%Y')"
echo "  Resultados en: $DESTINO"
echo "======================================================"
CORRER_EOF
sudo chmod +x /usr/local/bin/correr

# ---- Comando: correr-todas ----
sudo tee /usr/local/bin/correr-todas > /dev/null << 'TODAS_EOF'
#!/bin/bash
# Corre TODAS las simulaciones del repo, una por una.
# Salta las que ya tienen carpeta 'resultados'.
REPO="$HOME/repo"

mapfile -t CARPETAS < <(find "$REPO" -name 'in.*' -type f \
    -exec dirname {} \; | sort -u | xargs -n1 basename)

TOTAL=${#CARPETAS[@]}
N=0
for C in "${CARPETAS[@]}"; do
    N=$((N+1))
    RUTA=$(find "$REPO" -type d -name "$C" | head -1)
    if [ -d "$RUTA/resultados" ] && [ "$(ls -A "$RUTA/resultados" 2>/dev/null)" ]; then
        echo ">> [$N/$TOTAL] $C ya tiene resultados, saltando."
        continue
    fi
    echo ""
    echo ">> [$N/$TOTAL] Corriendo $C ..."
    correr "$C"
done
echo ""
echo "=== Todas las simulaciones terminadas ==="
TODAS_EOF
sudo chmod +x /usr/local/bin/correr-todas

echo "    OK"

# ─────────────────────────────────────────────────────────────
# Final
# ─────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                  INSTALACION COMPLETA                     ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  IMPORTANTE: cierra esta terminal y vuelve a conectarte  ║"
echo "║  (para que Docker funcione sin sudo)                     ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Despues, para usar:                                     ║"
echo "║                                                          ║"
echo "║    Ver lista de simulaciones:                            ║"
echo "║       correr                                             ║"
echo "║                                                          ║"
echo "║    Correr una (deja que elija cores solo):               ║"
echo "║       screen -S sim                                      ║"
echo "║       correr NOMBRE_DE_CARPETA                           ║"
echo "║       (Ctrl+A luego D para salir sin cortar)            ║"
echo "║                                                          ║"
echo "║    Correr todas en fila:                                 ║"
echo "║       screen -S sim                                      ║"
echo "║       correr-todas                                       ║"
echo "║                                                          ║"
echo "║    Volver a ver el avance:                               ║"
echo "║       screen -r sim                                      ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Los resultados quedan en:                               ║"
echo "║     ~/repo/NOMBRE_CARPETA/resultados/                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
