# Simulaciones LIGGGHTS — Guía de uso

Sistema para ejecutar las simulaciones de la tesis en Linux o Windows, con
respaldo automático para reanudar tras cualquier interrupción y avisos de
avance por WhatsApp.

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
Durante la instalación se ofrece configurar los avisos por WhatsApp.

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
correr NOMBRE --avisos 25                   Aviso de WhatsApp cada 25%
correr NOMBRE --sin-whatsapp                Ejecuta sin avisos
correr NOMBRE --reiniciar                   Empieza desde cero
correr --todas                              Ejecuta todas las pendientes
correr --probar-whatsapp                    Envía un mensaje de prueba
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
.\correr.ps1 NOMBRE -Avisos 25               Aviso de WhatsApp cada 25%
.\correr.ps1 NOMBRE -SinWhatsapp             Ejecuta sin avisos
.\correr.ps1 NOMBRE -Reiniciar               Empieza desde cero
.\correr.ps1 -Todas                          Ejecuta todas las pendientes
.\correr.ps1 -ProbarWhatsapp                 Envía un mensaje de prueba
```

---

## Avisos por WhatsApp (opcional)

El sistema puede enviar mensajes de WhatsApp al iniciar una simulación, cada
cierto porcentaje de avance, y al finalizar o interrumpirse. Usa el servicio
gratuito **CallMeBot** (uso personal).

### Activación (una sola vez)
1. Guarde en sus contactos el número **+34 611 08 28 80**.
2. Envíele por WhatsApp el mensaje exacto:
   `I allow callmebot to send me messages`
3. Recibirá una respuesta con su **APIKEY**.
4. El instalador (`configurar.sh` o `configurar.ps1`) le pedirá el número y el
   APIKEY y los guardará. También puede crear el archivo manualmente:
   - Linux: `~/.liggghts_whatsapp.conf`
   - Windows: `%USERPROFILE%\.liggghts_whatsapp.conf`

   Con dos líneas:
   ```
   WHATSAPP_PHONE=+593XXXXXXXXX
   WHATSAPP_APIKEY=su_apikey
   ```
5. Compruebe el envío:
   - Linux: `correr --probar-whatsapp`
   - Windows: `.\correr.ps1 -ProbarWhatsapp`

Las credenciales se guardan solo en el equipo (no en el repositorio).
Si no se configura, las simulaciones corren normalmente y sin avisos.

---

## Respaldo automático

Durante la simulación se guardan puntos de control alineados con cada vuelta
completa del tornillo, de modo que al reanudar el tornillo y las partículas
coinciden y no se introducen artefactos en la física.

Si la simulación se interrumpe por cualquier causa (reinicio del equipo, falta
de memoria o pausa manual), basta con **ejecutar de nuevo exactamente el mismo
comando**: el sistema detecta el último punto de control y reanuda la
simulación de forma automática. El programa indica en pantalla
`Modo: REANUDAR` cuando lo hace. Como máximo se pierde una vuelta de tornillo
de cálculo.

---

## Resultados

Los resultados de cada simulación quedan en:
```
<repositorio>/<simulación>/resultados/
```
Incluyen los archivos de partículas (`post/`), el flujo másico (`massflow.csv`),
los tiempos de residencia (`rt_*.txt`) y el registro de ejecución
(`log_sim.txt`).
