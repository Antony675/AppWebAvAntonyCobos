# PoliMusic — Aplicación Web (ASP Clásico)

Clon funcional de Spotify desarrollado en **ASP Clásico (VBScript)**, HTML5, CSS3 y JavaScript vanilla,
con SQL Server como motor de base de datos.

---

## 1. Estructura del proyecto

```
polimusic/
├── global.asa                     Eventos de aplicación y sesión
├── web.config                     Configuración de IIS (ASP, MIME, seguridad)
├── login.asp                      Pantalla de autenticación
├── logout.asp                     Cierre de sesión
├── dashboard.asp                  Pantalla principal (reproductor + galerías)
│
├── _includes/                     Código del servidor (no accesible desde el navegador)
│   ├── config.asp                 URL base, cabeceras, contador de reproducciones
│   ├── conexion.asp               Conexión ADODB + helpers (Esc, H, Js, IIf, Sha1Hex)
│   ├── sesion.asp                 Control de sesión, roles y token anti-CSRF
│   ├── consultas.asp              Repositorio centralizado de consultas SQL
│   ├── iconos.asp                 Biblioteca de iconografía SVG en línea
│   ├── layout_superior.asp        Cabecera, sidebar y topbar reutilizables
│   └── layout_inferior.asp        Reproductor y cierre de documento
│
├── admin/                         Consola exclusiva del rol Administrador
│   ├── panel.asp                  Panel con pestañas RUD por entidad
│   └── procesar.asp               Procesador de operaciones (INSERT/UPDATE/DELETE)
│
├── css/
│   └── polimusic.css              Dark mode minimalista, transiciones y animaciones
│
├── js/
│   ├── polimusic.js               Motor del reproductor y navegación
│   └── admin.js                   Filtros y sincronización de modales
│
└── resources/                     Recursos multimedia locales
    ├── SongFiles/                 Archivos de audio (.mp3)
    ├── AlbumImages/               Carátulas de álbumes
    ├── ArtistImages/              Fotografías de artistas
    ├── PlaylistImages/            Portadas de playlists
    └── UserImages/                Avatares de usuario
```

---

## 2. Roles del sistema

| Rol | Usuario | Acceso |
|-----|---------|--------|
| **Administrador** | `userAdmin` | Panel de administración con operaciones **RUD** (Lectura, Actualización, Eliminación) sobre Usuarios, Canciones, Artistas, Álbumes, Playlists y Catálogos. Además, acceso completo al catálogo. |
| **Estándar** | `AntonyCobos` | Solo consumo: reproducir audio y navegar el catálogo visual. Ve playlists públicas y propias. |

> **Contraseña de ambas cuentas:** `12345678`
> El sistema soporta contraseñas en texto plano (datos semilla) y SHA-1 en mayúsculas.

---

## 3. Base de datos

**Script:** `BDD_PoliMusic.sql` (raíz del repositorio, codificación UTF-16 LE)

**Cadena de conexión** (definida en `_includes/conexion.asp`):

```
Provider=MSOLEDBSQL;Server=localhost,14333;Database=BDD_PoliMusic;User Id=usr_PoliMusic;Password=Politecnica1;Encrypt=true;TrustServerCertificate=true;
```

Si el proveedor `MSOLEDBSQL` no está instalado, la capa de datos **degrada automáticamente**
al proveedor legado `SQLOLEDB`.

### Tablas utilizadas

| Tabla | Propósito |
|-------|-----------|
| `TBL_USER` | Usuarios y roles (`USER_TYPE`: 0 = Estándar, 1 = Administrador) |
| `TBL_SONG` | Canciones, ruta del archivo y contador de reproducciones |
| `TBL_ALBUM` | Álbumes con año de publicación y carátula |
| `TBL_ARTIST` | Artistas |
| `TBL_PLAYLIST` | Playlists (`TYPE`: 0 = Pública, 1 = Privada) |
| `TBL_TRACKLIST` | Relación Álbum ↔ Canción |
| `TBL_PLAYER` | Relación Canción ↔ Artista |
| `TBL_PLAYLIST_SONG` | Relación Playlist ↔ Canción |
| `TBL_CATALOG` | Tabla paramétrica de tipos |

### Normalización de rutas

La base de datos almacena rutas en formato `~/songFiles/archivo.mp3`. La función
`ResolverRecurso()` las traduce a rutas web reales bajo `resources/`:

