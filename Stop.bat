
@echo off
pushd "%~dp0"
powershell.exe -ExecutionPolicy Bypass -File ".\Scripts\Stop.ps1"
popd
echo on
