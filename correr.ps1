<#
.SYNOPSIS
    correr.ps1 - Ejecutor de simulaciones LIGGGHTS con respaldo automatico y
    notificaciones por WhatsApp (Windows).

.DESCRIPTION
    Ejecuta una simulacion LIGGGHTS del repositorio de la tesis usando Docker
    Desktop. Opera sobre el repositorio en el que se encuentra la usuaria
    (detectado automaticamente), respetando la rama activa: al cambiar de rama,
    las simulaciones disponibles cambian solas. Guarda puntos de control para
    reanudar tras interrupciones y, de forma opcional, envia avisos por WhatsApp.

    Ubicaciones (solo dos conceptos):
      1. El repositorio: la carpeta clonada (cualquier nombre/ubicacion). Fuente
         de los archivos de entrada; no se modifica.
      2. La carpeta de trabajo: %USERPROFILE%\liggghts-trabajo\<simulacion>\ ,
         creada automaticamente; contiene la copia de trabajo, los puntos de
         control y los resultados. Vive fuera del repositorio.

.PARAMETER Simulacion
    Nombre de la carpeta de la simulacion dentro del repositorio.
.PARAMETER Nucleos
    Numero de procesos. Si se omite, se calcula segun CPU y memoria.
.PARAMETER Version
    Version del contenedor: v1 o v2. Predeterminado: v2.
.PARAMETER Avisos
    Porcentaje de avance entre cada aviso de WhatsApp. Predeterminado: 10.
.PARAMETER SinWhatsapp
    Desactiva los avisos de WhatsApp para esta ejecucion.
.PARAMETER Reiniciar
    Fuerza el inicio desde cero, descartando cualquier punto de control.
.PARAMETER Listar
    Muestra las simulaciones de la rama actual y termina.
.PARAMETER Estado
    Muestra el avance de las simulaciones y termina.
.PARAMETER Todas
    Ejecuta en orden todas las simulaciones pendientes.
.PARAMETER ProbarWhatsapp
    Envia un mensaje de prueba por WhatsApp y termina.
.PARAMETER Ayuda
    Muestra la ayuda y termina.

.EXAMPLE
    .\correr.ps1 MASVEL2MENCOFAZURE
.EXAMPLE
    .\correr.ps1 MASVEL2MENCOFAZURE -Nucleos 4 -Version v2 -Avisos 25

.NOTES
    Requiere Docker Desktop en ejecucion y git. Ejecute el comando desde dentro
    de la carpeta del repositorio.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Simulacion,
    [Alias('n')][int]$Nucleos = 0,
    [Alias('v')][ValidateSet('v1', 'v2')][string]$Version = 'v2',
    [Alias('a')][ValidateRange(1, 100)][int]$Avisos = 10,
    [switch]$SinWhatsapp,
    [Alias('r')][switch]$Reiniciar,
    [Alias('l')][switch]$Listar,
    [Alias('e')][switch]$Estado,
    [Alias('t')][switch]$Todas,
    [Alias('p')][switch]$ProbarWhatsapp,
    [Alias('h')][switch]$Ayuda
)

#------------------------------------------------------------------------------
# Parametros de configuracion del entorno
#------------------------------------------------------------------------------
$DirTrabajo = Join-Path $env:USERPROFILE 'liggghts-trabajo'
$GbPorProceso = 5
$ImagenV1 = 'cesarsant2000/liggghts-motor'
$ImagenV2 = 'cesarsant2000/liggghts-motor-v2'
$PasosRespaldoPorDefecto = 1000000
$ArchivoConfigWhatsapp = Join-Path $env:USERPROFILE '.liggghts_whatsapp.conf'
$UrlWhatsapp = 'https://api.callmebot.com/whatsapp.php'
$SegundosEntreRevisiones = 60

# La raiz del repositorio se determina en tiempo de ejecucion.
$DirRepo = $null

#------------------------------------------------------------------------------
# Get-RepoActual
#   Devuelve la raiz del repositorio Git que contiene el directorio actual,
#   o $null si no se esta dentro de un repositorio.
#------------------------------------------------------------------------------
function Get-RepoActual {
    $raiz = (git rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -eq 0 -and $raiz) { return $raiz.Trim() }
    return $null
}

