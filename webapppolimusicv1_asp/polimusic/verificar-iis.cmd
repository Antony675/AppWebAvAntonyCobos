@echo off
REM ==================================================================================
REM  PoliMusic - Verificacion y puesta en marcha final
REM ==================================================================================
REM  Ejecuta comprobaciones y aplica el ajuste final de ASP.
REM  Debe ejecutarse como Administrador (el .cmd solicita elevacion automaticamente).
REM ==================================================================================
setlocal
set "SCRIPT_DIR=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%SCRIPT_DIR%verificar-iis.ps1\"' -Verb RunAs"
endlocal
