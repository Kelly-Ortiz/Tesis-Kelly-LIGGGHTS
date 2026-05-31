# Tesis-Kelly-LIGGGHTS
-----------------------------------------------------------------
# Guía Completa de Git, GitHub y GitHub Desktop: De Cero a Experto (Para Principiantes)

¡Bienvenido/a al mundo del control de versiones! Si no tienes ningún conocimiento previo sobre programación, comandos o servidores, no te preocupes. Esta guía fue diseñada específicamente para ti. Al terminar de leerla, entenderás qué son estas herramientas, cómo usarlas en tu día a día sin tocar una sola línea de código de terminal, y cómo solucionar los problemas más comunes.

---

## 1. Conceptos Básicos: ¿Qué es esto y para qué sirve?

Para entender Git y GitHub, usemos una analogía sencilla: **Imagining que estás escribiendo un libro o un reporte escolar.** Normalmente, guardarías archivos como:
* `proyecto_final.docx`
* `proyecto_final_version2.docx`
* `proyecto_final_este_si_es_el_bueno.docx`
* `proyecto_final_corregido_finalizado.docx`

Esto es un caos. Si trabajas con más personas, es imposible saber quién cambió qué. Git y GitHub resuelven esto de forma elegante.

### ¿Qué es Git?
**Git es una máquina del tiempo para tus proyectos.** Es un programa que se instala en tu computadora y se encarga de registrar, de forma invisible, cada pequeño cambio que haces en tus archivos. Si cometes un error o borras algo por accidente, Git te permite "viajar al pasado" y restaurar una versión anterior exacta.

### ¿Qué es GitHub?
**GitHub es como el Google Drive o Dropbox de los programadores, pero con superpoderes.** Es una plataforma web en la nube donde guardas las copias de tus "máquinas del tiempo" (tus proyectos con Git). Sirve para que tus archivos no se pierdan si se rompe tu computadora y para compartir tu trabajo con el mundo o con tu equipo de trabajo.

### ¿Qué es GitHub Desktop?
Git, originalmente, se controla escribiendo comandos de texto en una pantalla negra (la terminal). Como esto puede ser intimidante, GitHub creó **GitHub Desktop**: una aplicación visual (con botones, menús y ventanas de clics) que te permite usar toda la potencia de Git y GitHub sin escribir comandos pesados.

---

## 2. El Glosario Esencial (Términos que debes conocer)

Antes de empezar, debes familiarizarte con estas palabras. Son el "idioma" de Git:

* **Repositorio (o "Repo"):** Es la carpeta de tu proyecto. Es una carpeta normal, pero que Git está vigilando de cerca para registrar sus cambios. Puede estar en tu computadora (**Local**) o en internet (**Remoto**).
* **Commit (Confirmar cambios):** Es como tomar una "foto" o guardar una "partida" en un videojuego. Cuando haces un commit, le dices a Git: *"Guarda cómo está el proyecto en este preciso segundo con una nota explicativa"*.
* **Rama (Branch):** Imagina el tronco de un árbol. Esa es la versión principal de tu proyecto (usualmente llamada `main` o `master`). Si quieres probar una idea nueva sin arruinar el trabajo principal, creas una "rama" (un desvío). Si funciona, la unes al tronco; si no, la borras.
* **Clone (Clonar):** Descargar un repositorio que está en internet (GitHub) a tu computadora por primera vez, vinculándolo para que sigan conectados.
* **Push (Empujar/Subir):** Subir los "commits" (fotos/guardados) que hiciste en tu computadora a la nube de GitHub. Si no haces *Push*, nadie más verá tus cambios.
* **Pull (Jalar/Descargar):** Traer los cambios nuevos que están en GitHub a tu computadora. Sirve para actualizar tu proyecto con lo que hicieron tus compañeros.
* **Merge (Fusionar):** Unir dos ramas. Por ejemplo, unir tu rama de "ideas locas" con la rama principal porque tu idea funcionó perfectamente.
* **Pull Request (PR):** Una petición de revisión. Cuando trabajas en equipo, antes de unir tus cambios a la rama principal, creas un PR en GitHub para decirle a tus compañeros: *"Miren lo que hice, ¿lo revisan y me dan permiso de añadirlo al proyecto?"*.
* **Fork (Bifurcación):** Sacar una copia exacta de un repositorio de otra persona en tu propia cuenta de GitHub para experimentar libremente sin alterar el proyecto original.

---

## 3. Configuración Inicial (Paso a Paso)

Hagamos la configuración por única vez. No necesitas pagar nada, todo es gratis.

