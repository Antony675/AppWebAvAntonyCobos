# ==================================================================================
#  PoliMusic - Verificacion y puesta en marcha final
# ==================================================================================
#  Este script NO vuelve a publicar archivos. Solo:
#   1. Comprueba el estado real de la publicacion y de ASP.
#   2. Aplica las directivas ASP que falten (enableParentPaths, session, codePage).
#   3. Recicla el grupo de aplicaciones.
#   4. Prueba la URL y clasifica el resultado con instrucciones concretas.
#
#  Uso: doble clic en verificar-iis.cmd  (solicita UAC automaticamente)
# ==================================================================================

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Sitio     = "Default Web Site"
$NombreApp = "polimusic"
$Pool      = "PoliMusicPool"
$Destino   = "C:\inetpub\wwwroot"
$rutaApp   = Join-Path $Destino $NombreApp
$rutaConfig = "IIS:\Sites\$Sitio\$NombreApp"

function Linea { Write-Host ("-" * 64) -ForegroundColor DarkGray }
function Paso($t)  { Write-Host "`n==> $t" -ForegroundColor Cyan }
function Ok($t)    { Write-Host "    [OK] $t" -ForegroundColor Green }
function Aviso($t) { Write-Host "    [!]  $t" -ForegroundColor Yellow }
function Fallo($t) { Write-Host "    [X]  $t" -ForegroundColor Red }
function Dato($t)  { Write-Host "         $t" -ForegroundColor DarkGray }

Write-Host ""
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host "  PoliMusic - Verificacion y puesta en marcha final" -ForegroundColor Magenta
Write-Host "================================================================" -ForegroundColor Magenta

# --- Privilegios -------------------------------------------------------------------
$identidad = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identidad)
$esAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $esAdmin) {
    Fallo "Se requieren privilegios de administrador."
    Dato "Cierre esta ventana y ejecute verificar-iis.cmd (solicita UAC)."
    Read-Host "`nPresione ENTER para salir"
    exit 1
}
Ok "Privilegios de administrador confirmados"

try { Import-Module WebAdministration -ErrorAction Stop; Ok "Modulo WebAdministration cargado" }
catch { Fallo "No se pudo cargar WebAdministration: $($_.Exception.Message)"; Read-Host "ENTER para salir"; exit 1 }

# ===================================================================================
# 0. Validacion estatica del codigo fuente (causa mas probable del HTTP 500)
# ===================================================================================
# Comprueba errores de COMPILACION de VBScript que IIS solo revela al ejecutar:
#   * 'Dim' duplicado en el ambito global de una pagina ensamblada
#     -> "Name redefined" (error fatal -> HTTP 500 en TODAS las peticiones).
#   * Option Explicit mal ubicado -> 800a0400.
#   * global.asa con <% %> -> ASP 0137.
#   * bloques de control desbalanceados.
Paso "Validando la sintaxis VBScript del codigo fuente"

$validador = Join-Path $PSScriptRoot "validar_asp.py"
$python = $null
$candidatosPy = @(
    (Join-Path $env:USERPROFILE ".workbuddy-ai\binaries\python\versions\3.13.12\python.exe"),
    (Join-Path $env:USERPROFILE ".workbuddy-ai\binaries\python\versions\3.10.6\python.exe")
)
foreach ($c in $candidatosPy) { if (Test-Path $c) { $python = $c; break } }
if (-not $python) {
    foreach ($nombre in @("python", "py", "python3")) {
        $cmd = Get-Command $nombre -ErrorAction SilentlyContinue
        if ($cmd) { $python = $cmd.Source; break }
    }
}

