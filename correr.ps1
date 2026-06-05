<#
.SYNOPSIS
    correr.ps1 - Ejecutor de simulaciones LIGGGHTS con respaldo automatico (Windows).

.DESCRIPTION
    Ejecuta una simulacion LIGGGHTS alojada en el repositorio de la tesis usando
    Docker Desktop. Detecta los recursos de la maquina, ajusta la descomposicion
    del dominio y escribe puntos de control periodicos que permiten reanudar la
    simulacion tras cualquier interrupcion sin introducir artefactos en la fisica
    del tornillo giratorio.

.PARAMETER Simulacion
    Nombre de la carpeta de la simulacion dentro del repositorio.

.PARAMETER Nucleos
    Numero de procesos a utilizar. Si se omite, se calcula segun CPU y memoria.

.PARAMETER Version
    Version del contenedor: v1 o v2. Valor predeterminado: v2.

.PARAMETER Reiniciar
    Fuerza el inicio desde cero, descartando cualquier punto de control.

.PARAMETER Listar
    Muestra las simulaciones disponibles y termina.

.PARAMETER Estado
    Muestra el avance de las simulaciones y termina.

.PARAMETER Todas
    Ejecuta en orden todas las simulaciones pendientes.

.PARAMETER Ayuda
    Muestra la ayuda y termina.

.EXAMPLE
    .\correr.ps1 MASVEL2MENCOFAZURE
    Ejecuta la simulacion con la configuracion automatica.

.EXAMPLE
    .\correr.ps1 MASVEL2MENCOFAZURE -Nucleos 4 -Version v2
    Ejecuta usando 4 procesos y el contenedor v2.

.EXAMPLE
    .\correr.ps1 MASVEL2MENCOFAZURE -Reiniciar
    Ignora el respaldo y empieza desde cero.

.NOTES
    Requiere Docker Desktop instalado y en ejecucion. El repositorio debe estar
    clonado en la carpeta indicada por la variable $DirRepo (por defecto, la
    carpeta donde se encuentra este script).
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Simulacion,

    [Alias('n')]
    [int]$Nucleos = 0,

    [Alias('v')]
    [ValidateSet('v1', 'v2')]
    [string]$Version = 'v2',

    [Alias('r')]
    [switch]$Reiniciar,

    [Alias('l')]
    [switch]$Listar,

    [Alias('e')]
    [switch]$Estado,

    [Alias('t')]
    [switch]$Todas,

    [Alias('h')]
    [switch]$Ayuda
)

#------------------------------------------------------------------------------
# Parametros de configuracion del entorno
#------------------------------------------------------------------------------
$DirRepo    = $PSScriptRoot
$DirTrabajo = Join-Path $env:USERPROFILE 'runs'
$GbPorProceso = 5
$ImagenV1 = 'cesarsant2000/liggghts-motor'
$ImagenV2 = 'cesarsant2000/liggghts-motor-v2'
$PasosRespaldoPorDefecto = 1000000

#------------------------------------------------------------------------------
# Mostrar-Ayuda
#   Imprime la guia de uso orientada a la usuaria final.
#------------------------------------------------------------------------------
function Mostrar-Ayuda {
    @'
==============================================================================
  correr.ps1 - Ejecutor de simulaciones LIGGGHTS (Windows)
==============================================================================

QUE HACE
  Corre una simulacion del repositorio de la tesis usando Docker Desktop.
  Elige automaticamente cuantos procesos usar y guarda puntos de control
  para poder retomar la simulacion si se interrumpe.

FORMA DE USO
  .\correr.ps1 <simulacion> [opciones]

EJEMPLOS
  .\correr.ps1 MASVEL2MENCOFAZURE
        Corre esa simulacion con la configuracion automatica.

  .\correr.ps1 MASVEL2MENCOFAZURE -Nucleos 4
        Corre usando exactamente 4 procesos.

  .\correr.ps1 MASVEL2MENCOFAZURE -Version v1
        Corre usando el contenedor v1 en lugar del v2 (predeterminado).

  .\correr.ps1 MASVEL2MENCOFAZURE -Reiniciar
        Ignora cualquier punto de control y empieza desde cero.

OPCIONES
  -Nucleos N     Numero de procesos a utilizar.
                 Si se omite, se calcula segun CPU y memoria.
  -Version V     Version del contenedor: v1 o v2. Predeterminado: v2.
  -Reiniciar     Fuerza el inicio desde cero (descarta el respaldo).
  -Listar        Muestra las simulaciones disponibles y termina.
  -Estado        Muestra el avance de las simulaciones y termina.
  -Todas         Ejecuta en orden todas las simulaciones pendientes.
  -Ayuda         Muestra esta ayuda y termina.

QUE HACER SI SE INTERRUMPE
  Vuelva a ejecutar exactamente el mismo comando. El programa detecta el
  ultimo punto de control y reanuda la simulacion automaticamente.

DONDE QUEDAN LOS RESULTADOS
  <repositorio>\<simulacion>\resultados\

==============================================================================
'@ | Write-Host
}

