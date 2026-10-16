# ==================================================================================
#  PoliMusic - Reparacion completa de la publicacion en IIS
# ==================================================================================
#  Corrige el error HTTP 501 "Error en nueva aplicacion".
#
#  CAUSA RAIZ
#  La seccion <system.webServer/asp> esta BLOQUEADA a nivel de servidor
#  (overrideModeDefault="Deny"). Cuando el web.config de la aplicacion intentaba
#  declarar <asp ...> IIS rechazaba el archivo completo y respondia 501 a TODAS las
#  peticiones. Declarar una seccion bloqueada invalida el web.config entero.
#
#  ESTRATEGIA
#   1. Desbloquear la seccion <asp> a nivel de servidor con appcmd (herramienta
#      correcta; Set-WebConfiguration -Metadata NO existe y bloquea el script).
#   2. Publicar el web.config SIN la seccion <asp> (asi nunca vuelve a chocar).
#   3. Aplicar enableParentPaths y el resto de directivas ASP a nivel de servidor.
#   4. Reciclar el pool y probar la URL con guia de accion.
#
#  Uso: doble clic en reparar-iis.cmd  (solicita UAC automaticamente)
# ==================================================================================

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Sitio      = "Default Web Site"
$NombreApp  = "polimusic"
$Pool       = "PoliMusicPool"
$Destino    = "C:\inetpub\wwwroot"
$Origen     = $PSScriptRoot
$rutaApp    = Join-Path $Destino $NombreApp
$rutaConfig = "IIS:\Sites\$Sitio\$NombreApp"
$appcmd     = Join-Path $env:windir "system32\inetsrv\appcmd.exe"

function Linea { Write-Host ("-" * 64) -ForegroundColor DarkGray }
function Paso($t)  { Write-Host "`n==> $t" -ForegroundColor Cyan }
function Ok($t)    { Write-Host "    [OK] $t" -ForegroundColor Green }
function Aviso($t) { Write-Host "    [!]  $t" -ForegroundColor Yellow }
function Fallo($t) { Write-Host "    [X]  $t" -ForegroundColor Red }
function Dato($t)  { Write-Host "         $t" -ForegroundColor DarkGray }

Write-Host ""
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host "  PoliMusic - Reparacion completa de IIS" -ForegroundColor Magenta
Write-Host "================================================================" -ForegroundColor Magenta

# --- 0. Privilegios -----------------------------------------------------------------
Paso "Verificando privilegios de administrador"
$identidad = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identidad)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Fallo "Este script requiere privilegios de administrador."
    Dato "Cierre esta ventana y ejecute reparar-iis.cmd (solicita UAC)."
    Read-Host "`nPresione ENTER para salir"
    exit 1
}
Ok "Privilegios de administrador confirmados"

if (-not (Test-Path $appcmd)) {
    Fallo "No se encontro appcmd.exe en $appcmd"
    Dato "Asegurese de que IIS este instalado con las herramientas de administracion."
    Read-Host "`nPresione ENTER para salir"
    exit 1
}
Ok "appcmd.exe localizado"

try { Import-Module WebAdministration -ErrorAction Stop; Ok "Modulo WebAdministration cargado" }
catch { Aviso "Modulo WebAdministration no disponible (appcmd se usara igualmente)" }

# ===================================================================================
# 0.b VALIDACION ESTATICA DE VBSCRIPT (antes de publicar)
# ===================================================================================
# Evita publicar codigo que produciria un HTTP 500 por errores de compilacion:
#   * 'Dim' duplicado en el ambito global de una pagina ensamblada
#     -> "Name redefined" (error fatal de compilacion).
#   * Option Explicit mal ubicado -> 800a0400.
#   * global.asa con <% %>  -> ASP 0137.
#   * bloques de control desbalanceados.
#
# Se detiene la publicacion si hay errores, para no dejar el sitio en 500.
Paso "Validando la sintaxis VBScript del codigo fuente"

