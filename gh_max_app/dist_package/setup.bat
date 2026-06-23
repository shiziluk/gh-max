@echo off
chcp 65001 >nul
title GH-Max 安装程序
echo ========================================
echo   GH-Max V1.0 安装程序
echo ========================================
echo.

:: 请求管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 需要管理员权限，正在重新启动...
    powershell Start-Process -FilePath '%~f0' -Verb RunAs
    exit /b
)

set "INSTALL_DIR=%ProgramFiles%\GH-Max"
set "DESKTOP=%USERPROFILE%\Desktop"
set "STARTMENU=%APPDATA%\Microsoft\Windows\Start Menu\Programs\GH-Max"

echo [1/4] 安装文件到 %INSTALL_DIR% ...
if exist "%INSTALL_DIR%" (
    echo 检测到已有安装，正在覆盖...
    rmdir /s /q "%INSTALL_DIR%" 2>nul
)
xcopy /e /i /q "%~dp0frontend" "%INSTALL_DIR%\frontend"
xcopy /e /i /q "%~dp0backend" "%INSTALL_DIR%\backend"
xcopy /e /i /q "%~dp0data" "%INSTALL_DIR%\data"
copy /y "%~dp0launcher.vbs" "%INSTALL_DIR%\launcher.vbs"

echo [2/4] 创建快捷方式...
mkdir "%STARTMENU%" 2>nul

:: 用PowerShell创建快捷方式
powershell -Command " = New-Object -ComObject WScript.Shell;  = .CreateShortcut('%DESKTOP%\GH-Max.lnk'); .TargetPath = '%INSTALL_DIR%\launcher.vbs'; .WorkingDirectory = '%INSTALL_DIR%'; .IconLocation = '%INSTALL_DIR%\frontend\flutter_app.exe,0'; .Save()"
powershell -Command " = New-Object -ComObject WScript.Shell;  = .CreateShortcut('%STARTMENU%\GH-Max.lnk'); .TargetPath = '%INSTALL_DIR%\launcher.vbs'; .WorkingDirectory = '%INSTALL_DIR%'; .IconLocation = '%INSTALL_DIR%\frontend\flutter_app.exe,0'; .Save()"
powershell -Command " = New-Object -ComObject WScript.Shell;  = .CreateShortcut('%STARTMENU%\卸载 GH-Max.lnk'); .TargetPath = '%INSTALL_DIR%\uninstall.bat'; .WorkingDirectory = '%INSTALL_DIR%'; .Save()"

echo [3/4] 创建卸载程序...
copy /y "%~dp0uninstall.bat" "%INSTALL_DIR%\uninstall.bat"

echo [4/4] 注册卸载信息...
powershell -Command "New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GH-Max' -Force | Out-Null; Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GH-Max' -Name 'DisplayName' -Value 'GH-Max'; Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GH-Max' -Name 'UninstallString' -Value '%INSTALL_DIR%\uninstall.bat'; Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GH-Max' -Name 'DisplayIcon' -Value '%INSTALL_DIR%\frontend\flutter_app.exe'; Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GH-Max' -Name 'Publisher' -Value 'GH-Max'; Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GH-Max' -Name 'DisplayVersion' -Value '1.0.0'; Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GH-Max' -Name 'NoModify' -Value 1; Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GH-Max' -Name 'NoRepair' -Value 1"

echo.
echo ========================================
echo   安装完成！
echo   桌面已创建 GH-Max 快捷方式
echo ========================================
echo.
echo 按任意键退出...
pause >nul
