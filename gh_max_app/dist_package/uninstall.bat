@echo off
chcp 65001 >nul
title GH-Max 卸载程序
echo ========================================
echo   GH-Max V1.0 卸载程序
echo ========================================
echo.

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 需要管理员权限，正在重新启动...
    powershell Start-Process -FilePath '%~f0' -Verb RunAs
    exit /b
)

echo 正在停止 GH-Max 进程...
taskkill /f /im gh_max_backend.exe >nul 2>&1
taskkill /f /im flutter_app.exe >nul 2>&1
timeout /t 2 /nobreak >nul

echo 正在删除文件...
rmdir /s /q "%ProgramFiles%\GH-Max" 2>nul

echo 正在删除快捷方式...
del /q "%USERPROFILE%\Desktop\GH-Max.lnk" 2>nul
rmdir /s /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\GH-Max" 2>nul

echo 正在删除注册信息...
powershell -Command "Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GH-Max' -Force -ErrorAction SilentlyContinue"

echo.
echo ========================================
echo   GH-Max 已成功卸载
echo ========================================
echo.
echo 按任意键退出...
pause >nul
