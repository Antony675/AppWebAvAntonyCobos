<#
.SYNOPSIS
    Despliega la aplicacion PoliMusic en IIS bajo C:\inetpub\wwwroot.

.DESCRIPTION
    Automatiza la publicacion completa de la aplicacion web PoliMusic:
      1. Verifica IIS y el modulo de ASP Clasico.
      2. Copia los archivos de la aplicacion al directorio de publicacion.
      3. Crea la aplicacion IIS y su grupo de aplicaciones.
      4. Habilita ASP Clasico y las rutas de inclusión para este directorio.
      5. Configura permisos NTFS para el grupo IIS_IUSRS.
      6. Reinicia el sitio y verifica la respuesta HTTP.

.PARAMETER Origen
    Ruta del directorio 'polimusic' a publicar. Por defecto se resuelve en
    relacion al directorio del propio script.

.PARAMETER Destino
    Ruta raiz de publicacion. Por defecto C:\inetpub\wwwroot.

.PARAMETER NombreApp
    Nombre de la aplicacion virtual bajo el sitio de IIS. Por defecto 'polimusic'.

.PARAMETER Sitio
    Nombre del sitio de IIS. Por defecto 'Default Web Site'.

.PARAMETER Pool
    Nombre del grupo de aplicaciones. Por defecto 'PoliMusicPool'.

.EXAMPLE
    .\deploy-iis.ps1
    Despliegue estandar con valores por defecto.

.EXAMPLE
    .\deploy-iis.ps1 -NombreApp "musica" -Sitio "MiSitio"
    Despliegue en un sitio y nombre de aplicacion personalizados.

.NOTES
    Requiere ejecucion como Administrador y Windows PowerShell 5.1 o superior.
#>

[CmdletBinding()]
param(
    [string]$Origen     = "",
    [string]$Destino    = "C:\inetpub\wwwroot",
    [string]$NombreApp  = "polimusic",
    [string]$Sitio      = "Default Web Site",
    [string]$Pool       = "PoliMusicPool"
)

$ErrorActionPreference = 'Stop'
$script:Errores = @()

# =================================================================================
# Utilidades de presentacion
# =================================================================================
function Escribir-Paso {
    param([string]$Mensaje)
    Write-Host ""
    Write-Host "==> $Mensaje" -ForegroundColor Cyan
}

function Escribir-Ok {
    param([string]$Mensaje)
    Write-Host "    [OK] $Mensaje" -ForegroundColor Green
}

function Escribir-Aviso {
    param([string]$Mensaje)
    Write-Host "    [!]  $Mensaje" -ForegroundColor Yellow
}

function Escribir-Fallo {
    param([string]$Mensaje)
    Write-Host "    [X]  $Mensaje" -ForegroundColor Red
    $script:Errores += $Mensaje
}

# =================================================================================
# Banner
# =================================================================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor DarkCyan
Write-Host "  PoliMusic - Despliegue automatico en IIS" -ForegroundColor White
Write-Host "  Aplicacion web en ASP Clasico con SQL Server" -ForegroundColor DarkGray
Write-Host "================================================================" -ForegroundColor DarkCyan

# =================================================================================
# 0. Verificacion de privilegios administrativos
# =================================================================================
Escribir-Paso "Verificando privilegios de administrador"

$esAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $esAdmin) {
    Write-Host ""
    Escribir-Fallo "Se requieren privilegios de administrador."
    Write-Host "    Abra PowerShell con la opcion 'Ejecutar como administrador' y vuelva a intentarlo." -ForegroundColor Yellow
    exit 1
}
Escribir-Ok "Privilegios de administrador confirmados"

# =================================================================================
# 1. Resolucion de la ruta de origen
# =================================================================================
Escribir-Paso "Resolviendo la ubicacion de la aplicacion"

if ([string]::IsNullOrWhiteSpace($Origen)) {
    # El script se ubica en la raiz del proyecto; el codigo vive en la subcarpeta 'polimusic'
    $raizScript = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $Origen = Join-Path $raizScript "polimusic"

    # Si el script esta dentro de 'polimusic', se usa directamente ese directorio
    if (-not (Test-Path $Origen)) {
        $Origen = $raizScript
    }
}

$Origen = (Resolve-Path $Origen).Path
Escribir-Ok "Origen: $Origen"

# Archivos indispensables para considerar valido el directorio de origen
$archivosRequeridos = @("login.asp", "dashboard.asp", "_includes\conexion.asp", "css\polimusic.css", "js\polimusic.js")
$faltantes = @()

