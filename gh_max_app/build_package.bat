@echo off
chcp 65001 >nul
echo ========================================
echo   GH-Max 打包构建脚本
echo ========================================
echo.

set "ROOT_DIR=%~dp0"
set "BACKEND_DIR=%ROOT_DIR%backend"
set "FRONTEND_DIR=%ROOT_DIR%flutter_app"

echo [1/3] 构建Python后端...
cd /d "%BACKEND_DIR%"
pip install -r requirements.txt
pyinstaller --clean --onefile --name gh_max_backend --add-data "data;data" --add-data "logs;logs" --hidden-import akshare --hidden-import flask --hidden-import flask_cors --hidden-import numpy --hidden-import pandas --hidden-import requests --hidden-import bs4 --hidden-import lxml --hidden-import schedule --hidden-import apscheduler --console app.py

if %ERRORLEVEL% NEQ 0 (
    echo 后端构建失败!
    pause
    exit /b 1
)

echo.
echo [2/3] 检查Flutter前端...
cd /d "%FRONTEND_DIR%"
if not exist "Release\flutter_app.exe" (
    echo 未找到Release构建，正在构建...
    flutter build windows --release
)

echo.
echo [3/3] 打包完成!
echo.
echo 文件位置:
echo   后端: %BACKEND_DIR%\dist\gh_max_backend.exe
echo   前端: %FRONTEND_DIR%\Release\flutter_app.exe
echo.
echo 如需创建安装包，请使用 Inno Setup 打开 installer.iss 编译。
echo ========================================
pause
