unit xbhddvd;

// Xbox 360 HD DVD Player support

// The Xbox 360 HD DVD Player is a discontinued accessory for the Xbox 360
// console that enables the playback of movies on HD DVD discs. Microsoft
// offered the drive for sale between November 2006 and February 2008.

// Windows natively supports the the HD DVD drive using USB and UDF
// 256MB flash is identified as "Xbox 360 HD DVD Memory Unit" and will need a driver to use

// Hardware IDs
// Universal Serial Bus controllers
//
// "Xbox 360 HD DVD Memory Unit"
// USB\VID_045E&PID_029E&MI_00
// Microsoft Xbox 360 HD DVD Interface 0
//
// // "Xbox 360 HD DVD Memory Unit"
// USB\VID_045E&PID_029E&MI_01
// Microsoft Xbox 360 HD DVD Interface 1
//
// Download UpdateID
// 1d4d21a6-28da-492b-840f-1c67885161f3
// Download Updates
// Microsoft - Bus Controllers and Ports, Other hardware, Storage - Xbox 360 HD DVD Interface 0
// 20021667_7b6ddf62cdeb07d7c3ba4a0d902124e7212a34c2.cab (SHA1: e23fYs3rB9fDukoNkCEk5yEqNMI=) (SHA256: guSdZUxIVaeFPC9VddEPRrDJO7ldp2fWBQtgMe/Q4Rs=)

interface

uses
  Windows, SysUtils, IOUtils;

const
  DRIVER_CAB_URL = 'https://catalog.s.download.windowsupdate.com/msdownload/update/driver/drvs/2012/12/' + '20021667_7b6ddf62cdeb07d7c3ba4a0d902124e7212a34c2.cab';

  /// Returns *True* on success (package added OR driver injected)
function InstallHDDVDInterfaceDrivers: Boolean;

type
  // Minimal replica of RTL_OSVERSIONINFOW so we can call RtlGetVersion
  TRtlOSVersionInfoW = record
    dwOSVersionInfoSize: ULONG;
    dwMajorVersion: ULONG;
    dwMinorVersion: ULONG;
    dwBuildNumber: ULONG;
    dwPlatformId: ULONG;
    szCSDVersion: array [0 .. 127] of WCHAR;
  end;

  PRtlOSVersionInfoW = ^TRtlOSVersionInfoW;

  TRtlGetVersion = function(var OSVersionInfo: TRtlOSVersionInfoW): LONGINT; stdcall;

implementation

uses
  ShellAPI, UrlMon,
  main;

// ---------------------------------------------------------------------------
// Version helpers
// ---------------------------------------------------------------------------

function GetWinVersion(out Major, Minor: DWORD): Boolean;
var
  hNT: HMODULE;
  RtlGetVer: TRtlGetVersion;
  Info: TRtlOSVersionInfoW;
begin
  hNT := GetModuleHandle('ntdll.dll');
  @RtlGetVer := GetProcAddress(hNT, 'RtlGetVersion');
  Result := Assigned(RtlGetVer);
  if Result then
  begin
    ZeroMemory(@Info, SizeOf(Info));
    Info.dwOSVersionInfoSize := SizeOf(Info);
    RtlGetVer(Info);
    Major := Info.dwMajorVersion;
    Minor := Info.dwMinorVersion;
  end;
end;

function IsVistaOrEarlier: Boolean;
var
  Maj, Min: DWORD;
begin
  if not GetWinVersion(Maj, Min) then
    Exit(False);
  Result := (Maj < 6) or ((Maj = 6) and (Min = 0)); // 6.0 = Vista
end;

// ---------------------------------------------------------------------------
// Download helper
// ---------------------------------------------------------------------------

function DownloadDriverFile(const URL, FilePath: string): Boolean;
var
  hr: HRESULT;
  sz: Int64;
begin
  MainForm.LogEvent(Format('Downloading %s → %s', [URL, FilePath]), lsInfo);
  hr := URLDownloadToFile(nil, PChar(URL), PChar(FilePath), 0, nil);
  if not Succeeded(hr) then
  begin
    MainForm.LogEvent(Format('Download failed (0x%X)', [hr]), lsError);
    Exit(False);
  end;
  if not FileExists(FilePath) then
    Exit(False);
  sz := TFile.GetSize(FilePath);
  MainForm.LogEvent(Format('Download OK (%d bytes)', [sz]), lsInfo);
  Result := True;
end;

// ---------------------------------------------------------------------------
// Process launcher – optional UAC elevation (no StrUtils.IfThen)
// ---------------------------------------------------------------------------

function RunHidden(const AppName, Params: string; out ExitCode: Cardinal; Elevate: Boolean = False): Boolean;
var
  sei: TShellExecuteInfo;
  LogMsg: string;
begin
  LogMsg := 'Running: ' + AppName + ' ' + Params;
  if Elevate then
    LogMsg := LogMsg + ' (runas)';
  MainForm.LogEvent(LogMsg, lsInfo);

  ZeroMemory(@sei, SizeOf(sei));
  sei.cbSize := SizeOf(sei);
  sei.fMask := SEE_MASK_NOCLOSEPROCESS;
  sei.lpFile := PChar(AppName);
  sei.lpParameters := PChar(Params);
  sei.nShow := SW_HIDE;
  if Elevate then
    sei.lpVerb := 'runas';

  if not ShellExecuteEx(@sei) then
  begin
    ExitCode := GetLastError;
    MainForm.LogEvent('ShellExecuteEx failed (' + IntToStr(ExitCode) + ')', lsError);
    Exit(False);
  end;

  WaitForSingleObject(sei.hProcess, INFINITE);
  GetExitCodeProcess(sei.hProcess, ExitCode);
  CloseHandle(sei.hProcess);
  Result := ExitCode = 0;
