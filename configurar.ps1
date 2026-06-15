<#
.SYNOPSIS
    configurar.ps1 - Preparacion del entorno de simulaciones LIGGGHTS (Windows).

.DESCRIPTION
    Deja el equipo Windows listo para ejecutar simulaciones con Docker Desktop.
    Se ejecuta DESDE DENTRO del repositorio ya clonado. Verifica Docker, descarga
    los contenedores y, opcionalmente, configura los avisos por WhatsApp. No clona
    ni modifica el repositorio: respeta la copia y la rama actuales.

    En Windows el comando se ejecuta directamente desde la carpeta del repositorio
    (.\correr.ps1), por lo que siempre corresponde a la rama activa sin pasos
    adicionales de instalacion.

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

$ImagenV1 = 'cesarsant2000/liggghts-motor'
$ImagenV2 = 'cesarsant2000/liggghts-motor-v2'
$ArchivoConfigWhatsapp = Join-Path $env:USERPROFILE '.liggghts_whatsapp.conf'

Write-Host 'Preparando el entorno de simulaciones LIGGGHTS (Windows)...'

# Ubicar la raiz del repositorio a partir del directorio actual.
$DirRepo = (git rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $DirRepo) {
    Write-Error 'Ejecute este script desde dentro de la carpeta del repositorio.'
    exit 1
}
Write-Host "Repositorio detectado: $($DirRepo.Trim())"

Write-Host '[1/3] Verificando Docker Desktop...'
docker ps *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Error 'Docker Desktop no esta disponible o no esta en ejecucion.'
    Write-Host  'Abra Docker Desktop, espere a que inicie por completo y reintente.'
    exit 1
}
Write-Host '      Docker Desktop esta activo.'

Write-Host '[2/3] Descargando los contenedores de simulacion...'
docker pull $ImagenV1
docker pull $ImagenV2

Write-Host '[3/3] Avisos por WhatsApp (opcional)...'
if (Test-Path $ArchivoConfigWhatsapp) {
    Write-Host '      Ya existe una configuracion de WhatsApp; se conserva.'
} else {
    Write-Host '      Para recibir avisos, primero active CallMeBot desde su telefono'
    Write-Host '      (vea .\correr.ps1 -Ayuda). Luego ingrese los datos o pulse Enter'
    Write-Host '      para omitir.'
    $telefono = Read-Host '      Numero de WhatsApp con codigo de pais (Enter para omitir)'
    if ($telefono) {
        $apikey = Read-Host '      APIKEY recibido de CallMeBot'
        if ($apikey) {
            "WHATSAPP_PHONE=$telefono`nWHATSAPP_APIKEY=$apikey" |
                Set-Content -Path $ArchivoConfigWhatsapp -Encoding ASCII
            Write-Host '      Configuracion guardada. Pruebela con:  .\correr.ps1 -ProbarWhatsapp'
        } else {
            Write-Host '      Sin APIKEY; avisos desactivados.'
        }
    } else {
        Write-Host "      Avisos omitidos. Para activarlos luego, cree $ArchivoConfigWhatsapp."
    }
}

Write-Host ''
Write-Host '=============================================================================='
Write-Host '  Configuracion completada.'
Write-Host '=============================================================================='
Write-Host ''
Write-Host '  El comando se ejecuta desde la carpeta del repositorio y respeta la rama'
Write-Host '  activa automaticamente:'
Write-Host '      .\correr.ps1 -Listar       (ver simulaciones de la rama actual)'
Write-Host '      .\correr.ps1 NOMBRE        (ejecutar una simulacion)'
Write-Host '      .\correr.ps1 -Ayuda        (guia completa)'
Write-Host ''
Write-Host '=============================================================================='
