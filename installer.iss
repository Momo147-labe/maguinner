#define AppName "Gestion moderne de magasin"
#define AppVersion "1.0.0"
#define AppExeName "gestion_moderne_magasin.exe"

[Setup]
AppId={9F7A6C2E-8B5D-4C7F-A2E1-123456789ABC}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=Fode Momo Soumah
AppPublisherURL=https://github.com/Momo147-labe
DefaultDirName={pf}\{#AppName}
DefaultGroupName={#AppName}
OutputDir=Output
OutputBaseFilename=Setup-Gestion-Moderne-Magasin
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
DisableProgramGroupPage=yes
PrivilegesRequired=admin
SetupIconFile=icon.ico

[Files]
; Fichiers Flutter Release
Source: "build\windows\x64\runner\Release\*"; \
DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

; DLL Visual C++ (sécurité)
Source: "C:\Windows\System32\vcruntime140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Windows\System32\msvcp140.dll"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{commondesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"

[Run]
; 🚀 Lancer l'application après installation
Filename: "{app}\{#AppExeName}"; \
Description: "Lancer {#AppName}"; \
Flags: nowait postinstall skipifsilent
