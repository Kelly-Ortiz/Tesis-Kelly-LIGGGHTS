#!/usr/bin/env bash
#==============================================================================
# configurar.sh — Preparación del entorno de simulaciones LIGGGHTS (Linux)
#==============================================================================
#
# DESCRIPCIÓN
#   Deja la máquina lista para ejecutar simulaciones. Se ejecuta DESDE DENTRO
#   del repositorio ya clonado. Descarga los contenedores, instala el comando
#   'correr' en ~/bin (independiente de la rama) y, opcionalmente, configura los
#   avisos por WhatsApp. No clona ni modifica el repositorio: respeta la copia y
#   la rama en la que se encuentra la usuaria.
#
# REQUISITOS PREVIOS (los instala el administrador del equipo)
#   - Docker Engine, con el usuario en el grupo 'docker'; o bien Podman.
#   - git
#   - screen
#
# USO
#   Desde la carpeta del repositorio:
#       bash configurar.sh
#
# DESPUÉS
#   Ejecute 'source ~/.bashrc' o vuelva a conectarse. Use 'correr --ayuda'.
#   El comando 'correr' queda instalado de forma global, así que funciona en
#   cualquier rama sin volver a configurar. Si actualiza la herramienta en el
#   repositorio, reinstale con:  correr --actualizar
#==============================================================================

set -uo pipefail

readonly DIR_BIN="${HOME}/bin"
readonly IMAGEN_V1="cesarsant2000/liggghts-motor"
readonly IMAGEN_V2="cesarsant2000/liggghts-motor-v2"
readonly ARCHIVO_CONFIG_WHATSAPP="${HOME}/.liggghts_whatsapp.conf"

#------------------------------------------------------------------------------
# detectar_motor
#------------------------------------------------------------------------------
detectar_motor() {
    if docker ps >/dev/null 2>&1; then echo "docker"
    elif command -v podman >/dev/null 2>&1; then echo "podman"
    else return 1; fi
}

echo "Preparando el entorno de simulaciones LIGGGHTS..."

# Ubicar la raíz del repositorio a partir del directorio actual.
DIR_REPO=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -z "${DIR_REPO}" ]]; then
    echo "ERROR: Ejecute este script desde dentro de la carpeta del repositorio." >&2
    echo "       (la que contiene 'correr' y las carpetas de simulación)." >&2
    exit 1
fi
echo "Repositorio detectado: ${DIR_REPO}"

motor=$(detectar_motor)
if [[ -z "${motor:-}" ]]; then
    echo "ERROR: No se encontró Docker ni Podman utilizable sin privilegios." >&2
    echo "       Pida al administrador que instale Docker y lo agregue al grupo" >&2
    echo "       'docker'; luego vuelva a conectarse y ejecute este script." >&2
    exit 1
fi
echo "Motor de contenedores detectado: ${motor}"

echo "[1/3] Descargando los contenedores de simulación..."
"${motor}" pull "${IMAGEN_V1}"
"${motor}" pull "${IMAGEN_V2}"

echo "[2/3] Instalando el comando 'correr' en ~/bin..."
if [[ ! -f "${DIR_REPO}/correr" ]]; then
    echo "ERROR: No se encontró 'correr' en la raíz del repositorio." >&2
    exit 1
fi
mkdir -p "${DIR_BIN}"
install -m 0755 "${DIR_REPO}/correr" "${DIR_BIN}/correr"
if ! grep -qs 'HOME/bin' "${HOME}/.bashrc"; then
    echo 'export PATH="$HOME/bin:$PATH"' >> "${HOME}/.bashrc"
fi
export PATH="${HOME}/bin:${PATH}"

echo "[3/3] Avisos por WhatsApp (opcional)..."
if [[ -f "${ARCHIVO_CONFIG_WHATSAPP}" ]]; then
    echo "      Ya existe una configuración de WhatsApp; se conserva."
else
    echo "      Para recibir avisos, primero active CallMeBot desde su teléfono"
    echo "      (vea 'correr --ayuda'). Luego ingrese los datos, o pulse Enter"
    echo "      para omitir y configurarlo más tarde."
    read -r -p "      Número de WhatsApp con código de país (Enter para omitir): " ws_telefono
    if [[ -n "${ws_telefono}" ]]; then
        read -r -p "      APIKEY recibido de CallMeBot: " ws_apikey
        if [[ -n "${ws_apikey}" ]]; then
            printf 'WHATSAPP_PHONE=%s\nWHATSAPP_APIKEY=%s\n' "${ws_telefono}" "${ws_apikey}" \
                > "${ARCHIVO_CONFIG_WHATSAPP}"
            chmod 600 "${ARCHIVO_CONFIG_WHATSAPP}"
            echo "      Configuración guardada. Pruébela con:  correr --probar-whatsapp"
        else
            echo "      Sin APIKEY; avisos desactivados."
        fi
    else
        echo "      Avisos omitidos. Para activarlos luego, cree ${ARCHIVO_CONFIG_WHATSAPP}."
    fi
fi

cat <<'FIN'

==============================================================================
  Configuración completada.
==============================================================================

  Active el comando:   source ~/.bashrc   (o vuelva a conectarse)

  El comando 'correr' funciona en CUALQUIER rama sin volver a configurar.
  Ejecútelo siempre desde dentro de la carpeta del repositorio:

      correr --listar       (ver simulaciones de la rama actual)
      correr NOMBRE         (ejecutar una simulación)
      correr --ayuda        (guía completa)

  Si actualiza la herramienta en el repositorio:
      correr --actualizar

==============================================================================
FIN
