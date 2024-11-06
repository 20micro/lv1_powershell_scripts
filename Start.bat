
@echo off
pushd "%~dp0"
powershell.exe -ExecutionPolicy Bypass -File ".\Scripts\Start.ps1"
popd
echo on