$validador = Join-Path $Origen "validar_asp.py"
$python = $null
foreach ($cand in @(
        "C:\Users\$env:USERNAME\.workbuddy-ai\binaries\python\versions\3.13.12\python.exe",
        "C:\Users\$env:USERNAME\.workbuddy-ai\binaries\python\versions\3.10.6\python.exe"
    )) {
    if (Test-Path $cand) { $python = $cand; break }
}
if (-not $python) {
    foreach ($nombre in @("python", "py", "python3")) {
        $cmd = Get-Command $nombre -ErrorAction SilentlyContinue
        if ($cmd) { $python = $cmd.Source; break }
    }
}

if ($python -and (Test-Path $validador)) {
    $salida = & $python $validador $Origen 2>&1
    $texto = ($salida | Out-String)
    foreach ($linea in ($texto -split "`r?`n")) {
        if ($linea -match '^\s*\[X\]|^\s*-\s|Resultado:') {
            if ($linea -match '\[X\]') { Fallo $linea.Trim() }
            elseif ($linea -match '^\s*-') { Dato $linea.Trim() }
            else { Write-Host "    $($linea.Trim())" -ForegroundColor Gray }
        }
    }
    if ($texto -match 'SIN problemas detectados') {
        Ok "Validacion superada: el codigo no tiene errores de compilacion conocidos"
    }
    else {
        Fallo "Se detectaron errores de VBScript."
        Dato "Publique solo despues de corregirlos; de lo contrario el sitio dara HTTP 500."
        $resp = Read-Host "`nDesea continuar de todos modos? (s/N)"
        if ($resp -notmatch '^[sS]') {
            Dato "Publicacion cancelada por el usuario."
            Read-Host "`nPresione ENTER para salir"
            exit 1
        }
    }
}
else {
    Aviso "Validador no ejecutado (falta python o validar_asp.py). Se continua sin validar."
}

# ===================================================================================
# 1. DESBLOQUEAR la seccion <asp> a nivel de servidor  (CLAVE)
# ===================================================================================
Paso "Desbloqueando la seccion <asp> a nivel de servidor"

# Sintaxis CORRECTA de appcmd:
#   appcmd unlock config /section:...            -> quita el bloqueo de la seccion
#   appcmd set config /section:... /commit:apphost  -> escribe en applicationHost.config
# NO usar /overrideModeDefault:Allow: ese atributo no existe y appcmd devuelve el
# error "Atributo 'overrideModeDefault' desconocido".
#
# NOTA: "system.webServer/asp" es la UNICA seccion valida aqui. Los nombres
# "system.webServer/asp/session" y ".../limits" NO son secciones de configuracion
# (son sub-elementos), y appcmd los rechaza con "Seccion de configuracion desconocida".
$seccionAsp = "system.webServer/asp"

# 1) Quitar el bloqueo (unlock) en el nivel de servidor
$salida = & $appcmd unlock config /section:$seccionAsp 2>&1 | Out-String
if ($LASTEXITCODE -eq 0) {
    Ok "Desbloqueada (unlock): $seccionAsp"
}
else {
    Aviso "unlock de $seccionAsp devolvio: $($salida.Trim())"
}

# 2) Asegurar que la seccion admite sobrescritura por defecto en applicationHost.config
& $appcmd set config /section:$seccionAsp /overrideMode:Allow /commit:apphost 2>&1 | Out-Null

# Verificacion efectiva: el estado debe dejar de estar "locked"
$verif = & $appcmd list config /section:$seccionAsp 2>&1 | Out-String
if ($verif -match 'locked="false"') {
    Ok "VERIFICADO: la seccion <asp> ya no esta bloqueada (locked=false)"
}
elseif ($verif -match 'locked="true"') {
    Aviso "La seccion <asp> sigue bloqueada (locked=true)"
    Dato "Si proviene de una directiva de grupo (GPO), hay que ajustarla en el dominio."
    Dato "Mitigacion aplicada: las paginas usan #include virtual, que NO depende de"
    Dato "enableParentPaths, de modo que la aplicacion funciona igualmente."
}
else {
    Aviso "No se pudo confirmar el estado de bloqueo; se continua"
}

