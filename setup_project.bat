@echo off
title FitGirl RAR Files Inspector - Build Script
color 0A

echo ===================================================
echo  Building FitGirl RAR Files Inspector Executable
echo ===================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_project.ps1"

echo.
if exist "%~dp0fitgirl-rar-files-inspector.exe" (
    echo [SUCCESS] fitgirl-rar-files-inspector.exe created successfully!
) else (
    echo [ERROR] Build failed. Please check the logs above.
)

echo.
pause