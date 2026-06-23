@echo off
chcp 65001 >nul
echo ============================================
echo   GH-Max 卸载程序
echo ============================================
echo.
taskkill /f /im gh_max_backend.exe >nul 2>&1
taskkill /f /im flutter_app.exe >nul 2>&1
echo 正在卸载...
echo.
echo 请通过 Windows 设置中的"应用和功能"卸载 GH-Max
echo.
pause