| Ruta en BD | Ruta resuelta |
|-----------|---------------|
| `~/songFiles/x.mp3` | `resources/SongFiles/x.mp3` |
| `~/userImages/x.png` | `resources/UserImages/x.png` |
| `~/albumImages/x.png` | `resources/AlbumImages/x.png` |
| `~/artistImages/x.jpg` | `resources/ArtistImages/x.jpg` |
| `~/playlistImages/x.png` | `resources/PlaylistImages/x.png` |

---

## 4. Características de la interfaz

- **Dark mode minimalista** con paleta `#08060c` / `#100c17` / acento morado satinado
  `#a855f7` (escala `#ede4ff` → `#c9a6fb` → `#a855f7` → `#7c3aed` → `#3b1d6e`) sobre grises
  y negros con matiz violeta.
- **Animaciones CSS3:** burbujas flotantes en el login, efecto de barrido en botones,
  elevación y zoom de carátulas en hover, barras ecualizadoras animadas, transiciones
  de vista, aparición de modales y toasts.
- **Reproductor completo:** play/pausa, anterior/siguiente, aleatorio (3 estados),
  repetición (off/todo/una), barra de progreso arrastrable, control de volumen con
  silenciamiento y visualizador de ecualizador.
- **Atajos de teclado:** `Espacio` play/pausa · `←`/`→` ±5 s · `↑`/`↓` volumen · `/` buscar.
- **Persistencia ligera** de volumen, aleatorio y repetición en `localStorage`.
- **Diseño responsivo** con puntos de quiebre en 1180, 980, 860 y 560 px.
- **Accesibilidad:** roles ARIA, `aria-live` en notificaciones y respeto a
  `prefers-reduced-motion`.

---

## 5. Despliegue en IIS

### Opción A — Script automatizado (recomendado)

Ejecutar **PowerShell como Administrador**:

```powershell
cd <ruta-del-proyecto>
.\deploy-iis.ps1
```

El script realiza automáticamente:
1. Verifica la instalación de IIS y del módulo ASP Clásico.
2. Copia la aplicación a `C:\inetpub\wwwroot\polimusic`.
3. Crea la aplicación IIS y el grupo de aplicaciones con identidad `ApplicationPoolIdentity`.
4. Habilita ASP Clásico y `enableParentPaths` (requerido por los `#include`).
5. Otorga permisos de lectura a `IIS_IUSRS` y escritura a `_logs`.
6. Configura el documento predeterminado y reinicia el sitio.

### Opción B — Despliegue manual

```powershell
# 1. Copiar archivos
Copy-Item -Path .\polimusic -Destination C:\inetpub\wwwroot\polimusic -Recurse -Force

# 2. Crear la aplicación IIS
Import-Module WebAdministration
New-WebApplication -Site "Default Web Site" -Name "polimusic" `
    -PhysicalPath "C:\inetpub\wwwroot\polimusic" -ApplicationPool "DefaultAppPool"

# 3. Permisos
icacls C:\inetpub\wwwroot\polimusic /grant "IIS_IUSRS:(OI)(CI)R" /T
icacls C:\inetpub\wwwroot\polimusic\_logs /grant "IIS_IUSRS:(OI)(CI)M" /T

# 4. Reiniciar
iisreset
```

### Opción C — Reparación rápida

Si la aplicación ya está publicada pero devuelve errores, existe un script de
reparación que corrige los problemas conocidos sin volver a desplegar todo:

```powershell
# PowerShell como Administrador, o doble clic en reparar-iis.cmd
.\reparar-iis.ps1
```

Antes de publicar nada, este script **valida la sintaxis VBScript** del código fuente
con `validar_asp.py` y **detiene el despliegue** si encuentra errores de compilación
(los que producen el `HTTP 500`). Después repara: `HTTP 501`, el error de formato de
`timeout` en `<session>` y los `hiddenSegments` duplicados.

### Validación estática de VBScript (sin IIS)

`validar_asp.py` detecta **antes de desplegar** los errores que IIS solo revela al
ejecutar la página:

```powershell
python validar_asp.py .
```

| Comprobación | Error de IIS que evita |
|--------------|------------------------|
| `Dim` duplicado en el ámbito global de una página ensamblada | `Name redefined` → HTTP 500 en **todas** las peticiones |
| Recordset usado con `.EOF` / `.Fields` sin guarda `RsValido()` | `800a01b6 El objeto no acepta esta propiedad o método: 'EOF'` |
| Identificador (`Dim`, parámetro o contador `For`) que ensombrece una función de VBScript | `800a000d No coinciden los tipos: 'rnd'` |
| `Option Explicit` fuera de la primera instrucción | `800a0400 Se esperaba una instrucción` |
| `global.asa` con `<% %>` en cualquier parte | `ASP 0137 Bloque Script global no válido` |
| Delimitadores `<% %>` y bloques `If/For/Do/Select/Sub` desbalanceados | `ASP 0116` / comportamientos erráticos |

Salida esperada cuando todo está correcto:

```
[OK] _includes\conexion.asp
...
[OK] Sin 'Dim' duplicados en el ambito global de las paginas ensambladas.

