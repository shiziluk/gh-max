@echo off
chcp 65001 >nul
echo ============================================
echo   GH-Max ????
echo ============================================
echo.
taskkill /f /im gh_max_backend.exe >nul 2>&1
taskkill /f /im flutter_app.exe >nul 2>&1
echo ??????
echo.
echo ??? Windows ??????????? GH-Max?
echo.
pause
