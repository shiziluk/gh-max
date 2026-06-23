; GH-Max Installer Script for Inno Setup
; https://jrsoftware.org/isinfo.php

#define MyAppName "GH-Max"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "GH-Max"
#define MyAppURL "https://github.com/yourusername/gh-max"
#define MyAppExeName "flutter_app.exe"
#define MyBackendExeName "gh_max_backend.exe"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=..\installer_output
OutputBaseFilename=GH-Max-Setup-v{#MyAppVersion}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin

[Languages]
Name: "chinese"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加图标:"; Flags: checkedonce

[Files]
; Flutter前端应用
Source: "flutter_app\Release\*"; DestDir: "{app}\frontend"; Flags: ignoreversion recursesubdirs createallsubdirs
; Python后端（由PyInstaller打包）
Source: "backend\dist\gh_max_backend.exe"; DestDir: "{app}\backend"; Flags: ignoreversion
; 后端数据目录
Source: "backend\data\*"; DestDir: "{app}\backend\data"; Flags: ignoreversion recursesubdirs createallsubdirs onlyifdoesntexist
Source: "backend\logs\*"; DestDir: "{app}\backend\logs"; Flags: ignoreversion recursesubdirs createallsubdirs onlyifdoesntexist skipifsourcedoesntexist

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\frontend\{#MyAppExeName}"
Name: "{group}\卸载 {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\frontend\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; 启动后端服务（后台运行）
Filename: "{app}\backend\{#MyBackendExeName}"; Parameters: ""; Flags: runhidden nowait; Description: "启动后端服务"
; 启动前端应用
Filename: "{app}\frontend\{#MyAppExeName}"; Description: "启动 GH-Max"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; 停止后端进程
Filename: "taskkill"; Parameters: "/f /im {#MyBackendExeName}"; Flags: runhidden

[Code]
// 安装前检查
function InitializeSetup: Boolean;
begin
  Result := True;
end;
