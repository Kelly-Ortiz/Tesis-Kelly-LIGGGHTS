#!/usr/bin/env bash
#==============================================================================
# configurar.sh — Preparación del entorno de simulaciones LIGGGHTS (Linux)
#==============================================================================
#
# DESCRIPCIÓN
#   Deja la máquina lista para ejecutar simulaciones. Descarga los
#   contenedores necesarios, actualiza el repositorio e instala los
#   comandos de usuario. No requiere privilegios de administrador, siempre
#   que Docker (o Podman), git y screen ya estén instalados en el sistema.
#
# REQUISITOS PREVIOS (los instala el administrador del equipo)
#   - Docker Engine, con el usuario añadido al grupo 'docker'; o bien Podman.
#   - git
#   - screen
#
# USO
#   bash configurar.sh
#
# DESPUÉS DE EJECUTAR
#   Ejecute 'source ~/.bashrc' o vuelva a conectarse, y luego utilice el
#   comando 'correr'. Consulte 'correr --ayuda' para la guía de uso.
#==============================================================================

set -uo pipefail

readonly REPO_URL="https://github.com/Kelly-Ortiz/Tesis-Kelly-LIGGGHTS.git"
readonly DIR_REPO="${HOME}/repo"
readonly DIR_BIN="${HOME}/bin"
readonly IMAGEN_V1="cesarsant2000/liggghts-motor"
readonly IMAGEN_V2="cesarsant2000/liggghts-motor-v2"

#------------------------------------------------------------------------------
# detectar_motor
#   Determina el motor de contenedores disponible sin privilegios.
#------------------------------------------------------------------------------
detectar_motor() {
    if docker ps >/dev/null 2>&1; then
        echo "docker"
    elif command -v podman >/dev/null 2>&1; then
        echo "podman"
    else
        return 1
    fi
}

#------------------------------------------------------------------------------
# Programa principal
#------------------------------------------------------------------------------
echo "Preparando el entorno de simulaciones LIGGGHTS..."

motor=$(detectar_motor)
if [[ -z "${motor:-}" ]]; then
    echo "ERROR: No se encontró Docker ni Podman utilizable sin privilegios." >&2
    echo "       Verifique con el administrador que Docker esté instalado y" >&2
    echo "       que su usuario pertenezca al grupo 'docker'. Luego vuelva a" >&2
    echo "       conectarse y ejecute este script de nuevo." >&2
    exit 1
fi
echo "Motor de contenedores detectado: ${motor}"

echo "[1/3] Descargando los contenedores de simulación..."
"${motor}" pull "${IMAGEN_V1}"
"${motor}" pull "${IMAGEN_V2}"

echo "[2/3] Obteniendo el repositorio de simulaciones..."
if [[ -d "${DIR_REPO}/.git" ]]; then
    git -C "${DIR_REPO}" pull
else
    rm -rf "${DIR_REPO}"
    git clone "${REPO_URL}" "${DIR_REPO}"
fi

echo "[3/3] Instalando el comando 'correr'..."
mkdir -p "${DIR_BIN}"
if [[ -f "${DIR_REPO}/correr" ]]; then
    install -m 0755 "${DIR_REPO}/correr" "${DIR_BIN}/correr"
else
    echo "ERROR: No se encontró el archivo 'correr' en el repositorio." >&2
    echo "       Asegúrese de que 'correr' esté subido al repositorio." >&2
    exit 1
fi

if ! grep -qs 'HOME/bin' "${HOME}/.bashrc"; then
    echo 'export PATH="$HOME/bin:$PATH"' >> "${HOME}/.bashrc"
fi
export PATH="${HOME}/bin:${PATH}"

cat <<'FIN'

==============================================================================
  Configuración completada.
==============================================================================

  Active el comando ejecutando:   source ~/.bashrc
  (o simplemente vuelva a conectarse)

  Para empezar:
      screen -S sim
      correr --listar          (ver las simulaciones disponibles)
      correr NOMBRE             (ejecutar una simulación)

  Guía completa:
      correr --ayuda

==============================================================================
FIN
