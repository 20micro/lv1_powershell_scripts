
@echo off
chcp 1250>nul
pushd "%~dp0"
powershell.exe -ExecutionPolicy Bypass -File ".\Scripts\ConfigNetwork.ps1"
popd
echo.
pause
echo on