#------------------------------------------------------------------------------
# Test-Docker
#   Verifica que Docker Desktop este disponible y en ejecucion.
#------------------------------------------------------------------------------
function Test-Docker {
    try {
        docker ps *> $null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

#------------------------------------------------------------------------------
# Get-Procesos
#   Calcula el numero de procesos combinando los nucleos fisicos y un limite
#   por memoria para no agotar la RAM. Acepta un valor forzado opcional.
#------------------------------------------------------------------------------
function Get-Procesos {
    param([int]$Forzado = 0)

    $fisicos = (Get-CimInstance -ClassName Win32_Processor |
                Measure-Object -Property NumberOfCores -Sum).Sum
    if (-not $fisicos -or $fisicos -lt 1) { $fisicos = [int]$env:NUMBER_OF_PROCESSORS }

    $ramBytes = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory
    $ramGb = [math]::Floor($ramBytes / 1GB)
    $tope = [math]::Floor($ramGb / $GbPorProceso)
    if ($tope -lt 1) { $tope = 1 }

    $procesos = [math]::Min($fisicos, $tope)
    if ($Forzado -gt 0) { $procesos = $Forzado }
    return [int]$procesos
}

#------------------------------------------------------------------------------
# Get-RutaSimulacion
#   Localiza la carpeta de una simulacion dentro del repositorio.
#------------------------------------------------------------------------------
function Get-RutaSimulacion {
    param([string]$Nombre)
    $dir = Get-ChildItem -Path $DirRepo -Directory -Recurse -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -eq $Nombre } | Select-Object -First 1
    if ($dir) { return $dir.FullName } else { return $null }
}

#------------------------------------------------------------------------------
# Get-Simulaciones
#   Devuelve los nombres de todas las simulaciones disponibles.
#------------------------------------------------------------------------------
function Get-Simulaciones {
    Get-ChildItem -Path $DirRepo -Recurse -Filter 'in.*' -File -ErrorAction SilentlyContinue |
        ForEach-Object { $_.Directory.Name } | Sort-Object -Unique
}

#------------------------------------------------------------------------------
# Mostrar-Listado
#------------------------------------------------------------------------------
function Mostrar-Listado {
    Write-Host 'Simulaciones disponibles en el repositorio:'
    foreach ($s in Get-Simulaciones) { Write-Host "  - $s" }
}

#------------------------------------------------------------------------------
# Mostrar-Estado
#   Resume el avance de cada simulacion con trabajo en curso o resultados.
#------------------------------------------------------------------------------
function Mostrar-Estado {
    Write-Host 'Estado de las simulaciones:'
    if (-not (Test-Path $DirTrabajo)) { Write-Host '  (sin simulaciones en curso)'; return }
    foreach ($dir in Get-ChildItem -Path $DirTrabajo -Directory) {
        $log = Join-Path $dir.FullName 'log_sim.txt'
        $paso = '(sin iniciar)'
        if (Test-Path $log) {
            $m = Select-String -Path $log -Pattern '^\s*(\d+)' -AllMatches |
                 Select-Object -Last 1
            if ($m) { $paso = ($m.Matches[0].Value).Trim() }
        }
        $estado = 'en progreso'
        if (Test-Path (Join-Path $DirRepo "$($dir.Name)\resultados\COMPLETADO")) {
            $estado = 'COMPLETADA'
        }
        '{0,-30} paso: {1,-12} estado: {2}' -f $dir.Name, $paso, $estado | Write-Host
    }
}

#------------------------------------------------------------------------------
# Get-PasosPorVuelta
#   Calcula cada cuantos pasos el tornillo completa una vuelta, leyendo dt y
#   screwPeriod del archivo de entrada, para alinear los puntos de control.
#------------------------------------------------------------------------------
function Get-PasosPorVuelta {
    param([string]$Archivo)
    $contenido = Get-Content -Path $Archivo
    $dt = ($contenido | Select-String -Pattern 'variable\s+dt\s+equal\s+(\S+)' |
           Select-Object -First 1).Matches.Groups[1].Value
    $periodo = ($contenido | Select-String -Pattern 'variable\s+screwPeriod\s+equal\s+(\S+)' |
                Select-Object -First 1).Matches.Groups[1].Value
    if ($dt -and $periodo) {
        try {
            $pasos = [int]([double]$periodo / [double]$dt)
            if ($pasos -ge 1) { return $pasos }
        } catch { }
    }
    return $PasosRespaldoPorDefecto
}

#------------------------------------------------------------------------------
# New-InputReanudacion
#   Transforma el archivo de entrada original en una version de reanudacion:
#   lee el punto de control, desactiva la insercion de particulas, omite la
#   fase de llenado y continua hasta el numero total de pasos.
#------------------------------------------------------------------------------
function New-InputReanudacion {
    param(
        [string]$Origen,
        [string]$Destino,
        [string]$ArchivoRestart,
        [int]$Pasos
    )
    $salida = New-Object System.Collections.Generic.List[string]
    $continuacion = $false
    foreach ($linea in Get-Content -Path $Origen) {
        if ($continuacion) {
            $salida.Add("# [reanudacion] $linea")
            $continuacion = $linea -match '&\s*$'
            continue
        }
        if ($linea -match '^\s*create_box') {
            $salida.Add("read_restart $ArchivoRestart")
            continue
        }
        if ($linea -match 'particletemplate|particledistribution|mesh/surface/planar|insert/stream') {
            $salida.Add("# [reanudacion] $linea")
            if ($linea -match '&\s*$') { $continuacion = $true }
            continue
        }
        if ($linea -match '^\s*unfix\s+ins\s*$') {
            $salida.Add("# [reanudacion] $linea")
            continue
        }
        if ($linea -match '^\s*run\s+\$\{fillsteps\}') {
            $salida.Add("# [reanudacion] $linea")
            continue
        }
        if ($linea -match '^\s*run\s+\$\{dischargesteps\}') {
            $salida.Add('variable totalsteps equal ${fillsteps}+${dischargesteps}')
            $salida.Add("restart $Pasos restart.continuar.a restart.continuar.b")
            $salida.Add('run ${totalsteps} upto')
            continue
        }
        $salida.Add($linea)
    }
    Set-Content -Path $Destino -Value $salida -Encoding ASCII
}

#------------------------------------------------------------------------------
# Invoke-Simulacion
#   Orquesta la ejecucion completa: prepara el directorio de trabajo, decide
#   entre iniciar o reanudar, lanza el contenedor y archiva los resultados.
#------------------------------------------------------------------------------
function Invoke-Simulacion {
    param(
        [string]$Nombre,
        [int]$Forzado,
        [string]$Ver,
        [bool]$Reinicio
    )

    if (-not (Test-Docker)) {
        Write-Error 'Docker Desktop no esta disponible o no esta en ejecucion. Abralo y reintente.'
        return 1
    }

    $imagen = if ($Ver -eq 'v1') { $ImagenV1 } else { $ImagenV2 }

    $ruta = Get-RutaSimulacion -Nombre $Nombre
    if (-not $ruta) {
        Write-Error "No existe la simulacion '$Nombre'. Use -Listar para ver las disponibles."
        return 1
    }

    $archivo = Get-ChildItem -Path $ruta -Filter 'in.*' -File | Select-Object -First 1
    if (-not $archivo) {
        Write-Error "La carpeta '$Nombre' no contiene un archivo de entrada in.*"
        return 1
    }
    $entrada = $archivo.Name

    $procesos = Get-Procesos -Forzado $Forzado
    $pasos = Get-PasosPorVuelta -Archivo $archivo.FullName

    $dirRun = Join-Path $DirTrabajo $Nombre
    $restartA = Join-Path $dirRun 'restart.continuar.a'
    $restartB = Join-Path $dirRun 'restart.continuar.b'

    $reciente = $null
    if (-not $Reinicio) {
        foreach ($c in @($restartA, $restartB)) {
            if ((Test-Path $c) -and ((Get-Item $c).Length -gt 0)) {
                if (-not $reciente -or (Get-Item $c).LastWriteTime -gt (Get-Item $reciente).LastWriteTime) {
                    $reciente = $c
                }
            }
        }
    }

    Write-Host '=============================================================='
    Write-Host "  Simulacion   : $Nombre ($entrada)"
    Write-Host "  Imagen       : $imagen"
    Write-Host "  Procesos     : $procesos"
    Write-Host "  Respaldo     : cada $pasos pasos (una vuelta del tornillo)"

    if ($reciente) {
        Write-Host "  Modo         : REANUDAR desde $(Split-Path $reciente -Leaf)"
        Write-Host '=============================================================='
        New-InputReanudacion -Origen $archivo.FullName -Destino (Join-Path $dirRun $entrada) `
            -ArchivoRestart (Split-Path $reciente -Leaf) -Pasos $pasos
        (Get-Content (Join-Path $dirRun $entrada)) `
            -replace '^processors.*', "processors $procesos 1 1" |
            Set-Content (Join-Path $dirRun $entrada) -Encoding ASCII
        $csv = Join-Path $dirRun 'massflow.csv'
        if (Test-Path $csv) {
            Copy-Item $csv (Join-Path $dirRun "massflow.$(Get-Date -Format 'yyyyMMddHHmmss').csv")
        }
    } else {
        Write-Host '  Modo         : INICIO desde cero'
        Write-Host '=============================================================='
        if (Test-Path $dirRun) { Remove-Item $dirRun -Recurse -Force }
        New-Item -ItemType Directory -Path (Join-Path $dirRun 'post') -Force | Out-Null
        Copy-Item -Path (Join-Path $ruta '*') -Destination $dirRun -Recurse -Force
        $rutaEntrada = Join-Path $dirRun $entrada
        $texto = (Get-Content $rutaEntrada) -replace '^processors.*', "processors $procesos 1 1"
        $texto = $texto | ForEach-Object {
            if ($_ -match '^\s*run\s+\$\{dischargesteps\}') {
                "restart $pasos restart.continuar.a restart.continuar.b"
                $_
            } else { $_ }
        }
        Set-Content -Path $rutaEntrada -Value $texto -Encoding ASCII
    }

    Write-Host "  Inicio: $(Get-Date -Format 'HH:mm:ss dd-MM-yyyy')"

    # Docker Desktop acepta rutas Windows con el formato de montaje estandar.
    docker run --rm `
        -v "${dirRun}:/simulaciones" `
        $imagen `
        mpirun -np $procesos --allow-run-as-root --bind-to none --oversubscribe `
        lmp380 -in "/simulaciones/$entrada" -log /simulaciones/log_sim.txt
    $resultado = $LASTEXITCODE

    $destino = Join-Path $ruta 'resultados'
    New-Item -ItemType Directory -Path $destino -Force | Out-Null
    if (Test-Path (Join-Path $dirRun 'post')) {
        Copy-Item (Join-Path $dirRun 'post') $destino -Recurse -Force -ErrorAction SilentlyContinue
    }
    Get-ChildItem $dirRun -Filter '*.csv' -ErrorAction SilentlyContinue |
        Copy-Item -Destination $destino -Force -ErrorAction SilentlyContinue
    Get-ChildItem $dirRun -Filter 'rt_*.txt' -ErrorAction SilentlyContinue |
        Copy-Item -Destination $destino -Force -ErrorAction SilentlyContinue
    Copy-Item (Join-Path $dirRun 'log_sim.txt') $destino -Force -ErrorAction SilentlyContinue

    Write-Host "  Fin: $(Get-Date -Format 'HH:mm:ss dd-MM-yyyy')"
    if ($resultado -eq 0) {
        New-Item -ItemType File -Path (Join-Path $destino 'COMPLETADO') -Force | Out-Null
        Write-Host "  Estado: COMPLETADA. Resultados en $destino"
    } else {
        Write-Host "  Estado: interrumpida. Para reanudar, ejecute de nuevo: .\correr.ps1 $Nombre"
    }
    return $resultado
}

#------------------------------------------------------------------------------
# Invoke-Todas
#   Ejecuta todas las simulaciones pendientes, omitiendo las completadas.
#------------------------------------------------------------------------------
function Invoke-Todas {
    param([int]$Forzado, [string]$Ver)
    $nombres = Get-Simulaciones
    $total = $nombres.Count
    $indice = 0
    foreach ($nombre in $nombres) {
        $indice++
        $marca = Join-Path $DirRepo "$nombre\resultados\COMPLETADO"
        if (Test-Path $marca) {
            Write-Host ">> [$indice/$total] ${nombre}: ya completada, se omite."
            continue
        }
        Write-Host ''
        Write-Host ">> [$indice/$total] Ejecutando $nombre ..."
        Invoke-Simulacion -Nombre $nombre -Forzado $Forzado -Ver $Ver -Reinicio $false
    }
    Write-Host ''
    Write-Host 'Proceso finalizado: todas las simulaciones pendientes fueron atendidas.'
}

#------------------------------------------------------------------------------
# Punto de entrada
#------------------------------------------------------------------------------
if ($Ayuda)  { Mostrar-Ayuda;  exit 0 }
if ($Listar) { Mostrar-Listado; exit 0 }
if ($Estado) { Mostrar-Estado;  exit 0 }
if ($Todas)  { Invoke-Todas -Forzado $Nucleos -Ver $Version; exit 0 }

if (-not $Simulacion) {
    Write-Error "Debe indicar el nombre de una simulacion. Ejemplo: .\correr.ps1 MASVEL2MENCOFAZURE"
    Write-Host  "Use '.\correr.ps1 -Ayuda' para mas informacion."
    exit 1
}

$codigo = Invoke-Simulacion -Nombre $Simulacion -Forzado $Nucleos -Ver $Version -Reinicio $Reiniciar.IsPresent
exit $codigo