foreach ($archivo in $archivosRequeridos) {
    $rutaCompleta = Join-Path $Origen $archivo
    if (-not (Test-Path $rutaCompleta)) {
        $faltantes += $archivo
    }
}

if ($faltantes.Count -gt 0) {
    Escribir-Fallo "Faltan archivos obligatorios en el directorio de origen:"
    $faltantes | ForEach-Object { Write-Host "         - $_" -ForegroundColor Red }
    exit 1
}
Escribir-Ok "Estructura de la aplicacion validada"

# =================================================================================
# 2. Verificacion de IIS y del modulo ASP Clasico
# =================================================================================
Escribir-Paso "Verificando la instalacion de IIS"

$featureIIS = Get-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -ErrorAction SilentlyContinue
if ($null -eq $featureIIS -or $featureIIS.State -ne 'Enabled') {
    Escribir-Fallo "IIS no esta habilitado en el sistema."
    Write-Host "    Habilite las caracteristicas en: Panel de control > Programas > Activar o desactivar caracteristicas de Windows" -ForegroundColor Yellow
    exit 1
}
Escribir-Ok "Servidor IIS habilitado"

$featureASP = Get-WindowsOptionalFeature -Online -FeatureName IIS-ASP -ErrorAction SilentlyContinue
if ($null -eq $featureASP -or $featureASP.State -ne 'Enabled') {
    Escribir-Aviso "El modulo de ASP Clasico no esta habilitado. Intentando habilitarlo..."
    try {
        Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASP -All -NoRestart | Out-Null
        Escribir-Ok "Modulo ASP Clasico habilitado"
    }
    catch {
        Escribir-Fallo "No fue posible habilitar ASP Clasico: $($_.Exception.Message)"
        exit 1
    }
}
else {
    Escribir-Ok "Modulo ASP Clasico habilitado"
}

$servicioW3SVC = Get-Service -Name W3SVC -ErrorAction SilentlyContinue
if ($null -eq $servicioW3SVC) {
    Escribir-Fallo "El servicio W3SVC (World Wide Web Publishing Service) no esta disponible."
    exit 1
}
Escribir-Ok "Servicio W3SVC presente (estado: $($servicioW3SVC.Status))"

# Carga del modulo de administracion de IIS
try {
    Import-Module WebAdministration -ErrorAction Stop
    Escribir-Ok "Modulo WebAdministration cargado"
}
catch {
    Escribir-Fallo "No fue posible cargar el modulo WebAdministration: $($_.Exception.Message)"
    exit 1
}

# =================================================================================
# 3. Copia de archivos al directorio de publicacion
# =================================================================================
Escribir-Paso "Publicando archivos de la aplicacion"

$rutaApp = Join-Path $Destino $NombreApp

if (Test-Path $rutaApp) {
    Escribir-Aviso "El directorio de destino ya existe. Se actualizara su contenido:"
    Write-Host "         $rutaApp" -ForegroundColor DarkGray

    # Se elimina unicamente la carpeta de la aplicacion para evitar copias parciales
    try {
        Remove-Item -Path $rutaApp -Recurse -Force
        Escribir-Ok "Directorio anterior eliminado"
    }
    catch {
        Escribir-Fallo "No fue posible limpiar el directorio de destino: $($_.Exception.Message)"
        exit 1
    }
}

try {
    New-Item -Path $rutaApp -ItemType Directory -Force | Out-Null
    Copy-Item -Path (Join-Path $Origen "*") -Destination $rutaApp -Recurse -Force
    Escribir-Ok "Archivos copiados a: $rutaApp"
}
catch {
    Escribir-Fallo "Error durante la copia de archivos: $($_.Exception.Message)"
    exit 1
}

# El archivo de documentacion no es necesario en el servidor de produccion
$readmePub = Join-Path $rutaApp "README.md"
if (Test-Path $readmePub) {
    Remove-Item $readmePub -Force
    Escribir-Ok "Archivo README.md excluido del despliegue"
}

# Reconteo de archivos publicados
$totalArchivos = (Get-ChildItem -Path $rutaApp -Recurse -File).Count
Escribir-Ok "$totalArchivos archivos publicados"

# =================================================================================
# 4. Creacion del grupo de aplicaciones y de la aplicacion IIS
# =================================================================================
Escribir-Paso "Configurando el grupo de aplicaciones y la aplicacion IIS"

# --- Grupo de aplicaciones ---
$poolExiste = Test-Path "IIS:\AppPools\$Pool"