### Paso 1: Crear cuenta en GitHub
1. Entra a [github.com](https://github.com).
2. Haz clic en **Sign up** (Registrarse).
3. Introduce tu correo, crea una contraseña segura y elige un nombre de usuario (elige uno profesional, te servirá para tu portafolio en el futuro).
4. Verifica tu correo electrónico.

### Paso 2: Instalar GitHub Desktop
1. Entra a [desktop.github.com](https://desktop.github.com).
2. Descarga la versión correspondiente a tu sistema operativo (Windows o Mac).
3. Instala el programa como cualquier otra aplicación.

### Paso 3: Vincular la aplicación con tu cuenta
1. Abre **GitHub Desktop**.
2. Te pedirá iniciar sesión. Haz clic en **Sign in to GitHub.com**.
3. Se abrirá tu navegador web pidiendo autorización. Haz clic en **Authorize desktop** (Autorizar).
4. Configura tu nombre y correo (deben ser los mismos de tu cuenta de GitHub). Esto sirve para que cada vez que guardes algo, aparezca tu nombre como autor.

---

## 4. El Flujo de Trabajo Diario (Cómo trabajar sin errores)

Esta es la rutina que seguirás cada vez que uses estas herramientas. Es el "ABC" del desarrollo.

```
[ Tu Computadora ] --(Commit)--> [ Foto Guardada Local ] --(Push)--> [ Nube de GitHub ]
```

### Escenario A: Crear un proyecto desde cero
1. Abre GitHub Desktop.
2. Ve al menú **File** (Archivo) -> **New Repository** (Nuevo Repositorio).
3. Ponle un nombre (ej. `mi-primer-proyecto`), una descripción opcional y elige en qué carpeta de tu computadora se guardará.
4. Marca la casilla **Initialize this repository with a README** (esto crea un archivo de texto inicial, muy recomendado).
5. Haz clic en **Create Repository**.
6. ¡Listo! Ya existe en tu computadora. Ahora haz clic en el botón azul de arriba que dice **Publish repository** (Publicar repositorio) para subirlo a internet en tu cuenta de GitHub.

### Escenario B: Trabajar en un proyecto existente (Modificar archivos)
Una vez que el repositorio está creado y enlazado:

1. **Abrir los archivos:** En GitHub Desktop, verás un botón que dice **Show in Explorer** (o *Show in Finder* en Mac). Haz clic ahí. Se abrirá la carpeta de tu proyecto.
2. **Hacer cambios:** Abre cualquier archivo (un documento de texto, un código, una imagen), hazle cambios, escribe algo nuevo y dale a **Guardar** en el programa que uses (como bloc de notas, Word, VS Code, etc.). Cerciórate de guardar el archivo.
3. **Ver los cambios:** Regresa a GitHub Desktop. Verás que en la barra lateral izquierda aparece el archivo que modificaste con un cuadro verde (si agregaste cosas) o rojo (si borraste cosas). Te muestra exactamente qué cambió.
4. **Hacer el Commit (Guardar la foto):**
    * Abajo a la izquierda verás un campo obligatorio llamado **Summary** (Resumen). Escribe de forma breve qué hiciste (ej: `Corregido el título de la página principal`).
    * Opcional: En *Description*, detalla más tus cambios.
    * Haz clic en el botón azul **Commit to main**.
5. **Subir los cambios (Push):** Verás que arriba aparece un botón que dice **Push origin** (con una flecha hacia arriba). Haz clic ahí. ¡Tus cambios ahora están seguros en internet (GitHub)!

---

## 5. El uso de Ramas (Branches) y Trabajo en Equipo

Nunca trabajes directamente sobre la rama principal (`main`) si estás colaborando con más personas, porque podrías romper el trabajo de todos.

1. En la parte superior de GitHub Desktop, haz clic donde dice **Current Branch** (Rama actual, que por defecto es `main`).
2. Haz clic en **New Branch** (Nueva Rama).
3. Ponle un nombre descriptivo sin espacios (ej: `cambiar-colores-pantalla` o `agregar-boton-contacto`). Haz clic en **Create Branch**.
4. Haz tus cambios en los archivos, haz tus commits normalmente.
5. Haz clic en **Publish branch** para subir tu rama a GitHub.
6. **Crear Pull Request:** Cuando termines tu trabajo, GitHub Desktop te mostrará un botón mágico que dice **Create Pull Request**. Al pulsarlo, te llevará a la web de GitHub para que escribas un mensaje a tu equipo explicando tus cambios. Si ellos lo aprueban, tus cambios se fusionarán (*Merge*) con la rama principal `main`.

---

## 6. Errores Comunes y Cómo Solucionarlos

No te asustes. Todos los programadores del mundo, desde principiantes hasta expertos en la NASA, cometen estos errores. Aquí sabrás cómo salir del problema.

### Error 1: "Merge Conflicts" (Conflictos de fusión)
* **Por qué pasa:** Esto ocurre cuando tú y otra persona modificaron **la misma línea del mismo archivo** al mismo tiempo. Cuando intentas unir los cambios, Git se confunde y dice: *"No sé cuál versión es la correcta, elige tú"*.
* **Cómo se ve:** GitHub Desktop se pondrá de color de advertencia y te dirá que hay conflictos pendientes.
* **Solución fácil:**
    1. GitHub Desktop te sugerirá abrir el archivo conflictivo en tu editor de texto o te dará opciones.
    2. Al abrir el archivo verás marcas extrañas como `<<<<<<< HEAD`, `=======`, y `>>>>>>>`. 
    3. Lo que está entre `<<<<<<<` y `=======` es **tu cambio**. Lo que está entre `=======` y `>>>>>>>` es **el cambio de la otra persona**.
    4. Borra manualmente las marcas (`<<<<<<<`, `=======`, `>>>>>>>`) y deja únicamente el texto que de verdad deba quedarse (puedes dejar el tuyo, el de la otra persona, o combinarlos).
    5. Guarda el archivo, regresa a GitHub Desktop, verás que el conflicto desaparece. Haz clic en **Commit merge** y luego haz **Push**.

### Error 2: El botón de Push no funciona y pide hacer "Pull" primero
* **Por qué pasa:** Alguien de tu equipo subió cambios a GitHub mientras tú trabajabas en tu computadora. Tu computadora está "desactualizada" con respecto al servidor. Git te prohíbe subir cosas para evitar destruir el trabajo del otro.
* **Solución:** Muy fácil. Haz clic en el botón **Fetch origin** (o **Pull**) que aparece arriba a la derecha. Traerá los cambios de internet, los unirá con los tuyos automáticamente, y ahora sí te dejará presionar el botón **Push**.

### Error 3: Hiciste un Commit pero te diste cuenta de que te equivocaste en algo
* **Por qué pasa:** Escribiste mal el mensaje del commit, te faltó guardar un archivo, o rompiste algo justo antes de subirlo.
* **Solución (Si NO has hecho Push):** En GitHub Desktop, abajo a la izquierda (justo debajo de donde haces los commits), hay un botón maravilloso que dice **Undo** (Deshacer). Si lo presionas, el último commit se desarma, devolviendo tus archivos al estado de edición para que los corrijas.
* **Solución (Si YA hiciste Push):** Lo mejor para un principiante es simplemente hacer las correcciones necesarias en los archivos, guardar, y hacer un **nuevo commit** con un mensaje como `Corrección del error anterior`. No intentes borrar el historial si estás empezando.

### Error 4: "Authentication Failed" (Error de autenticación)
* **Por qué pasa:** Cambiaste tu contraseña de GitHub en la web, o los permisos de la aplicación en tu computadora caducaron.
* **Solución:** Ve en GitHub Desktop a *Options* (en Windows) o *Preferences* (en Mac) -> *Accounts*. Haz clic en **Sign out** (Cerrar sesión) y luego vuelve a hacer clic en **Sign in** para loguearte de nuevo a través del navegador.

---

## 7. Buenas Prácticas (Para parecer un profesional)

Si sigues estos consejos desde el primer día, tu aprendizaje será sumamente fluido:

1.  **Haz Pull todas las mañanas:** Antes de empezar a tocar un solo archivo, abre GitHub Desktop y dale al botón *Fetch/Pull*. Así te aseguras de trabajar sobre lo más nuevo que haya hecho tu equipo.
2.  **Haz Commits pequeños y seguidos:** No trabajes 5 días seguidos para hacer un solo commit gigante. Es mejor hacer 5 commits al día. Uno que diga `Creado el diseño del menú`, otro `Cambiado el color de fondo`, otro `Arreglado error de tipografía`. Si algo se rompe, será facilísimo regresar al punto exacto donde funcionaba.
3.  **Escribe mensajes de Commit claros:** Evita poner cosas como `asdasd`, `cambios`, o `arreglado`. Usa textos claros en presente: `Agregar formulario de registro`, `Eliminar imagen obsoleta`. Tu "yo del futuro" te lo agradecerá cuando busques algo de hace semanas.
4.  **No subas archivos basura:** No subas archivos personales, contraseñas escritas en bloc de notas, o archivos temporales de tu sistema operativo. (Para esto existe un archivo especial llamado `.gitignore`, que le dice a Git qué carpetas ignorar por completo).

¡Felicidades! Ya tienes todo el conocimiento teórico y práctico necesario para manejar proyectos en Git y GitHub usando GitHub Desktop. ¡A practicar!
