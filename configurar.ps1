<#
.SYNOPSIS
    configurar.ps1 - Preparacion del entorno de simulaciones LIGGGHTS (Windows).

.DESCRIPTION
    Deja el equipo Windows listo para ejecutar simulaciones con Docker Desktop.
    Verifica que Docker este disponible, descarga los contenedores necesarios,
    actualiza el repositorio y, de forma opcional, configura los avisos por
    WhatsApp. Debe ejecutarse desde la carpeta del repositorio.

.NOTES
    Requisitos previos:
      - Docker Desktop instalado y en ejecucion.
      - git instalado (https://git-scm.com/download/win).

    Si PowerShell impide ejecutar el script, abra PowerShell y ejecute una vez:
      Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

.EXAMPLE
    .\configurar.ps1
#>

[CmdletBinding()]
param()

$RepoUrl  = 'https://github.com/Kelly-Ortiz/Tesis-Kelly-LIGGGHTS.git'
$ImagenV1 = 'cesarsant2000/liggghts-motor'
$ImagenV2 = 'cesarsant2000/liggghts-motor-v2'
$ArchivoConfigWhatsapp = Join-Path $env:USERPROFILE '.liggghts_whatsapp.conf'

Write-Host 'Preparando el entorno de simulaciones LIGGGHTS (Windows)...'

#------------------------------------------------------------------------------
# Verificacion de Docker Desktop
#------------------------------------------------------------------------------
Write-Host '[1/4] Verificando Docker Desktop...'
docker ps *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Error 'Docker Desktop no esta disponible o no esta en ejecucion.'
    Write-Host  'Abra Docker Desktop, espere a que inicie por completo y reintente.'
    exit 1
}
Write-Host '      Docker Desktop esta activo.'

#------------------------------------------------------------------------------
# Descarga de los contenedores
#------------------------------------------------------------------------------
Write-Host '[2/4] Descargando los contenedores de simulacion...'
docker pull $ImagenV1
docker pull $ImagenV2

#------------------------------------------------------------------------------
# Actualizacion del repositorio
#------------------------------------------------------------------------------
Write-Host '[3/4] Verificando el repositorio...'
if (Test-Path (Join-Path $PSScriptRoot '.git')) {
    git -C $PSScriptRoot pull
} else {
    Write-Host '      Este script no se esta ejecutando dentro del repositorio.'
    Write-Host "      Si aun no lo tiene, clonelo con:  git clone $RepoUrl"
}

#------------------------------------------------------------------------------
# Configuracion opcional de avisos por WhatsApp
#------------------------------------------------------------------------------
Write-Host '[4/4] Avisos por WhatsApp (opcional)...'
if (Test-Path $ArchivoConfigWhatsapp) {
    Write-Host '      Ya existe una configuracion de WhatsApp; se conserva la actual.'
} else {
    Write-Host '      Para recibir avisos del avance por WhatsApp:'
    Write-Host '        1. Guarde en sus contactos el numero  +34 611 08 28 80'
    Write-Host '        2. Enviele por WhatsApp el mensaje exacto:'
    Write-Host '              I allow callmebot to send me messages'
    Write-Host '        3. Recibira una respuesta con su APIKEY.'
    Write-Host ''
    $telefono = Read-Host '      Numero de WhatsApp con codigo de pais (Enter para omitir)'
    if ($telefono) {
        $apikey = Read-Host '      APIKEY recibido de CallMeBot'
        if ($apikey) {
            "WHATSAPP_PHONE=$telefono`nWHATSAPP_APIKEY=$apikey" |
                Set-Content -Path $ArchivoConfigWhatsapp -Encoding ASCII
            Write-Host '      Configuracion guardada. Pruebela con:  .\correr.ps1 -ProbarWhatsapp'
        } else {
            Write-Host '      No se ingreso un APIKEY; los avisos quedan desactivados.'
        }
    } else {
        Write-Host "      Avisos omitidos. Puede activarlos despues creando el archivo:"
        Write-Host "        $ArchivoConfigWhatsapp"
    }
}

Write-Host ''
Write-Host '=============================================================================='
Write-Host '  Configuracion completada.'
Write-Host '=============================================================================='
Write-Host ''
Write-Host '  Para empezar, desde la carpeta del repositorio:'
Write-Host '      .\correr.ps1 -Listar          (ver las simulaciones disponibles)'
Write-Host '      .\correr.ps1 NOMBRE           (ejecutar una simulacion)'
Write-Host ''
Write-Host '  Guia completa:'
Write-Host '      .\correr.ps1 -Ayuda'
Write-Host ''
Write-Host '=============================================================================='