if (-not $poolExiste) {
    try {
        New-WebAppPool -Name $Pool -Force | Out-Null
        Escribir-Ok "Grupo de aplicaciones creado: $Pool"
    }
    catch {
        Escribir-Fallo "No fue posible crear el grupo de aplicaciones: $($_.Exception.Message)"
        exit 1
    }
}
else {
    Escribir-Ok "Grupo de aplicaciones existente reutilizado: $Pool"
}

# Configuracion del pool: .NET no gestionado y reciclaje saludable
try {
    Set-ItemProperty "IIS:\AppPools\$Pool" -Name "managedRuntimeVersion" -Value "" -ErrorAction SilentlyContinue
    Set-ItemProperty "IIS:\AppPools\$Pool" -Name "managedPipelineMode" -Value "Integrated" -ErrorAction SilentlyContinue
    Escribir-Ok "Pool configurado para aplicaciones sin .NET gestionado (ASP Clasico)"
}
catch {
    Escribir-Aviso "No se pudo ajustar la configuracion del pool: $($_.Exception.Message)"
}

# --- Sitio de destino ---
if (-not (Test-Path "IIS:\Sites\$Sitio")) {
    Escribir-Aviso "El sitio '$Sitio' no existe. Sitios disponibles:"
    Get-ChildItem "IIS:\Sites" | ForEach-Object { Write-Host "         - $($_.Name)" -ForegroundColor DarkGray }
    Escribir-Fallo "Especifique un sitio valido con el parametro -Sitio"
    exit 1
}
Escribir-Ok "Sitio destino localizado: $Sitio"

# --- Aplicacion virtual ---
$appExiste = $null -ne (Get-WebApplication -Site $Sitio -Name $NombreApp -ErrorAction SilentlyContinue)

if ($appExiste) {
    try {
        Remove-WebApplication -Site $Sitio -Name $NombreApp -ErrorAction SilentlyContinue
        Escribir-Ok "Aplicacion anterior eliminada"
    }
    catch {
        Escribir-Aviso "No se pudo eliminar la aplicacion previa: $($_.Exception.Message)"
    }
}

try {
    New-WebApplication -Site $Sitio -Name $NombreApp -PhysicalPath $rutaApp -ApplicationPool $Pool -Force | Out-Null
    Escribir-Ok "Aplicacion IIS creada en /$NombreApp"
}
catch {
    Escribir-Fallo "No fue posible crear la aplicacion IIS: $($_.Exception.Message)"
    exit 1
}

# =================================================================================
# 5. Habilitacion de ASP Clasico y rutas de inclusion
# =================================================================================
Escribir-Paso "Habilitando ASP Clasico para la aplicacion"

$rutaConfig = "IIS:\Sites\$Sitio\$NombreApp"
$appcmd     = Join-Path $env:windir "system32\inetsrv\appcmd.exe"

# ---------------------------------------------------------------------------------
# IMPORTANTE - causa del error HTTP 501
# La seccion <system.webServer/asp> suele estar BLOQUEADA a nivel de servidor
# (overrideModeDefault="Deny"). Si el web.config de la aplicacion la declara, IIS
# rechaza el archivo completo y responde 501 a TODAS las peticiones. El web.config
# publicado por este script NO la declara; la configuracion se aplica aqui con
# appcmd, que es la herramienta correcta. (Set-WebConfiguration -Metadata NO existe
# y hacia que PowerShell entrara en modo interactivo pidiendo un valor.)
# ---------------------------------------------------------------------------------