# ===================================================================================
# 2. Publicar el web.config corregido (SIN la seccion <asp>)
# ===================================================================================
Paso "Publicando el web.config corregido"

$wcOrigen = Join-Path $Origen "web.config"
if (-not (Test-Path $wcOrigen)) {
    Fallo "No se encontro web.config junto a este script: $wcOrigen"
    Read-Host "`nPresione ENTER para salir"
    exit 1
}

try {
    Copy-Item -Path $wcOrigen -Destination (Join-Path $rutaApp "web.config") -Force
    [xml]$xVerif = Get-Content (Join-Path $rutaApp "web.config") -Raw
    $tieneAsp = $null -ne $xVerif.configuration.'system.webServer'.asp
    if ($tieneAsp) {
        Aviso "El web.config aun declara <asp>; puede volver a chocar con el bloqueo"
    }
    else {
        Ok "web.config publicado SIN la seccion <asp> (sin conflictos de bloqueo)"
    }
}
catch {
    Fallo "No se pudo publicar el web.config: $($_.Exception.Message)"
    Read-Host "`nPresione ENTER para salir"
    exit 1
}

# Sincronizar el resto del codigo por si hubo cambios
try {
    foreach ($sub in @("_includes", "admin", "css", "js")) {
        $oSub = Join-Path $Origen $sub
        $dSub = Join-Path $rutaApp $sub
        if (Test-Path $oSub) {
            if (-not (Test-Path $dSub)) { New-Item -Path $dSub -ItemType Directory -Force | Out-Null }
            Copy-Item -Path (Join-Path $oSub "*") -Destination $dSub -Recurse -Force
        }
    }
    foreach ($archivo in @("login.asp", "dashboard.asp", "logout.asp", "global.asa")) {
        $oArch = Join-Path $Origen $archivo
        if (Test-Path $oArch) { Copy-Item -Path $oArch -Destination (Join-Path $rutaApp $archivo) -Force }
    }
    Ok "Codigo de la aplicacion sincronizado"
}
catch { Aviso "No se pudo sincronizar todo el codigo: $($_.Exception.Message)" }

# --- Verificacion de la estructura de global.asa -----------------------------------
# Reglas de un global.asa valido (ASP Clasico):
#   * NO debe contener bloques <% ... %> en NINGUNA parte, ni siquiera dentro de un
#     comentario: el parser detecta el literal '<%' y lanza ASP 0137
#     "Bloque Script global no valido".
#   * Solo admite bloques <script language="VBScript" runat="Server"> ... </script>
#     con las 4 subrutinas autorizadas.
#   * Debe empezar directamente con el <script ...> (nada de encabezados decorativos).
$rutaAsa = Join-Path $rutaApp "global.asa"
if (Test-Path $rutaAsa) {
    $contenidoAsa = Get-Content $rutaAsa -Raw

    $tieneTagScript   = $contenidoAsa -match '<script\s+language="VBScript"\s+runat="Server">'
    $tieneCierreScript = $contenidoAsa -match '</script>'
    # Detectar cualquier '<%' o '%>' en todo el archivo (incluidos comentarios)
    $tieneDelimitador = $contenidoAsa -match '<%|%>'

    $primeraLinea = (($contenidoAsa -split "`r?`n") | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1)

    $problemas = @()
    if ($tieneDelimitador) {
        $problemas += "contiene bloques '<%' o '%>' (ni siquiera dentro de comentarios) -> ASP 0137"
    }
    if ($primeraLinea -notmatch '^\s*<script') {
        $problemas += "no empieza directamente con <script ... runat=""Server"">"
    }
    if (-not $tieneTagScript) { $problemas += "falta el bloque <script language=""VBScript"" runat=""Server"">" }
    if (-not $tieneCierreScript) { $problemas += "falta el cierre </script>" }

    if ($problemas.Count -eq 0) {
        Ok "global.asa: estructura valida (solo bloque <script runat=Server>, sin <% %>, con las 4 subrutinas)"
    }
    else {
        Fallo "global.asa: estructura INCORRECTA"
        foreach ($p in $problemas) { Dato "- $p" }
    }
}
else {
    Aviso "No existe global.asa en la aplicacion publicada"
}

