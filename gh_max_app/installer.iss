; GH-Max Installer Script for Inno Setup

#define MyAppName "GH-Max"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "shiziluk"
#define MyAppURL "https://github.com/shiziluk/gh-max"

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
UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\frontend\flutter_app.exe

[Languages]
Name: "chinese"; MessagesFile: "ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加图标:"; Flags: checkedonce

[Files]
Source: "dist_package\launcher.vbs"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist_package\setup.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist_package\uninstall.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist_package\frontend\*"; DestDir: "{app}\frontend"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "dist_package\backend\*"; DestDir: "{app}\backend"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "dist_package\data\*"; DestDir: "{app}\backend\data"; Flags: ignoreversion recursesubdirs createallsubdirs onlyifdoesntexist

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "wscript.exe"; Parameters: """{app}\launcher.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\frontend\flutter_app.exe"
Name: "{group}\卸载 {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "wscript.exe"; Parameters: """{app}\launcher.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\frontend\flutter_app.exe"; Tasks: desktopicon

[Run]
Filename: "wscript.exe"; Parameters: """{app}\launcher.vbs"""; Description: "启动 {#MyAppName}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "taskkill"; Parameters: "/f /im gh_max_backend.exe"; Flags: runhidden; RunOnceId: "KillBackend"
Filename: "taskkill"; Parameters: "/f /im flutter_app.exe"; Flags: runhidden; RunOnceId: "KillFrontend"