Resultado: 13 archivos analizados, SIN problemas detectados.
```

> **Nota sobre falsos positivos:** el validador analiza únicamente las regiones
> `<% ... %>` (SQL y JavaScript de cliente quedan excluidos), de modo que un
> `for (var i = 0; ...)` en JavaScript o un `For ... Next` repartido entre bloques
> ASP (`For` en un bloque y `<% Next %>` en otro) **no** se marcan como error.

### Opción D — Verificación y puesta en marcha final

Si el despliegue terminó pero no sabes en qué estado quedó, este script **no vuelve a
publicar nada**: valida la sintaxis del código fuente, comprueba archivos, ASP, permisos
y pool, aplica las directivas que falten, recicla el pool y prueba la URL clasificando el
resultado con instrucciones:

```powershell
# Doble clic en verificar-iis.cmd
.\verificar-iis.ps1
```

Interpretación de la salida:

| Código | Significado | Qué hacer |
|--------|-------------|-----------|
| **200** | La aplicación funciona | Abrir `http://localhost/polimusic/login.asp` |
| **500** | ASP ejecuta pero hay error de script | El propio script ya indica los errores de compilación detectados; revisar también la URL en el navegador |
| **501** | ASP sigue rechazando las inclusiones | Ejecutar `reparar-iis.cmd` |
| **0** | Sin respuesta | Revisar el servicio `W3SVC` |

### Solución de problemas conocidos

