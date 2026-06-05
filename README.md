# Simulaciones LIGGGHTS — Guía de uso

Sistema para ejecutar las simulaciones de la tesis en Linux o Windows, con
respaldo automático para reanudar tras cualquier interrupción.

## Archivos del sistema

| Archivo | Plataforma | Función |
|---|---|---|
| `correr` | Linux | Ejecutor de simulaciones (comando principal) |
| `configurar.sh` | Linux | Instalación del entorno (una vez) |
| `correr.ps1` | Windows | Ejecutor de simulaciones (PowerShell) |
| `configurar.ps1` | Windows | Instalación del entorno (una vez) |

Los cuatro archivos deben estar subidos al repositorio.

---

## Uso en Linux

### Instalación (una sola vez)
Requiere que el administrador haya instalado Docker (o Podman), git y screen,
y haya añadido el usuario al grupo `docker`.

```
git clone https://github.com/Kelly-Ortiz/Tesis-Kelly-LIGGGHTS.git ~/repo
bash ~/repo/configurar.sh
source ~/.bashrc
```

### Ejecución
```
screen -S sim
correr MASVEL2MENCOFAZURE
```
Para salir sin detener la simulación: `Ctrl+A` y luego `D`.
Para volver a ver el avance: `screen -r sim`.

### Opciones disponibles
```
correr --ayuda                              Guía completa
correr --listar                             Lista las simulaciones
correr --estado                             Muestra el avance
correr NOMBRE                               Ejecuta una simulación
correr NOMBRE --nucleos 4                   Fuerza 4 procesos
correr NOMBRE --version v1                  Usa el contenedor v1
correr NOMBRE --reiniciar                   Empieza desde cero
correr --todas                              Ejecuta todas las pendientes
```

---

## Uso en Windows

### Instalación (una sola vez)
Requiere Docker Desktop instalado y en ejecución, y git para Windows.
Si PowerShell bloquea la ejecución de scripts, abra PowerShell una vez y ejecute:
```
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Luego, dentro de la carpeta del repositorio:
```
.\configurar.ps1
```

### Ejecución
```
.\correr.ps1 MASVEL2MENCOFAZURE
```

### Opciones disponibles
```
.\correr.ps1 -Ayuda                         Guía completa
.\correr.ps1 -Listar                        Lista las simulaciones
.\correr.ps1 -Estado                        Muestra el avance
.\correr.ps1 NOMBRE                          Ejecuta una simulación
.\correr.ps1 NOMBRE -Nucleos 4               Fuerza 4 procesos
.\correr.ps1 NOMBRE -Version v1              Usa el contenedor v1
.\correr.ps1 NOMBRE -Reiniciar               Empieza desde cero
.\correr.ps1 -Todas                          Ejecuta todas las pendientes
```

---

## Respaldo automático

Durante la simulación se guardan puntos de control alineados con cada vuelta
completa del tornillo, de modo que al reanudar el tornillo y las partículas
coinciden y no se introducen artefactos en la física.

Si la simulación se interrumpe por cualquier causa (reinicio del equipo, falta
de memoria o pausa manual), basta con **ejecutar de nuevo exactamente el mismo
comando**: el sistema detecta el último punto de control y reanuda la
simulación de forma automática. El programa indica en pantalla
`Modo: REANUDAR` cuando lo hace.

Como máximo se pierde una vuelta de tornillo de cálculo.

---

## Resultados

Los resultados de cada simulación quedan en:
```
<repositorio>/<simulación>/resultados/
```
Incluyen los archivos de partículas (`post/`), el flujo másico (`massflow.csv`),
los tiempos de residencia (`rt_*.txt`) y el registro de ejecución
(`log_sim.txt`).
