@echo off
chcp 1251 >nul
echo INSTALLING CERT IN CONT
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0auto_install_cert.ps1"
pause