| Síntoma | Causa | Solución |
|---------|-------|----------|
| **`800a000d No coinciden los tipos: 'rnd'`** al iniciar sesión | Una variable **ensombrece una función incorporada de VBScript**. `Dim rnd` en `GenerarToken()` rompía `Int(Rnd() * n)`; `Dim hex` / `Dim asc` rompían `Hex()` / `Asc()` en `Sha1Hex()` | Renombrar la variable (`rnd` → `indice`, `hex` → `oTextoHex`, `asc` → `oAsc`). `validar_asp.py` detecta este patrón en `Dim`, parámetros de `Sub`/`Function` y contadores de `For` |
| **`800a01b6 El objeto no acepta esta propiedad o método: 'EOF'`** en `layout_superior.asp` / `dashboard.asp` | Se llama a `rs.EOF` sobre un Recordset **cerrado o inválido**. `If Not rs Is Nothing` **no basta**: un Recordset puede ser un objeto no-Nothing pero estar cerrado (por ejemplo si la consulta falló) | Usar siempre **`If RsValido(rs) Then`** antes de tocar `.EOF` / `.Fields`. `RsValido()` comprueba objeto + no `Nothing` + `State` abierto. `EjecutarConsulta()` además garantiza devolver un Recordset **abierto** o `Nothing`, nunca uno cerrado |
| **HTTP 500 en todas las páginas** por `Name redefined` | Una página declara con `Dim` una variable que **ya declaró un `#include`** (`strBase` estaba declarada en `layout_superior.asp` y **redeclarada** en `dashboard.asp` / `admin/panel.asp`). En VBScript un `Dim` duplicado en el mismo ámbito es **error fatal de compilación** | Ya corregido: las páginas **asignan** `strBase` sin volver a declararla. `validar_asp.py` comprueba esto en cada página ensamblada |
| **HTTP 501 "Error en nueva aplicación"** (página en blanco) | El `web.config` declara la sección `<asp>`, que está **bloqueada a nivel de servidor** (`overrideModeDefault="Deny"`). IIS rechaza el archivo completo y responde 501 a todas las peticiones | El `web.config` de este proyecto **no declara `<asp>`**. Ejecutar `reparar-iis.cmd`, que desbloquea la sección con `appcmd` |
| `ERROR: Atributo 'overrideModeDefault' desconocido` al desbloquear | `appcmd set config` no acepta `overrideModeDefault`; se confundía con el atributo XML homónimo | Sintaxis correcta: `appcmd unlock config /section:...` y luego `appcmd set config /section:... /overrideMode:Allow /commit:apphost` |
| Al ejecutar el despliegue aparece `Proporcione valores para los parámetros siguientes: Value:` | Se usó un cmdlet de IIS con un parámetro inexistente, y PowerShell entra en modo interactivo | Ya corregido: los scripts usan `appcmd`. Si reaparece, pulsar `Ctrl+C` |
| `El atributo 'timeout' no es válido. Timespan debe tener el formato [-][d.]hh:mm:ss[.ff]` | `<session timeout="30" />` usa un entero | Usar `timeout="00:30:00"` |
| `No se puede agregar una entrada de colección duplicada ... '_includes'` o `... 'bin'` | La colección `hiddenSegments` se declaraba **a la vez** en el `web.config` y en los cmdlets | El `web.config` es la única fuente de verdad; los scripts ya no la manipulan |
| **HTTP 500** en cualquier página | Error de script en VBScript | Abrir la URL en el navegador; `scriptErrorSentToBrowser="true"` muestra el detalle exacto |
| `ASP 0116 Falta delimitador de cierre de script` en `global.asa, línea 1` | El `global.asa` estaba envuelto en un bloque `<% ... %>`. **Un `global.asa` nunca lleva `<% %>`**: solo bloques `<script language="VBScript" runat="Server">` | Ya corregido. Si reaparece, verificar que la primera línea de `global.asa` **no** sea `<%` |
| `ASP 0137 Bloque Script global no válido` en `global.asa, línea N` | Hay un literal `<%` o `%>` **en cualquier parte** del archivo, **incluso dentro de un comentario `'`**. El parser lo detecta como directiva Script | El `global.asa` debe ser minimalista: solo el `<script>` con las 4 subrutinas, sin encabezados ni comentarios que mencionen `<%` |
| `unlock ... Sección de configuración desconocida: system.webServer/asp/session` | `unlock config` solo acepta **secciones completas**, no sub-elementos | Usar solo `system.webServer/asp` en `unlock`. Los sub-elementos (`session`, `limits`) sí valen en `set config` |
| Cambios en `global.asa` no surten efecto | El archivo solo se lee al **arrancar** la aplicación | Detener y arrancar el sitio (`Stop-Website` / `Start-Website`), no basta con reciclar el pool |
| No se puede copiar a `C:\inetpub\wwwroot` | Falta de privilegios | Ejecutar el script con UAC (`deploy-iis.cmd` / `reparar-iis.cmd`) |

> **Reglas de oro (IIS + ASP Clásico):**
> 1. La sección `<system.webServer/asp>` suele estar **bloqueada por defecto**. **Nunca la
>    declares en un `web.config` de aplicación**: configúrala con
>    `appcmd ... /commit:apphost` desde el script de despliegue.
> 2. Las páginas usan **`#include virtual`** (no `#include file`). `virtual` resuelve la
>    ruta desde la raíz de la aplicación y **no depende de `enableParentPaths`**, por lo
>    que la aplicación funciona aunque esa directiva esté bloqueada.
> 3. **`global.asa` debe ser minimalista.** Solo el bloque
>    `<script language="VBScript" runat="Server">` con las 4 subrutinas autorizadas
>    (`Application_OnStart`, `Application_OnEnd`, `Session_OnStart`, `Session_OnEnd`).
>    **Sin `<% %>` en ninguna parte** — ni siquiera dentro de un comentario `'`, porque el
>    parser lo detecta y lanza `ASP 0137`. Sin encabezados ni BOM. Un error aquí **tumba
>    toda la aplicación** (ASP lo compila antes que cualquier página), y tras editarlo hay
>    que **reiniciar el sitio**, no basta con reciclar el pool.
> 4. No dupliques colecciones (`hiddenSegments`, `defaultDocument/files`) entre el
>    `web.config` y los cmdlets.
> 5. **Un `#include` comparte el mismo ámbito que la página que lo incluye.** Si un
>    include declara `Dim strBase`, la página **no puede volver a declararla**: en
>    VBScript eso es `Name redefined`, un error **fatal de compilación** que devuelve
>    `HTTP 500` en todas las peticiones. Patrón correcto:
>    `If strBase = "" Then strBase = URL_BASE` (asignar, nunca redeclarar).
>    Ejecuta `python validar_asp.py .` para comprobarlo antes de desplegar.
> 6. **Nunca leas `.EOF` / `.Fields` sin una guarda `RsValido()`.** Un `Recordset`
>    puede ser un objeto no-`Nothing` **pero estar cerrado** (consulta fallida, cursor
>    liberado…). En ese caso `rs.EOF` lanza
>    `800a01b6 El objeto no acepta esta propiedad o método`. `If Not rs Is Nothing`
>    **no es suficiente**. Patrón correcto:
>    ```vb
>    If RsValido(rs) Then
>        Do While Not rs.EOF
>            ...
>        Loop
>        rs.Close
>        Set rs = Nothing
>    End If
>    ```
>    `EjecutarConsulta()` ya garantiza "Recordset abierto **o** `Nothing`", pero la
>    guarda `RsValido()` es la única comprobación segura en el punto de uso.
> 7. **Nunca uses el nombre de una función incorporada de VBScript como variable.**
>    `Dim rnd`, `Dim hex`, `Dim asc`, `Dim len`, `Dim date`… **ensombrecen** la
>    función homónima dentro de ese módulo, y la llamada (`Rnd()`, `Hex()`, `Asc()`)
>    pasa a leerse como la variable vacía:
>    `800a000d No coinciden los tipos: 'rnd'`. Aplica igual a **parámetros**
>    (`Sub X(ByVal len)`) y a **contadores** (`For date = ...`). Usa nombres
>    descriptivos (`indice`, `oTextoHex`, `oAsc`). `validar_asp.py` lo verifica.