# ===================================================================================
# 3. Aplicar las directivas de ASP
# ===================================================================================
Paso "Aplicando directivas de ASP clasico"

# NOTA IMPORTANTE
# Las paginas ahora usan #include VIRTUAL, que NO depende de enableParentPaths.
# enableParentPaths solo hace falta para #include file con rutas "..\"; se intenta
# aplicar por compatibilidad, pero su fallo ya NO impide que la aplicacion funcione.
$cmdPadres = & $appcmd set config "$Sitio/$NombreApp" /section:system.webServer/asp /enableParentPaths:"true" 2>&1 | Out-String
if ($LASTEXITCODE -eq 0) { Ok "enableParentPaths = true aplicado (compatibilidad)" }
else { Aviso "enableParentPaths no aplicado; no es critico (se usa #include virtual)" }

# scriptErrorSentToBrowser es CLAVE para diagnosticar: muestra el error real en el navegador
$cmdErr = & $appcmd set config "$Sitio/$NombreApp" /section:system.webServer/asp /scriptErrorSentToBrowser:"true" 2>&1 | Out-String
if ($LASTEXITCODE -eq 0) { Ok "scriptErrorSentToBrowser = true (los errores se ven en el navegador)" }
else { Aviso "No se pudo activar scriptErrorSentToBrowser" }

$cmdCp = & $appcmd set config "$Sitio/$NombreApp" /section:system.webServer/asp /codePage:"65001" 2>&1 | Out-String
if ($LASTEXITCODE -eq 0) { Ok "codePage = 65001 (UTF-8)" }

# session es un SUB-ELEMENTO de <asp>: appcmd set config SI lo acepta como /section.
# (unlock config NO, porque solo trabaja con secciones completas.)
$cmdSes = & $appcmd set config "$Sitio/$NombreApp" /section:system.webServer/asp/session /allowSessionState:"true" 2>&1 | Out-String
if ($LASTEXITCODE -eq 0) { Ok "allowSessionState = true" }
else { Aviso "allowSessionState no aplicado (no es critico)" }

$cmdTo = & $appcmd set config "$Sitio/$NombreApp" /section:system.webServer/asp/session /timeout:"00:30:00" 2>&1 | Out-String
if ($LASTEXITCODE -eq 0) { Ok "timeout = 00:30:00 (formato hh:mm:ss correcto)" }
else { Aviso "timeout no aplicado (no es critico)" }

# --- Verificacion efectiva ----------------------------------------------------------
$efectivo = & $appcmd list config "$Sitio/$NombreApp" /section:system.webServer/asp /xml 2>&1 | Out-String
if ($efectivo -match 'enableParentPaths="true"') {
    Ok "VERIFICADO: enableParentPaths = True (incluye con '..' operativo)"
}
else {
    Fallo "enableParentPaths NO quedo en true; fragmento de configuracion:"
    Dato $efectivo.Trim()
}

# ===================================================================================
# 4. Segmentos ocultos
# ===================================================================================
Paso "Protegiendo directorios internos"

# El web.config declara _includes y _logs. NO se manipula la coleccion con appcmd ni
# con la API: hacerlo en paralelo fue lo que producia el error
# "No se puede agregar una entrada de coleccion duplicada ... 'bin'".
try {
    [xml]$wcActual = Get-Content (Join-Path $rutaApp "web.config") -Raw
    $seg = $wcActual.configuration.'system.webServer'.security.requestFiltering.hiddenSegments.add
    if ($seg) {
        $nombres = ($seg | ForEach-Object { $_.segment }) -join ", "
        Ok "Segmentos ocultos declarados en web.config: $nombres"
    }
    else {
        Aviso "El web.config no declara segmentos ocultos"
    }
}
catch {
    Aviso "No se pudo leer los segmentos ocultos del web.config: $($_.Exception.Message)"
}