#------------------------------------------------------------------------------
# Get-RamaActual
#------------------------------------------------------------------------------
function Get-RamaActual {
    $r = (git -C $DirRepo rev-parse --abbrev-ref HEAD 2>$null)
    if ($r) { return $r.Trim() } else { return '(desconocida)' }
}

#------------------------------------------------------------------------------
# Get-ConfigWhatsapp
#------------------------------------------------------------------------------
function Get-ConfigWhatsapp {
    $config = @{ Phone = ''; ApiKey = '' }
    if (Test-Path $ArchivoConfigWhatsapp) {
        foreach ($linea in Get-Content $ArchivoConfigWhatsapp) {
            if ($linea -match '^\s*WHATSAPP_PHONE\s*=\s*(.+)\s*$')  { $config.Phone  = $Matches[1].Trim() }
            if ($linea -match '^\s*WHATSAPP_APIKEY\s*=\s*(.+)\s*$') { $config.ApiKey = $Matches[1].Trim() }
        }
    }
    return $config
}

#------------------------------------------------------------------------------
# Send-Whatsapp
#------------------------------------------------------------------------------
function Send-Whatsapp {
    param([string]$Mensaje)
    $cfg = Get-ConfigWhatsapp
    if (-not $cfg.Phone -or -not $cfg.ApiKey) { return }
    try {
        $params = @{ phone = $cfg.Phone; text = $Mensaje; apikey = $cfg.ApiKey }
        Invoke-RestMethod -Uri $UrlWhatsapp -Method Get -Body $params -TimeoutSec 15 -ErrorAction SilentlyContinue | Out-Null
    } catch { }
}

#------------------------------------------------------------------------------
# Mostrar-Ayuda
#------------------------------------------------------------------------------
function Mostrar-Ayuda {
    @'
==============================================================================
  correr.ps1 - Ejecutor de simulaciones LIGGGHTS (Windows)
==============================================================================

QUE HACE
  Corre una simulacion del repositorio de la tesis usando Docker Desktop.
  Trabaja sobre el repositorio donde usted se encuentre y respeta la rama
  activa: al cambiar de rama, las simulaciones disponibles cambian solas.
  Guarda puntos de control para reanudar y envia avisos por WhatsApp.

IMPORTANTE
  Ejecute el comando desde dentro de la carpeta del repositorio.

FORMA DE USO
  .\correr.ps1 <simulacion> [opciones]

EJEMPLOS
  .\correr.ps1 MASVEL2MENCOFAZURE
  .\correr.ps1 MASVEL2MENCOFAZURE -Nucleos 4
  .\correr.ps1 MASVEL2MENCOFAZURE -Version v1
  .\correr.ps1 MASVEL2MENCOFAZURE -Avisos 25
  .\correr.ps1 MASVEL2MENCOFAZURE -Reiniciar

OPCIONES
  -Nucleos N      Numero de procesos (automatico si se omite).
  -Version V      Version del contenedor: v1 o v2. Predeterminado: v2.
  -Avisos P       Aviso de WhatsApp cada P por ciento (def. 10).
  -SinWhatsapp    Desactiva los avisos de WhatsApp para esta ejecucion.
  -Reiniciar      Fuerza el inicio desde cero (descarta el respaldo).
  -Listar         Muestra las simulaciones de la rama actual y termina.
  -Estado         Muestra el avance de las simulaciones y termina.
  -Todas          Ejecuta en orden todas las simulaciones pendientes.
  -ProbarWhatsapp Envia un mensaje de prueba por WhatsApp y termina.
  -Ayuda          Muestra esta ayuda y termina.

SI SE INTERRUMPE
  Vuelva a ejecutar el mismo comando: se reanuda desde el ultimo punto de
  control automaticamente.

DONDE QUEDAN LOS RESULTADOS
  %USERPROFILE%\liggghts-trabajo\<simulacion>\

==============================================================================
'@ | Write-Host
}

#------------------------------------------------------------------------------
# Test-Docker
#------------------------------------------------------------------------------
function Test-Docker {
    try { docker ps *> $null; return ($LASTEXITCODE -eq 0) } catch { return $false }
}

#------------------------------------------------------------------------------
# Get-Procesos
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
#------------------------------------------------------------------------------
function Get-RutaSimulacion {
    param([string]$Nombre)
    $dir = Get-ChildItem -Path $DirRepo -Directory -Recurse -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -eq $Nombre } | Select-Object -First 1
    if ($dir) { return $dir.FullName } else { return $null }
}