end;

// ---------------------------------------------------------------------------
// Main routine
// ---------------------------------------------------------------------------
function FindFirstInf(const Dir: string; var InfPath: string): Boolean;
var
  SR: TSearchRec;
begin
  Result := False;
  if FindFirst(IncludeTrailingPathDelimiter(Dir) + '*.inf', faAnyFile, SR) = 0 then
  begin
    InfPath := IncludeTrailingPathDelimiter(Dir) + SR.Name;
    Result := True;
    FindClose(SR);
    Exit;
  end;
  if FindFirst(IncludeTrailingPathDelimiter(Dir) + '*', faDirectory, SR) = 0 then
  begin
    repeat
      if (SR.Attr and faDirectory <> 0) and (SR.Name <> '.') and (SR.Name <> '..') then
      begin
        if FindFirstInf(IncludeTrailingPathDelimiter(Dir) + SR.Name, InfPath) then
        begin
          Result := True;
          Break;
        end;
      end;
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
end;

function InstallHDDVDInterfaceDrivers: Boolean;
var
  TmpDir: array [0 .. MAX_PATH] of Char;
  CabPath: array [0 .. MAX_PATH] of Char;
  OrigCabPath: string;
  ExtractDir: string;
  ExitCode: Cardinal;
  UsePkgMgr: Boolean;
  CabFileName: string;
  InfPath: string;
  InfDir: string;
begin
  Result := False;
  MainForm.LogEvent('=== HD‑DVD driver install ===', lsInfo);

  UsePkgMgr := IsVistaOrEarlier;

  if (GetTempPath(MAX_PATH, TmpDir) = 0) or (GetTempFileName(TmpDir, 'HDD', 0, CabPath) = 0) then
  begin
    MainForm.LogEvent('Cannot create temp file', lsError);
    Exit;
  end;

  StrPCopy(CabPath, ChangeFileExt(string(CabPath), '.cab'));

  CabFileName := ExtractFileName(DRIVER_CAB_URL);
  OrigCabPath := IncludeTrailingPathDelimiter(ExtractFilePath(CabPath)) + CabFileName;
  if not RenameFile(CabPath, OrigCabPath) then
    OrigCabPath := CabPath;

  ExtractDir := IncludeTrailingPathDelimiter(ExtractFilePath(OrigCabPath)) + 'HDDExtract_' + IntToHex(GetTickCount, 8);
  ForceDirectories(ExtractDir);

  try
    if not DownloadDriverFile(DRIVER_CAB_URL, OrigCabPath) then
      Exit;

    if not UsePkgMgr then
    begin
      if not RunHidden('dism.exe', Format('/Online /Quiet /NoRestart /Add-Package /PackagePath:"%s"', [OrigCabPath]), ExitCode) then
      begin
        if ExitCode = 740 then
        begin
          MainForm.LogEvent('Elevation required → retrying', lsWarn);
          RunHidden('dism.exe', Format('/Online /NoRestart /Add-Package /PackagePath:"%s"', [OrigCabPath]), ExitCode, True);
        end;
      end;

      if ExitCode = 2 then
      begin
        MainForm.LogEvent('Add‑Package exit 2 → trying Add‑Driver (extracting CAB first)', lsWarn);

        if RunHidden('expand.exe', Format('"%s" -F:* "%s"', [OrigCabPath, ExtractDir]), ExitCode) and (ExitCode = 0) then
        begin
          // Find the first INF file recursively
          if FindFirstInf(ExtractDir, InfPath) then
          begin
            InfDir := ExtractFilePath(InfPath);
            MainForm.LogEvent('Found INF: ' + InfPath, lsInfo);
            RunHidden('dism.exe', Format('/Online /NoRestart /Add-Driver /Driver:"%s" /Recurse', [InfDir]), ExitCode, True);
          end
          else
            MainForm.LogEvent('No INF file found after extracting CAB!', lsError);
        end
        else
        begin
          MainForm.LogEvent('expand.exe failed', lsError);
        end;
      end;

      if ExitCode = 0 then
      begin
        MainForm.LogEvent('Driver installed successfully', lsInfo);
        Result := True;
      end
      else
        MainForm.LogEvent('DISM failed (exit ' + IntToStr(ExitCode) + ')', lsWarn);
    end
    else
    begin
      if RunHidden('pkgmgr.exe', Format('/ip /m:"%s"', [OrigCabPath]), ExitCode) and (ExitCode = 0) then
      begin
        Result := True;
      end
      else
        MainForm.LogEvent('pkgmgr failed (exit ' + IntToStr(ExitCode) + ')', lsWarn);
    end;
  finally
    if FileExists(OrigCabPath) then
      DeleteFile(OrigCabPath);
    if DirectoryExists(ExtractDir) then
      RemoveDir(ExtractDir);
  end;
end;

end.