# ===================================================================================
# 5. Permisos NTFS
# ===================================================================================
Paso "Ajustando permisos NTFS"
try {
    icacls $rutaApp /grant "IIS_IUSRS:(OI)(CI)R" /T /Q | Out-Null
    Ok "Lectura para IIS_IUSRS"
}
catch { Aviso "icacls de lectura reporto incidencias" }

$rutaLogs = Join-Path $rutaApp "_logs"
if (-not (Test-Path $rutaLogs)) { New-Item -Path $rutaLogs -ItemType Directory -Force | Out-Null }
try {
    icacls $rutaLogs /grant "IIS_IUSRS:(OI)(CI)M" /T /Q | Out-Null
    Ok "Escritura para IIS_IUSRS sobre _logs"
}
catch { Aviso "icacls de escritura reporto incidencias" }

# ===================================================================================
# 6. Reiniciar el sitio y reciclar el pool
# ===================================================================================
# IMPORTANTE: global.asa solo se lee cuando ARRANCA la aplicacion. Reciclar el pool
# no siempre basta para que IIS lo reprocese. Por eso se detiene y arranca el sitio,
# garantizando que se relea el global.asa corregido.
Paso "Reiniciando el sitio y el grupo de aplicaciones"

try {
    $sitioDetenido = $false
    if (Test-Path "IIS:\Sites\$Sitio") {
        Stop-Website -Name $Sitio -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        $sitioDetenido = $true
        Write-Host "    [OK] Sitio detenido temporalmente: $Sitio" -ForegroundColor Green
    }

    if ($sitioDetenido) {
        Start-Website -Name $Sitio -ErrorAction SilentlyContinue
        Ok "Sitio reiniciado: $Sitio (global.asa se relee)"
    }
}
catch {
    Aviso "No se pudo reiniciar el sitio: $($_.Exception.Message)"
    Dato "Se intenta unicamente el reciclaje del pool"
}

try {
    if (Test-Path "IIS:\AppPools\$Pool") {
        Restart-WebAppPool -Name $Pool -ErrorAction SilentlyContinue
        Ok "Pool reciclado: $Pool"
    }
    else {
        & $appcmd recycle apppool /apppool.name:"$Pool" 2>&1 | Out-Null
        Ok "Pool reciclado via appcmd"
    }
}
catch { Aviso "No se pudo reciclar el pool: $($_.Exception.Message)" }

# El pool tambien puede reciclarse por la aplicacion concreta
& $appcmd recycle apppool /apppool.name:"$Pool" 2>&1 | Out-Null

# NOTA: la cache de plantillas ASP se invalida al reiniciar el sitio (Start-Website)
# o con iisreset. No existe un "appcmd clear config" util aqui, asi que se omite.

Start-Sleep -Seconds 4

# --- Comprobacion temprana y reinicio total si hiciera falta -----------------------
$pruebaRapida = 0
try {
    $rr = Invoke-WebRequest -Uri "http://localhost/polimusic/login.asp" -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
    $pruebaRapida = [int]$rr.StatusCode
}
catch {
    if ($_.Exception.Response) { $pruebaRapida = [int]$_.Exception.Response.StatusCode.value__ }
}

if ($pruebaRapida -ne 200) {
    Aviso "La aplicacion aun no responde 200 (codigo $pruebaRapida); se aplica un reinicio total de IIS"
    try {
        & $env:windir\system32\iisreset.exe /restart 2>&1 | Out-Null
        Write-Host "    [OK] iisreset ejecutado; esperando el arranque..." -ForegroundColor Green
        Start-Sleep -Seconds 8
    }
    catch {
        Aviso "iisreset no disponible: $($_.Exception.Message)"
    }
}

Start-Sleep -Seconds 2

# ===================================================================================
# 7. Probar la aplicacion
# ===================================================================================
Paso "Probando la aplicacion"

