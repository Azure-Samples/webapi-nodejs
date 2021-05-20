@echo off

set SCRIPT_DIR=%~dp0

REM Defer initialization logic to Powershell script...
powershell %SCRIPT_DIR%pre-init.ps1