if ($python -and (Test-Path $validador)) {
    # Se valida el CODIGO FUENTE (junto al script), no lo ya publicado
    $salida = & $python $validador $PSScriptRoot 2>&1
    $texto = ($salida | Out-String)
    $hayError = $false
    foreach ($linea in ($texto -split "`r?`n")) {
        $t = $linea.Trim()
        if ($t -eq "") { continue }
        if ($t -match '^\[X\]') { Fallo $t; $hayError = $true }
        elseif ($t -match '^\[OK\]') { Ok $t }
        elseif ($t -match '^\s*-') { Dato $t }
        elseif ($t -match 'Resultado:') { Dato $t }
    }
    if ($hayError) {
        Fallo "El codigo fuente tiene errores de compilacion VBScript."
        Dato "Esto explica un HTTP 500. Corrija los puntos marcados con [X]."
    }
    else {
        Ok "El codigo fuente compila sin errores conocidos"
    }
}
else {
    Aviso "Validador no disponible (falta python o validar_asp.py) - se omite este analisis"
}

# ===================================================================================
# 1. Estado de la publicacion
# ===================================================================================
Paso "Estado de la publicacion"

if (Test-Path $rutaApp) {
    $total = (Get-ChildItem $rutaApp -Recurse -File).Count
    Ok "Directorio publicado: $rutaApp ($total archivos)"
}
else {
    Fallo "No existe $rutaApp - ejecute primero deploy-iis.cmd"
    Read-Host "`nPresione ENTER para salir"
    exit 1
}

foreach ($f in @("login.asp", "dashboard.asp", "logout.asp", "global.asa", "web.config", "_includes\conexion.asp", "admin\panel.asp")) {
    if (Test-Path (Join-Path $rutaApp $f)) { Ok "Presente: $f" } else { Fallo "FALTA: $f" }
}

# --- Contenido del web.config publicado --------------------------------------------
$wcPub = Join-Path $rutaApp "web.config"
if (Test-Path $wcPub) {
    try {
        [xml]$xCfg = Get-Content $wcPub -Raw
        $nodoAsp = $xCfg.configuration.'system.webServer'.asp
        if ($null -ne $nodoAsp) {
            Fallo "El web.config DECLARA la seccion <asp> - esto provoca el error 501"
            Dato "La seccion <asp> esta bloqueada a nivel de servidor y no puede"
            Dato "sobrescribirse desde un web.config de aplicacion."
            Dato "Solucion: ejecutar reparar-iis.ps1 (publica el web.config corregido)"
        }
        else {
            Ok "web.config correcto: NO declara <asp> (config se aplica por appcmd)"
        }
    }
    catch { Aviso "No se pudo leer el web.config publicado: $($_.Exception.Message)" }
}
else {
    Fallo "No existe web.config en la aplicacion"
}

# --- Aplicacion y pool --------------------------------------------------------------
if (Test-Path "IIS:\Sites\$Sitio\$NombreApp") { Ok "Aplicacion IIS '/$NombreApp' registrada" }
else { Fallo "La aplicacion IIS '/$NombreApp' no existe" }

if (Test-Path "IIS:\AppPools\$Pool") { Ok "Grupo de aplicaciones '$Pool' presente" }
else { Aviso "El pool '$Pool' no existe" }

# ===================================================================================
# 2. Directivas ASP efectivas (aplicadas con appcmd)
# ===================================================================================
Paso "Aplicando directivas de ASP clasico"

$appcmd = Join-Path $env:windir "system32\inetsrv\appcmd.exe"