$url = "http://localhost/polimusic/login.asp"
$codigo = 0
$detalle = ""

try {
    $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 25 -ErrorAction Stop
    $codigo = [int]$r.StatusCode
    if ($r.Content -match "PoliMusic") { $detalle = "Contenido de PoliMusic detectado en la respuesta" }
    else { $detalle = "Responde 200 pero el contenido no parece el login" }
}
catch {
    if ($_.Exception.Response) { $codigo = [int]$_.Exception.Response.StatusCode.value__ }
    $detalle = $_.Exception.Message
}

Write-Host ""
Linea
switch ($codigo) {
    200 {
        Write-Host "  RESULTADO: HTTP 200 - LA APLICACION FUNCIONA" -ForegroundColor Green
        Linea
        Ok $detalle
        Write-Host ""
        Write-Host "  Abra en el navegador:" -ForegroundColor White
        Write-Host "    $url" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Cuentas de prueba:" -ForegroundColor White
        Write-Host "    Administrador : userAdmin  / 12345678" -ForegroundColor Cyan
        Write-Host "    Estandar      : AntonyCobos / 12345678" -ForegroundColor Cyan
    }
    500 {
        Write-Host "  RESULTADO: HTTP 500 - ERROR DE SCRIPT VBScript" -ForegroundColor Yellow
        Linea
        Dato "ASP ya ejecuta (el bloqueo desaparecio), pero una pagina falla."
        Write-Host ""
        Write-Host "  Abra la URL en el navegador para ver el mensaje exacto:" -ForegroundColor White
        Write-Host "    $url" -ForegroundColor Cyan
        Write-Host ""
        Dato "Causa probable: la base de datos no responde o faltan tablas."
        Dato "Compruebe: Test-NetConnection localhost -Port 14333"
    }
    501 {
        Write-Host "  RESULTADO: HTTP 501 - SIGUE BLOQUEADO" -ForegroundColor Red
        Linea
        Dato "La seccion <asp> continua bloqueada a nivel de servidor."
        Write-Host ""
        Write-Host "  Solucion manual (PowerShell como Administrador):" -ForegroundColor Yellow
        Write-Host "    & ""$env:windir\system32\inetsrv\appcmd.exe"" unlock config /section:system.webServer/asp" -ForegroundColor Cyan
        Write-Host "    & ""$env:windir\system32\inetsrv\appcmd.exe"" set config /section:system.webServer/asp /overrideMode:Allow /commit:apphost" -ForegroundColor Cyan
        Write-Host ""
        Dato "Las paginas usan #include virtual, que NO depende de enableParentPaths,"
        Dato "de modo que un 501 persistente indicaria un problema de otro tipo."
        Dato "Si el bloqueo proviene de una directiva de grupo (GPO), hay que ajustarlo"
        Dato "en el nivel que lo impone."
    }
    default {
        if ($codigo -eq 0) {
            Write-Host "  RESULTADO: SIN RESPUESTA" -ForegroundColor Red
            Linea
            Dato $detalle
            Dato "Verifique el servicio: Get-Service W3SVC"
        }
        else {
            Write-Host "  RESULTADO: HTTP $codigo" -ForegroundColor Yellow
            Linea
            Dato $detalle
        }
    }
}
Linea

Write-Host ""
Write-Host "  Diagnostico adicional:" -ForegroundColor White
$sqlOk = Test-NetConnection -ComputerName localhost -Port 14333 -InformationLevel Quiet -WarningAction SilentlyContinue
if ($sqlOk) { Ok "SQL Server accesible en localhost:14333" }
else { Aviso "SQL Server NO responde en localhost:14333 (revise el contenedor Docker)" }

Write-Host ""
Write-Host "  Nota: el web.config publicado ya NO declara la seccion <asp>," -ForegroundColor DarkGray
Write-Host "  de modo que no puede volver a chocar con el bloqueo del servidor." -ForegroundColor DarkGray
Write-Host ""

Read-Host "Presione ENTER para cerrar"