#------------------------------------------------------------------------------
# Get-Simulaciones
#------------------------------------------------------------------------------
function Get-Simulaciones {
    Get-ChildItem -Path $DirRepo -Recurse -Filter 'in.*' -File -ErrorAction SilentlyContinue |
        ForEach-Object { $_.Directory.Name } | Sort-Object -Unique
}

#------------------------------------------------------------------------------
# Get-PasoActual
#------------------------------------------------------------------------------
function Get-PasoActual {
    param([string]$Log)
    if (-not (Test-Path $Log)) { return 0 }
    $ultimo = 0
    foreach ($linea in Get-Content $Log) {
        if ($linea -match '^\s*(\d+)\s') { $ultimo = [int64]$Matches[1] }
    }
    return $ultimo
}

#------------------------------------------------------------------------------
# Mostrar-Listado
#------------------------------------------------------------------------------
function Mostrar-Listado {
    Write-Host "Repositorio: $DirRepo"
    Write-Host "Rama activa: $(Get-RamaActual)"
    Write-Host 'Simulaciones disponibles en esta rama:'
    $sims = Get-Simulaciones
    if ($sims) { foreach ($s in $sims) { Write-Host "  - $s" } }
    else { Write-Host '  (ninguna en esta rama)' }
}

#------------------------------------------------------------------------------
# Mostrar-Estado
#------------------------------------------------------------------------------
function Mostrar-Estado {
    Write-Host "Estado de las simulaciones (carpeta de trabajo $DirTrabajo):"
    if (-not (Test-Path $DirTrabajo)) { Write-Host '  (todavia no se ha ejecutado ninguna)'; return }
    foreach ($dir in Get-ChildItem -Path $DirTrabajo -Directory) {
        $log = Join-Path $dir.FullName 'log_sim.txt'
        $paso = Get-PasoActual -Log $log
        $estado = 'en progreso'
        if (Test-Path (Join-Path $dir.FullName 'COMPLETADO')) { $estado = 'COMPLETADA' }
        '{0,-30} paso: {1,-12} estado: {2}' -f $dir.Name, $paso, $estado | Write-Host
    }
}

#------------------------------------------------------------------------------
# Get-PasosPorVuelta
#------------------------------------------------------------------------------
function Get-PasosPorVuelta {
    param([string]$Archivo)
    $contenido = Get-Content -Path $Archivo
    $dt = ($contenido | Select-String -Pattern 'variable\s+dt\s+equal\s+(\S+)' | Select-Object -First 1).Matches.Groups[1].Value
    $periodo = ($contenido | Select-String -Pattern 'variable\s+screwPeriod\s+equal\s+(\S+)' | Select-Object -First 1).Matches.Groups[1].Value
    if ($dt -and $periodo) {
        try { $pasos = [int]([double]$periodo / [double]$dt); if ($pasos -ge 1) { return $pasos } } catch { }
    }
    return $PasosRespaldoPorDefecto
}

#------------------------------------------------------------------------------
# Get-PasosTotales
#------------------------------------------------------------------------------
function Get-PasosTotales {
    param([string]$Archivo)
    $contenido = Get-Content -Path $Archivo
    $ft = ($contenido | Select-String -Pattern 'variable\s+filltime\s+equal\s+(\S+)' | Select-Object -First 1).Matches.Groups[1].Value
    $dt2 = ($contenido | Select-String -Pattern 'variable\s+dischargetime\s+equal\s+(\S+)' | Select-Object -First 1).Matches.Groups[1].Value
    $dt = ($contenido | Select-String -Pattern 'variable\s+dt\s+equal\s+(\S+)' | Select-Object -First 1).Matches.Groups[1].Value
    if ($ft -and $dt2 -and $dt) {
        try { return [int64](([double]$ft + [double]$dt2) / [double]$dt) } catch { return 0 }
    }
    return 0
}

