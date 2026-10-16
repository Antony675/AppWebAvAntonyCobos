@echo off
REM ==================================================================================
REM  PoliMusic - Reparacion de la publicacion en IIS (solicita elevacion automatica)
REM ==================================================================================
setlocal
set "SCRIPT_DIR=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%SCRIPT_DIR%reparar-iis.ps1\"' -Verb RunAs"
endlocal