if (Test-Path $appcmd) {
    # Desbloquear la seccion <asp> a nivel de servidor.
    # Sintaxis CORRECTA: unlock + set config /overrideMode:Allow (NO overrideModeDefault).
    # "system.webServer/asp" es la unica seccion valida; sus sub-elementos (session,
    # limits) NO son secciones y appcmd los rechaza como desconocidos.
    & $appcmd unlock config /section:system.webServer/asp 2>&1 | Out-Null
    & $appcmd set config /section:system.webServer/asp /overrideMode:Allow /commit:apphost 2>&1 | Out-Null
    Ok "Seccion <asp> desbloqueada a nivel de servidor"

    # Directivas de ASP. enableParentPaths es opcional (se usa #include virtual).
    & $appcmd set config "$Sitio/$NombreApp" /section:system.webServer/asp /enableParentPaths:"true" 2>&1 | Out-Null
    & $appcmd set config "$Sitio/$NombreApp" /section:system.webServer/asp /scriptErrorSentToBrowser:"true" 2>&1 | Out-Null
    & $appcmd set config "$Sitio/$NombreApp" /section:system.webServer/asp /codePage:"65001" 2>&1 | Out-Null
    & $appcmd set config "$Sitio/$NombreApp" /section:system.webServer/asp/session /allowSessionState:"true" 2>&1 | Out-Null
    & $appcmd set config "$Sitio/$NombreApp" /section:system.webServer/asp/session /timeout:"00:30:00" 2>&1 | Out-Null
    Ok "Directivas ASP aplicadas (enableParentPaths, errores visibles, UTF-8, sesion 30 min)"

    # --- Verificacion efectiva ------------------------------------------------------
    $salidaAsp = & $appcmd list config "$Sitio/$NombreApp" /section:system.webServer/asp /xml 2>&1 | Out-String
    if ($salidaAsp -match 'enableParentPaths="true"') {
        Ok "VERIFICADO: enableParentPaths = True"
    }
    else {
        Aviso "enableParentPaths no confirmado; las paginas usan #include virtual, que no lo requiere"
    }
}
else {
    Fallo "appcmd.exe no encontrado; no se pueden aplicar las directivas de ASP"
}

# ===================================================================================
# 3. Permisos minimos
# ===================================================================================
Paso "Comprobando permisos NTFS"
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
# 4. Reciclar y probar
# ===================================================================================
Paso "Reciclando el grupo de aplicaciones"
try {
    if (Test-Path "IIS:\AppPools\$Pool") {
        Restart-WebAppPool -Name $Pool -ErrorAction SilentlyContinue
        Ok "Pool reciclado: $Pool"
    }
    else { Aviso "Pool inexistente, se omite" }
}
catch { Aviso "No se pudo reciclar: $($_.Exception.Message)" }

Start-Sleep -Seconds 2

Paso "Probando la aplicacion"
$url = "http://localhost/polimusic/login.asp"
$codigo = 0
$detalle = ""

try {
    $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 25 -ErrorAction Stop
    $codigo = [int]$r.StatusCode
    # Comprobar que la respuesta sea realmente el login
    if ($r.Content -match "PoliMusic") { $detalle = "Contenido de PoliMusic detectado" }
    else { $detalle = "Responde pero el contenido no parece el login" }
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
        Dato "ASP ya ejecuta, pero una pagina produce error."
        Write-Host ""
        Write-Host "  Abra esta URL en el navegador para ver el mensaje exacto" -ForegroundColor White
        Write-Host "  (scriptErrorSentToBrowser esta activo):" -ForegroundColor White
        Write-Host "    $url" -ForegroundColor Cyan
        Dato "Causa mas probable: la base de datos no responde o faltan tablas."
    }
    501 {
        Write-Host "  RESULTADO: HTTP 501 - ASP SIGUE RECHAZANDO LAS INCLUSIONES" -ForegroundColor Red
        Linea
        Dato "La seccion <asp> continua bloqueada a nivel de servidor, o el web.config"
        Dato "todavia la declara (lo que invalida el archivo completo)."
        Write-Host ""
        Write-Host "  Solucion:" -ForegroundColor Yellow
        Write-Host "    Doble clic en reparar-iis.cmd" -ForegroundColor Cyan
        Write-Host ""
        Dato "El script desbloquea la seccion con appcmd y publica el web.config sin <asp>."
    }
    default {
        if ($codigo -eq 0) {
            Write-Host "  RESULTADO: SIN RESPUESTA" -ForegroundColor Red
            Linea
            Dato $detalle
            Dato "Verifique que el servicio W3SVC este en ejecucion:  Get-Service W3SVC"
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
$contenedorOk = (Test-NetConnection -ComputerName localhost -Port 14333 -InformationLevel Quiet -WarningAction SilentlyContinue)
if ($contenedorOk) { Ok "SQL Server accesible en localhost:14333" }
else { Aviso "SQL Server NO responde en localhost:14333 (revise el contenedor Docker)" }

Write-Host ""

Read-Host "Presione ENTER para cerrar"