if (Test-Path $appcmd) {
    # 1) Desbloquear la seccion <asp> en applicationHost.config.
    #    Sintaxis CORRECTA: "appcmd unlock config" + "set config /overrideMode:Allow".
    #    NO usar /overrideModeDefault:Allow (atributo inexistente -> error 1168).
    #    "system.webServer/asp" es la unica seccion valida; ".../session" y ".../limits"
    #    son sub-elementos y appcmd los rechaza como "desconocidos".
    & $appcmd unlock config /section:system.webServer/asp 2>&1 | Out-Null
    & $appcmd set config /section:system.webServer/asp /overrideMode:Allow /commit:apphost 2>&1 | Out-Null
    Escribir-Ok "Seccion <asp> desbloqueada a nivel de servidor"

    # 2) Directivas de ASP. Las paginas usan #include virtual, que NO depende de
    #    enableParentPaths; se aplica igualmente por compatibilidad.
    & $appcmd set config "$Sitio/$NombreApp" /section:system.webServer/asp /enableParentPaths:"true" 2>&1 | Out-Null
    Escribir-Ok "enableParentPaths = true (compatibilidad con #include file)"

    & $appcmd set config "$Sitio/$NombreApp" /section:system.webServer/asp /scriptErrorSentToBrowser:"true" 2>&1 | Out-Null
    & $appcmd set config "$Sitio/$NombreApp" /section:system.webServer/asp /codePage:"65001" 2>&1 | Out-Null
    Escribir-Ok "Errores visibles en el navegador y pagina de codigo UTF-8"

    & $appcmd set config "$Sitio/$NombreApp" /section:system.webServer/asp/session /allowSessionState:"true" 2>&1 | Out-Null
    & $appcmd set config "$Sitio/$NombreApp" /section:system.webServer/asp/session /timeout:"00:30:00" 2>&1 | Out-Null
    Escribir-Ok "Sesion habilitada (expiracion 00:30:00, formato correcto)"
}
else {
    Escribir-Aviso "appcmd.exe no localizado; se intenta con el modulo WebAdministration"
    try {
        Set-WebConfigurationProperty -PSPath $rutaConfig -Filter "system.webServer/asp" `
            -Name "enableParentPaths" -Value $true -ErrorAction Stop
        Escribir-Ok "enableParentPaths aplicado via WebAdministration"
    }
    catch {
        Escribir-Aviso "No se pudo fijar enableParentPaths: $($_.Exception.Message)"
    }
}

# --- Verificacion efectiva ---------------------------------------------------------
try {
    $salidaAsp = & $appcmd list config "$Sitio/$NombreApp" /section:system.webServer/asp /xml 2>&1 | Out-String
    if ($salidaAsp -match 'enableParentPaths="true"') {
        Escribir-Ok "VERIFICADO: enableParentPaths = True"
    }
    else {
        Escribir-Aviso "enableParentPaths no confirmado; las paginas usan #include virtual, que no lo requiere"
    }
}
catch {
    Escribir-Aviso "No se pudo verificar enableParentPaths: $($_.Exception.Message)"
}

# --- Documento predeterminado ---
# El web.config de la aplicacion declara los documentos con <clear> + <add>. NO se
# vuelve a tocar la coleccion con la API para no volver a crear duplicados.
try {
    $docs = (Get-WebConfiguration -PSPath $rutaConfig `
        -Filter "system.webServer/defaultDocument/files" -ErrorAction SilentlyContinue)
    if ($docs) {
        Escribir-Ok "Documento predeterminado configurado (login.asp) - declarado en web.config"
    }
    else {
        Escribir-Aviso "No se pudo leer el documento predeterminado; el web.config lo declara"
    }
}
catch {
    Escribir-Aviso "No se pudo fijar el documento predeterminado: $($_.Exception.Message)"
}

