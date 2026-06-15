# Simulaciones LIGGGHTS — Guía de uso

Sistema para ejecutar las simulaciones de la tesis en Linux o Windows. Respeta
la rama de Git activa, tiene respaldo automático para reanudar tras
interrupciones y envía avisos de avance por WhatsApp.

## Concepto clave: solo dos ubicaciones

1. **El repositorio**: la carpeta donde está clonado el repo (cualquier nombre
   y ubicación). Contiene las herramientas y, según la rama, distintas carpetas
   de simulación. Es la fuente; el programa no la modifica.
2. **La carpeta de trabajo**: `~/liggghts-trabajo/<simulación>/` (Linux) o
   `%USERPROFILE%\liggghts-trabajo\<simulación>\` (Windows). Se crea sola y
   contiene la copia de trabajo, los puntos de control y los resultados. Vive
   fuera del repositorio para no interferir con el cambio de ramas.

No hay ninguna otra carpeta. No existe "repo-simulaciones".

## Archivos del sistema

| Archivo | Plataforma | Función |
|---|---|---|
| `correr` | Linux | Ejecutor de simulaciones |
| `configurar.sh` | Linux | Instalación del entorno (una vez) |
| `correr.ps1` | Windows | Ejecutor de simulaciones |
| `configurar.ps1` | Windows | Instalación del entorno (una vez) |
| `sincronizar-herramientas.sh` | Mantenimiento | Propaga las herramientas a todas las ramas |

---

## Comportamiento con ramas de Git

El comando detecta la raíz del repositorio desde donde se ejecuta y trabaja
sobre la **rama activa**. Al cambiar de rama con `git checkout`, las
simulaciones disponibles cambian solas: `correr --listar` siempre muestra las
de la rama actual.

En Linux, `correr` se instala en `~/bin`, por lo que es el mismo comando en
todas las ramas. En Windows se ejecuta directamente desde el repositorio
(`.\correr.ps1`), que también corresponde siempre a la rama activa.

### Mantener las herramientas iguales en todas las ramas
Git versiona los archivos por rama. Para que `correr` y `configurar` sean
idénticos en todas las ramas mientras las carpetas de simulación siguen siendo
distintas, edite las herramientas en una sola rama de referencia y propáguelas:

```
bash sincronizar-herramientas.sh main
```

Esto copia, ya confirmadas, las herramientas de `main` al resto de ramas, sin
tocar las carpetas de simulación propias de cada una.

---

## Uso en Linux

### Instalación (una sola vez)
Requiere que el administrador haya instalado Docker (o Podman), git y screen,
y añadido el usuario al grupo `docker`. Desde dentro del repositorio:
```
bash configurar.sh
source ~/.bashrc
```

### Ejecución (desde dentro del repositorio)
```
screen -S sim
correr MASVEL2MENCOFAZURE
```
Salir sin detener: `Ctrl+A` y luego `D`. Volver al avance: `screen -r sim`.

### Opciones
```
correr --ayuda                Guía completa
correr --listar               Simulaciones de la rama actual
correr --estado               Avance de las simulaciones
correr NOMBRE                 Ejecuta una simulación
correr NOMBRE --nucleos 4     Fuerza 4 procesos
correr NOMBRE --version v1    Usa el contenedor v1
correr NOMBRE --avisos 25     Aviso de WhatsApp cada 25%
correr NOMBRE --sin-whatsapp  Ejecuta sin avisos
correr NOMBRE --reiniciar     Empieza desde cero
correr --todas                Ejecuta todas las pendientes
correr --probar-whatsapp      Envía un mensaje de prueba
correr --actualizar           Reinstala el comando desde el repositorio actual
```

---

## Uso en Windows

### Instalación (una sola vez)
Requiere Docker Desktop en ejecución y git. Si PowerShell bloquea scripts:
```
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```
Desde dentro del repositorio:
```
.\configurar.ps1
```

### Ejecución (desde dentro del repositorio)
```
.\correr.ps1 MASVEL2MENCOFAZURE
```

### Opciones
```
.\correr.ps1 -Ayuda                Guía completa
.\correr.ps1 -Listar               Simulaciones de la rama actual
.\correr.ps1 -Estado               Avance de las simulaciones
.\correr.ps1 NOMBRE                 Ejecuta una simulación
.\correr.ps1 NOMBRE -Nucleos 4      Fuerza 4 procesos
.\correr.ps1 NOMBRE -Version v1     Usa el contenedor v1
.\correr.ps1 NOMBRE -Avisos 25      Aviso de WhatsApp cada 25%
.\correr.ps1 NOMBRE -SinWhatsapp    Ejecuta sin avisos
.\correr.ps1 NOMBRE -Reiniciar      Empieza desde cero
.\correr.ps1 -Todas                 Ejecuta todas las pendientes
.\correr.ps1 -ProbarWhatsapp        Envía un mensaje de prueba
```

---

## Avisos por WhatsApp (opcional)

Usa el servicio gratuito CallMeBot. Activación (una sola vez):
1. Abra la página de CallMeBot para "Free WhatsApp API" y vea el número de bot
   vigente (CallMeBot rota sus números y a veces el servicio está lleno).
2. Guarde ese número en sus contactos.
3. Envíele por WhatsApp: `I allow callmebot to send me messages`
4. Guarde el APIKEY recibido. El instalador lo pide, o créelo a mano:
   - Linux: `~/.liggghts_whatsapp.conf`
   - Windows: `%USERPROFILE%\.liggghts_whatsapp.conf`
   ```
   WHATSAPP_PHONE=+593XXXXXXXXX
   WHATSAPP_APIKEY=su_apikey
   ```
5. Compruebe con `correr --probar-whatsapp` o `.\correr.ps1 -ProbarWhatsapp`.

Recibirá avisos de inicio, avance (cada cierto %), finalización y, si algo
falla, la causa (memoria, partículas perdidas, etc.). Si CallMeBot no responde,
puede estar lleno: reintente más tarde. Las simulaciones corren igual sin avisos.

---

## Respaldo automático

Se guardan puntos de control alineados con cada vuelta completa del tornillo,
de modo que al reanudar no se introducen artefactos en la física. Si una
simulación se interrumpe, vuelva a ejecutar el mismo comando: se reanuda desde
el último punto de control. Como máximo se pierde una vuelta de tornillo.

---

## Resultados

Quedan en `~/liggghts-trabajo/<simulación>/` (Linux) o
`%USERPROFILE%\liggghts-trabajo\<simulación>\` (Windows): partículas (`post/`),
flujo másico (`massflow.csv`), tiempos de residencia (`rt_*.txt`) y el registro
(`log_sim.txt`).