### Requisitos previos de IIS

| Característica | Ruta en "Activar o desactivar características de Windows" |
|---------------|-----------------------------------------------------------|
| Servidor web (IIS) | Internet Information Services → Servidor web |
| ASP Clásico | Servidor web → Desarrollo de aplicaciones → **ASP** |
| Contenido estático | Servidor web → Características HTTP comunes → Contenido estático |
| Documento predeterminado | Servidor web → Características HTTP comunes → Documento predeterminado |

### URL de acceso

```
http://localhost/polimusic/login.asp
```

---

## 6. Solución de problemas

| Síntoma | Causa probable | Solución |
|---------|---------------|----------|
| Error HTTP 404.3 | ASP Clásico no está habilitado | Activar la característica "ASP" en Windows Features y ejecutar `iisreset` |
| Error HTTP 500.19 | Sección duplicada en `web.config` | Verificar que `asp` no esté bloqueada en la configuración raíz |
| Include no encontrado | `enableParentPaths` desactivado | El script de despliegue lo habilita; en manual: `appcmd set config /section:asp /enableParentPaths:true` |
| Página en blanco | Error de ASP silenciado | `web.config` ya define `scriptErrorSentToBrowser="true"`; revisar el Visor de eventos |
| No conecta a la base de datos | Contenedor SQL Server detenido o proveedor ausente | Verificar el puerto 14333 y `Provider=MSOLEDBSQL` |
| Audio no reproduce | Tipo MIME faltante | Ya declarado en `web.config` (`audio/mpeg`) |
| Imágenes no cargan | Carpetas de recursos vacías | Verificar que `resources/AlbumImages` y `ArtistImages` contengan archivos |

### Verificación de conectividad con la base de datos

```powershell
Test-NetConnection -ComputerName localhost -Port 14333
```

---

## 7. Seguridad implementada

- **Prevención de inyección SQL:** función `Esc()` aplicada a toda entrada de usuario,
  `EscInt()` para valores numéricos.
- **Prevención de XSS:** función `H()` (`Server.HTMLEncode`) en toda salida; `Js()` para
  valores embebidos en JavaScript.
- **Token anti-CSRF:** generado por sesión y validado en cada operación del panel.
- **Control de acceso por rol:** `RequerirSesion()` y `RequerirAdmin()` como guardas al
  inicio de cada página protegida.
- **Protección de código fuente:** `_includes` y `_logs` bloqueados como segmentos ocultos.
- **Cabeceras de seguridad:** `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`.
- **Regla de negocio:** un administrador no puede eliminar su propia cuenta ni usuarios
  con playlists asociadas.
- **Auditoría:** registro de accesos y operaciones administrativas en `_logs/accesos_*.log`.

---

## 8. Notas de alcance

Según los requerimientos, el panel administrativo implementa **RUD** (Lectura,
Actualización y Eliminación). La operación de **alta (Create)** no forma parte del
alcance solicitado y por ello no se expone en la interfaz.