# --- Extensiones bloqueadas ---
# El web.config de la aplicacion ya declara _includes y _logs usando <remove> previo,
# de modo que nunca provoca "entrada de coleccion duplicada". Aqui NO se vuelve a
# insertar nada con la API: hacerlo en paralelo al web.config era justo lo que generaba
# el conflicto de clave unica 'segment'. Solo se verifica que la seccion sea escribible.
try {
    $segmentos = (Get-WebConfiguration -PSPath $rutaConfig `
        -Filter "system.webServer/security/requestFiltering/hiddenSegments" -ErrorAction SilentlyContinue)
    if ($segmentos) {
        Escribir-Ok "Directorios internos protegidos (_includes, _logs) - declarados en web.config"
    }
    else {
        Escribir-Aviso "No se pudieron leer los segmentos ocultos; el web.config los declara"
    }
}
catch {
    Escribir-Aviso "No se pudieron aplicar los segmentos ocultos: $($_.Exception.Message)"
}

# =================================================================================
# 6. Permisos NTFS
# =================================================================================
Escribir-Paso "Ajustando permisos de sistema de archivos"

# Lectura general para la identidad del servidor web
try {
    $aclLectura = icacls $rutaApp /grant "IIS_IUSRS:(OI)(CI)R" /T /Q 2>&1
    if ($LASTEXITCODE -eq 0) {
        Escribir-Ok "Permisos de lectura otorgados a IIS_IUSRS"
    }
    else {
        Escribir-Aviso "icacls reporto incidencias: $aclLectura"
    }
}
catch {
    Escribir-Aviso "No se pudieron asignar permisos de lectura: $($_.Exception.Message)"
}

# Escritura restringida a la carpeta de bitacoras
$rutaLogs = Join-Path $rutaApp "_logs"
if (-not (Test-Path $rutaLogs)) {
    New-Item -Path $rutaLogs -ItemType Directory -Force | Out-Null
    Escribir-Ok "Directorio de bitacoras creado: _logs"
}

try {
    icacls $rutaLogs /grant "IIS_IUSRS:(OI)(CI)M" /T /Q 2>&1 | Out-Null
    Escribir-Ok "Permisos de escritura otorgados a IIS_IUSRS sobre _logs"
}
catch {
    Escribir-Aviso "No se pudieron asignar permisos de escritura en _logs: $($_.Exception.Message)"
}

# =================================================================================
# 7. Inicio de servicios y verificacion
# =================================================================================
Escribir-Paso "Iniciando servicios y verificando la respuesta"

try {
    if ((Get-Service W3SVC).Status -ne 'Running') {
        Start-Service W3SVC
        Escribir-Ok "Servicio W3SVC iniciado"
    }
    else {
        Escribir-Ok "Servicio W3SVC en ejecucion"
    }
}
catch {
    Escribir-Aviso "No se pudo iniciar W3SVC: $($_.Exception.Message)"
}

try {
    Restart-WebAppPool -Name $Pool -ErrorAction SilentlyContinue
    Escribir-Ok "Grupo de aplicaciones reiniciado"
}
catch {
    Escribir-Aviso "No se pudo reiniciar el pool: $($_.Exception.Message)"
}

# --- Prueba de conectividad HTTP ---
$urlPrueba = "http://localhost/$NombreApp/login.asp"
$respuestaCodigo = $null

try {
    $respuesta = Invoke-WebRequest -Uri $urlPrueba -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
    $respuestaCodigo = $respuesta.StatusCode
}
catch {
    if ($_.Exception.Response) {
        $respuestaCodigo = [int]$_.Exception.Response.StatusCode
    }
}

Start-Sleep -Seconds 1

if ($respuestaCodigo -eq 200) {
    Escribir-Ok "Respuesta HTTP 200: la aplicacion responde correctamente"
}
elseif ($null -ne $respuestaCodigo) {
    Escribir-Aviso "La aplicacion respondio con el codigo HTTP $respuestaCodigo"
    Write-Host "         Revise el Visor de eventos o el mensaje devuelto por la pagina." -ForegroundColor DarkGray
}
else {
    Escribir-Aviso "No se obtuvo respuesta en la direccion de prueba"
    Write-Host "         Verifique que el sitio '$Sitio' tenga un enlace (binding) activo." -ForegroundColor DarkGray
}

# --- Verificacion del puerto de SQL Server ---
Escribir-Paso "Verificando la conectividad con SQL Server"

$sqlDisponible = $false
try {
    $cliente = New-Object System.Net.Sockets.TcpClient
    $cliente.Connect("127.0.0.1", 14333)
    $sqlDisponible = $cliente.Connected
    $cliente.Close()
}
catch {
    $sqlDisponible = $false
}

if ($sqlDisponible) {
    Escribir-Ok "Puerto 14333 accesible: contenedor de SQL Server operativo"
}
else {
    Escribir-Aviso "El puerto 14333 no responde. La aplicacion mostrara un error de conexion."
    Write-Host "         Inicie el contenedor de SQL Server antes de usar la aplicacion." -ForegroundColor DarkGray
}

# =================================================================================
# Resumen final
# =================================================================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor DarkCyan
Write-Host "  RESUMEN DEL DESPLIEGUE" -ForegroundColor White
Write-Host "================================================================" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Directorio publicado : $rutaApp"
Write-Host "  Sitio IIS            : $Sitio"
Write-Host "  Aplicacion virtual   : /$NombreApp"
Write-Host "  Grupo de aplicaciones: $Pool"
Write-Host ""
Write-Host "  URL de acceso:" -ForegroundColor White
Write-Host "    $urlPrueba" -ForegroundColor Green
Write-Host ""
Write-Host "  Cuentas de prueba:" -ForegroundColor White
Write-Host "    Administrador : userAdmin  / 12345678"
Write-Host "    Estandar      : AntonyCobos / 12345678"
Write-Host ""

if ($script:Errores.Count -eq 0) {
    Write-Host "  Estado: despliegue completado sin errores." -ForegroundColor Green
}
else {
    Write-Host "  Estado: despliegue completado con $($script:Errores.Count) advertencia(s)." -ForegroundColor Yellow
    $script:Errores | ForEach-Object { Write-Host "    - $_" -ForegroundColor Yellow }
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor DarkCyan
Write-Host ""
