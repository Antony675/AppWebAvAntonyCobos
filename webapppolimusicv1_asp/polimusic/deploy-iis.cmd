@echo off
REM ===============================================================================
REM  PoliMusic - Lanzador del despliegue en IIS
REM  Solicita elevacion de privilegios y ejecuta el script de PowerShell.
REM ===============================================================================

setlocal
cd /d "%~dp0"

echo.
echo  PoliMusic - Despliegue en IIS
echo  ============================================================
echo.

REM --- Verificacion de privilegios administrativos ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo  Se requieren privilegios de administrador.
    echo  Solicitando elevacion...
    echo.

    REM Relanza este mismo archivo con permisos elevados
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo  Privilegios de administrador confirmados.
echo  Iniciando despliegue...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy-iis.ps1"

echo.
echo  Presione cualquier tecla para cerrar esta ventana.
pause >nul

endlocal
