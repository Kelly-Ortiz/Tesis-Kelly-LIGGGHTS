<#
.SYNOPSIS
    configurar.ps1 - Preparacion del entorno de simulaciones LIGGGHTS (Windows).

.DESCRIPTION
    Deja el equipo Windows listo para ejecutar simulaciones con Docker Desktop.
    Verifica que Docker este disponible, descarga los contenedores necesarios y
    actualiza el repositorio. Debe ejecutarse desde la carpeta del repositorio.

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

Write-Host 'Preparando el entorno de simulaciones LIGGGHTS (Windows)...'

#------------------------------------------------------------------------------
# Verificacion de Docker Desktop
#------------------------------------------------------------------------------
Write-Host '[1/3] Verificando Docker Desktop...'
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
Write-Host '[2/3] Descargando los contenedores de simulacion...'
docker pull $ImagenV1
docker pull $ImagenV2

#------------------------------------------------------------------------------
# Actualizacion del repositorio
#------------------------------------------------------------------------------
Write-Host '[3/3] Verificando el repositorio...'
if (Test-Path (Join-Path $PSScriptRoot '.git')) {
    git -C $PSScriptRoot pull
} else {
    Write-Host '      Este script no se esta ejecutando dentro del repositorio.'
    Write-Host "      Si aun no lo tiene, clonelo con:"
    Write-Host "        git clone $RepoUrl"
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
