[Setup]
AppName="Snag Report Extractor"
AppVersion=1.0
DefaultDirName="{pf}\Snag Report Extractor"
DefaultGroupName=Snag Report Extractor
OutputDir=D:\Projects\snag_report_extractor_app\build\windows\x64\runner\Release\installer
OutputBaseFilename="Snag Report Extractor"
Compression=lzma
SolidCompression=yes

[Tasks]
Name: "desktopicon"; Description: "Create Desktop shortcut";

[Files]
Source: "D:\Projects\snag_report_extractor_app\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Snag Report Extractor"; Filename: "{app}\snag_report_extractor_app.exe"
Name: "{userdesktop}\Snag Report Extractor"; Filename: "{app}\snag_report_extractor_app.exe"; Tasks: desktopicon