#------------------------------------------------------------------------------
# New-InputReanudacion
#------------------------------------------------------------------------------
function New-InputReanudacion {
    param([string]$Origen, [string]$Destino, [string]$ArchivoRestart, [int]$Pasos)
    $salida = New-Object System.Collections.Generic.List[string]
    $continuacion = $false
    foreach ($linea in Get-Content -Path $Origen) {
        if ($continuacion) {
            $salida.Add("# [reanudacion] $linea")
            $continuacion = $linea -match '&\s*$'
            continue
        }
        if ($linea -match '^\s*create_box') { $salida.Add("read_restart $ArchivoRestart"); continue }
        if ($linea -match 'particletemplate|particledistribution|mesh/surface/planar|insert/stream') {
            $salida.Add("# [reanudacion] $linea")
            if ($linea -match '&\s*$') { $continuacion = $true }
            continue
        }
        if ($linea -match '^\s*unfix\s+ins\s*$') { $salida.Add("# [reanudacion] $linea"); continue }
        if ($linea -match '^\s*run\s+\$\{fillsteps\}') { $salida.Add("# [reanudacion] $linea"); continue }
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
# Start-MonitorProgreso
#------------------------------------------------------------------------------
function Start-MonitorProgreso {
    param([string]$Log, [int64]$Total, [string]$Nombre, [int]$Intervalo,
          [string]$Url, [string]$Phone, [string]$ApiKey, [int]$Segundos)
    if ($Total -lt 1 -or -not $Phone -or -not $ApiKey) { return $null }
    return Start-Job -ScriptBlock {
        param($Log, $Total, $Nombre, $Intervalo, $Url, $Phone, $ApiKey, $Segundos)
        $ultimoHito = 0
        while ($true) {
            Start-Sleep -Seconds $Segundos
            if (-not (Test-Path $Log)) { continue }
            $paso = 0
            foreach ($linea in Get-Content $Log) {
                if ($linea -match '^\s*(\d+)\s') { $paso = [int64]$Matches[1] }
            }
            if ($paso -le 0) { continue }
            $pct = [int]($paso * 100 / $Total)
            if ($pct -ge ($ultimoHito + $Intervalo)) {
                $ultimoHito = [int]([math]::Floor($pct / $Intervalo) * $Intervalo)
                try {
                    $cuerpo = @{ phone = $Phone; text = "Simulacion *$Nombre*: $pct% completado (paso $paso de $Total)."; apikey = $ApiKey }
                    Invoke-RestMethod -Uri $Url -Method Get -Body $cuerpo -TimeoutSec 15 -ErrorAction SilentlyContinue | Out-Null
                } catch { }
            }
        }
    } -ArgumentList $Log, $Total, $Nombre, $Intervalo, $Url, $Phone, $ApiKey, $Segundos
}

#------------------------------------------------------------------------------
# Get-DiagnosticoError
#------------------------------------------------------------------------------
function Get-DiagnosticoError {
    param([string]$Log, [int]$Codigo)
    $cola = ''
    if (Test-Path $Log) { $cola = (Get-Content $Log -Tail 40) -join "`n" }
    if ($Codigo -eq 137 -or $cola -match '(?i)signal 9|killed|out of memory|cannot allocate') {
        return 'Falta de memoria (RAM). Sugerencia: reducir el numero de procesos con -Nucleos.'
    }
    $lineaError = ($cola -split "`n" | Select-String -Pattern '(?i)ERROR' | Select-Object -Last 1)
    if ($lineaError) {
        $texto = $lineaError.ToString()
        if ($texto -match '(?i)lost atoms|particles? lost') {
            return 'Se perdieron particulas (posible inestabilidad numerica o dt muy grande).'
        } elseif ($texto -match '(?i)bond atoms missing|neighbor list overflow') {
            return 'Desbordamiento de la lista de vecinos o particulas fuera del dominio.'
        } else {
            $corto = if ($texto.Length -gt 120) { $texto.Substring(0, 120) } else { $texto }
            return "Error de LIGGGHTS: $corto"
        }
    }
    if ($Codigo -eq 130) { return 'Detenida manualmente (Ctrl+C).' }
    return "Causa no identificada (codigo $Codigo). Revise log_sim.txt para mas detalle."
}

#------------------------------------------------------------------------------
# Invoke-Simulacion
#------------------------------------------------------------------------------
function Invoke-Simulacion {
    param([string]$Nombre, [int]$Forzado, [string]$Ver,
          [bool]$Reinicio, [int]$AvisosPct, [bool]$UsarWhatsapp)

    if (-not (Test-Docker)) {
        Write-Error 'Docker Desktop no esta disponible o no esta en ejecucion. Abralo y reintente.'
        return 1
    }
    $imagen = if ($Ver -eq 'v1') { $ImagenV1 } else { $ImagenV2 }
    $ruta = Get-RutaSimulacion -Nombre $Nombre
    if (-not $ruta) {
        Write-Error "No existe la simulacion '$Nombre' en la rama actual ($(Get-RamaActual)). Use -Listar."
        return 1
    }
    $archivo = Get-ChildItem -Path $ruta -Filter 'in.*' -File | Select-Object -First 1
    if (-not $archivo) { Write-Error "La carpeta '$Nombre' no contiene un archivo de entrada in.*"; return 1 }
    $entrada = $archivo.Name

    $procesos = Get-Procesos -Forzado $Forzado
    $pasos = Get-PasosPorVuelta -Archivo $archivo.FullName
    $total = Get-PasosTotales -Archivo $archivo.FullName
    $cfg = Get-ConfigWhatsapp
    $whatsappActivo = $UsarWhatsapp -and $cfg.Phone -and $cfg.ApiKey

    $dirRun = Join-Path $DirTrabajo $Nombre
    $restartA = Join-Path $dirRun 'restart.continuar.a'
    $restartB = Join-Path $dirRun 'restart.continuar.b'

    $reciente = $null
    if (-not $Reinicio) {
        foreach ($c in @($restartA, $restartB)) {
            if ((Test-Path $c) -and ((Get-Item $c).Length -gt 0)) {
                if (-not $reciente -or (Get-Item $c).LastWriteTime -gt (Get-Item $reciente).LastWriteTime) { $reciente = $c }
            }
        }
    }

    Write-Host '=============================================================='
    Write-Host "  Simulacion   : $Nombre ($entrada)"
    Write-Host "  Repositorio  : $DirRepo  [rama: $(Get-RamaActual)]"
    Write-Host "  Imagen       : $imagen"
    Write-Host "  Procesos     : $procesos"
    Write-Host "  Respaldo     : cada $pasos pasos (una vuelta del tornillo)"
    Write-Host "  Pasos totales: $total"
    if ($whatsappActivo) { Write-Host "  WhatsApp     : avisos cada $AvisosPct%" } else { Write-Host "  WhatsApp     : desactivado" }

    if ($reciente) {
        Write-Host "  Modo         : REANUDAR desde $(Split-Path $reciente -Leaf)"
        Write-Host '=============================================================='
        New-InputReanudacion -Origen $archivo.FullName -Destino (Join-Path $dirRun $entrada) `
            -ArchivoRestart (Split-Path $reciente -Leaf) -Pasos $pasos
        (Get-Content (Join-Path $dirRun $entrada)) -replace '^processors.*', "processors $procesos 1 1" |
            Set-Content (Join-Path $dirRun $entrada) -Encoding ASCII
        $csv = Join-Path $dirRun 'massflow.csv'
        if (Test-Path $csv) { Copy-Item $csv (Join-Path $dirRun "massflow.$(Get-Date -Format 'yyyyMMddHHmmss').csv") }
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

    $monitor = $null
    if ($whatsappActivo -and $total -ge 1) {
        Send-Whatsapp -Mensaje "Simulacion *$Nombre* iniciada con $procesos procesos. Avisos cada $AvisosPct%."
        $monitor = Start-MonitorProgreso -Log (Join-Path $dirRun 'log_sim.txt') -Total $total `
            -Nombre $Nombre -Intervalo $AvisosPct -Url $UrlWhatsapp `
            -Phone $cfg.Phone -ApiKey $cfg.ApiKey -Segundos $SegundosEntreRevisiones
    }

    docker run --rm `
        -v "${dirRun}:/simulaciones" `
        $imagen `
        mpirun -np $procesos --allow-run-as-root --bind-to none --oversubscribe `
        lmp380 -in "/simulaciones/$entrada" -log /simulaciones/log_sim.txt
    $resultado = $LASTEXITCODE

    if ($monitor) {
        Stop-Job $monitor -ErrorAction SilentlyContinue
        Remove-Job $monitor -Force -ErrorAction SilentlyContinue
    }

    Write-Host "  Fin: $(Get-Date -Format 'HH:mm:ss dd-MM-yyyy')"
    if ($resultado -eq 0) {
        New-Item -ItemType File -Path (Join-Path $dirRun 'COMPLETADO') -Force | Out-Null
        Write-Host "  Estado: COMPLETADA. Resultados en $dirRun"
        if ($whatsappActivo) { Send-Whatsapp -Mensaje "Simulacion *$Nombre* COMPLETADA con exito. Resultados listos para descargar." }
    } else {
        $diagnostico = Get-DiagnosticoError -Log (Join-Path $dirRun 'log_sim.txt') -Codigo $resultado
        $hayRespaldo = ((Test-Path $restartA) -and ((Get-Item $restartA).Length -gt 0)) -or `
                       ((Test-Path $restartB) -and ((Get-Item $restartB).Length -gt 0))
        if ($hayRespaldo) {
            Write-Host "  Estado: detenida. Causa: $diagnostico"
            Write-Host "          Hay un punto de control; para reanudar: .\correr.ps1 $Nombre"
            if ($whatsappActivo) { Send-Whatsapp -Mensaje "Simulacion *$Nombre* se detuvo. Causa: $diagnostico Hay respaldo: para retomar, vuelva a ejecutarla." }
        } else {
            Write-Host "  Estado: ERROR antes del primer respaldo. Causa: $diagnostico"
            Write-Host "          Revise $dirRun\log_sim.txt"
            if ($whatsappActivo) { Send-Whatsapp -Mensaje "Simulacion *$Nombre* FALLO. Causa: $diagnostico No hay respaldo aun; revise la configuracion." }
        }
    }
    return $resultado
}

#------------------------------------------------------------------------------
# Invoke-Todas
#------------------------------------------------------------------------------
function Invoke-Todas {
    param([int]$Forzado, [string]$Ver, [int]$AvisosPct, [bool]$UsarWhatsapp)
    $nombres = Get-Simulaciones
    $total = $nombres.Count
    $indice = 0
    foreach ($nombre in $nombres) {
        $indice++
        if (Test-Path (Join-Path $DirTrabajo "$nombre\COMPLETADO")) {
            Write-Host ">> [$indice/$total] ${nombre}: ya completada, se omite."
            continue
        }
        Write-Host ''
        Write-Host ">> [$indice/$total] Ejecutando $nombre ..."
        Invoke-Simulacion -Nombre $nombre -Forzado $Forzado -Ver $Ver -Reinicio $false -AvisosPct $AvisosPct -UsarWhatsapp $UsarWhatsapp
    }
    Write-Host ''
    Write-Host 'Proceso finalizado: todas las simulaciones pendientes fueron atendidas.'
}

#------------------------------------------------------------------------------
# Test-Whatsapp
#------------------------------------------------------------------------------
function Test-Whatsapp {
    $cfg = Get-ConfigWhatsapp
    if (-not $cfg.Phone -or -not $cfg.ApiKey) {
        Write-Error "WhatsApp no esta configurado. Cree $ArchivoConfigWhatsapp con WHATSAPP_PHONE y WHATSAPP_APIKEY."
        return
    }
    Write-Host "Enviando mensaje de prueba a $($cfg.Phone)..."
    Send-Whatsapp -Mensaje "Mensaje de prueba: la configuracion de avisos LIGGGHTS funciona correctamente."
    Write-Host "Si no llega en un minuto, revise el numero y el apikey en $ArchivoConfigWhatsapp."
}

#------------------------------------------------------------------------------
# Punto de entrada
#------------------------------------------------------------------------------
if ($Ayuda) { Mostrar-Ayuda; exit 0 }

$DirRepo = Get-RepoActual
if (-not $DirRepo) {
    Write-Error "No se esta dentro de un repositorio Git. Entre a la carpeta del repositorio y reintente."
    exit 1
}

if ($Listar)         { Mostrar-Listado; exit 0 }
if ($Estado)         { Mostrar-Estado;  exit 0 }
if ($ProbarWhatsapp) { Test-Whatsapp;   exit 0 }

$usarWa = -not $SinWhatsapp.IsPresent

if ($Todas) {
    Invoke-Todas -Forzado $Nucleos -Ver $Version -AvisosPct $Avisos -UsarWhatsapp $usarWa
    exit 0
}

if (-not $Simulacion) {
    Write-Error "Debe indicar el nombre de una simulacion. Ejemplo: .\correr.ps1 MASVEL2MENCOFAZURE"
    Write-Host  "Use '.\correr.ps1 -Ayuda' para mas informacion."
    exit 1
}

$codigo = Invoke-Simulacion -Nombre $Simulacion -Forzado $Nucleos -Ver $Version `
    -Reinicio $Reiniciar.IsPresent -AvisosPct $Avisos -UsarWhatsapp $usarWa
exit $codigo
