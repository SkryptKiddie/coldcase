@echo off
setlocal ENABLEEXTENSIONS

set "TARGET_VOL=C:"
call :parse_args %*
if errorlevel 1 goto :usage

if not defined COMPUTERNAME set "COMPUTERNAME=UNKNOWNHOST"

call :make_timestamp
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "COLLECT_ROOT=%SCRIPT_DIR%\Collection-%COMPUTERNAME%-%STAMP%"
set "ZIP_FILE=%COLLECT_ROOT%.zip"
set "LOG_FILE=%COLLECT_ROOT%\collection.log"

call :mkdir "%COLLECT_ROOT%"
call :mkdir "%COLLECT_ROOT%\LiveResponse"
call :mkdir "%COLLECT_ROOT%\Registry"
call :mkdir "%COLLECT_ROOT%\EventLogs"
call :mkdir "%COLLECT_ROOT%\Filesystem"
call :mkdir "%COLLECT_ROOT%\WindowsArtifacts"
call :mkdir "%COLLECT_ROOT%\Profiles"
call :mkdir "%COLLECT_ROOT%\RecycleBin"
call :mkdir "%COLLECT_ROOT%\Bodyfile"

call :log Starting collection on %COMPUTERNAME%
call :log Target drive: %TARGET_VOL%
call :log Output folder: %COLLECT_ROOT%
if defined DRYRUN call :log Dry run enabled. No artefacts will be copied.

call :log [PHASE] Collecting system artefacts
call :collect_system
call :log [PHASE] Collecting registry artefacts
call :collect_registry
call :log [PHASE] Collecting event log artefacts
call :collect_eventlogs
call :log [PHASE] Collecting filesystem metadata artefacts
call :collect_filesystem_metadata
call :log [PHASE] Building bodyfile
call :collect_bodyfile
call :log [PHASE] Collecting Windows log/lnk/inf/prefetch/debug artefacts
call :collect_windows_artifacts
call :log [PHASE] Collecting user profile artefacts
call :collect_profiles
call :log [PHASE] Collecting Recycle Bin artefacts
call :collect_recycle_bin
call :log [PHASE] Creating ZIP package
call :normalise_attributes "%COLLECT_ROOT%"
call :capture "%COLLECT_ROOT%\collected_items.txt" tree /f %COLLECT_ROOT%
call :zip_output "%COLLECT_ROOT%" "%ZIP_FILE%"
call :cleanup_collection_folder "%COLLECT_ROOT%" "%ZIP_FILE%"

echo Collection complete.
if exist "%ZIP_FILE%" (
	echo Collection complete: "%ZIP_FILE%"
) else (
	echo Collection complete: "%COLLECT_ROOT%"
)
goto :eof

:usage
echo.
echo ColdCase Logical Collector
echo https://github.com/SkryptKiddie/coldcase
echo.
echo Collects artefacts from legacy Windows systems to conduct incident response.
echo Tested and designed for Windows XP and Windows Server 2003.
echo The tool will automatically target "C:" drive if no /target argument is provided.
echo.
echo Usage:
echo   coldcase.bat
echo   coldcase.bat /dryrun
echo   coldcase.bat /target C:
echo   coldcase.bat /dryrun /target C:
echo.
echo Notes:
echo   - Run using an Administrator command prompt.
echo   - ZIP creation uses cscript.exe and Explorer's ZIP support.
echo   - This tool does not make efforts to respect Locard's Principle. You have been warned.
goto :eof

:parse_args
if "%~1"=="" goto :eof
if /i "%~1"=="/?" exit /b 1
if /i "%~1"=="-?" exit /b 1
if /i "%~1"=="/help" exit /b 1
if /i "%~1"=="-help" exit /b 1
if /i "%~1"=="/dryrun" (
	set "DRYRUN=1"
	shift
	goto :parse_args
)
if /i "%~1"=="/target" (
	if "%~2"=="" (
		echo Missing value for /target. Expected a drive like C:.
		exit /b 1
	)
	call :set_target "%~2"
	if errorlevel 1 exit /b 1
	shift
	shift
	goto :parse_args
)
if /i "%~1:~0,8%"=="/target:" (
	call :set_target "%~1:~8%"
	if errorlevel 1 exit /b 1
	shift
	goto :parse_args
)
echo Unknown argument: %~1
exit /b 1

:set_target
set "RAW_TARGET=%~1"
if "%RAW_TARGET%"=="" exit /b 1
set "RAW_TARGET=%RAW_TARGET:\=%"
set "RAW_TARGET=%RAW_TARGET:/=%"
if not "%RAW_TARGET:~1,1%"==":" (
	echo Invalid /target value: %~1
	echo Expected format like C: or D:\
	exit /b 1
)
set "TARGET_VOL=%RAW_TARGET:~0,2%"
exit /b 0

:make_timestamp
set "STAMP="
if exist "%SystemRoot%\system32\wbem\wmic.exe" (
	for /f "tokens=2 delims==" %%I in ('"%SystemRoot%\system32\wbem\wmic.exe" os get LocalDateTime /value ^| find "="') do (
		set "STAMP=%%I"
		goto :trim_stamp
	)
)
:trim_stamp
if defined STAMP (
	set "STAMP=%STAMP:~0,4%-%STAMP:~4,2%-%STAMP:~6,2%T%STAMP:~8,2%-%STAMP:~10,2%-%STAMP:~12,2%"
	goto :eof
)
set "STAMP=%DATE%_%TIME%"
set "STAMP=%STAMP:/=-%"
set "STAMP=%STAMP::=-%"
set "STAMP=%STAMP: =0%"
set "STAMP=%STAMP:,=-%"
set "STAMP=%STAMP:.=-%"
goto :eof

:log
if defined DRYRUN (
	echo [DRYRUN] %*
	goto :eof
)
echo [%DATE% %TIME%] %*
echo [%DATE% %TIME%] %*>>"%LOG_FILE%"
goto :eof

:mkdir
if exist "%~1" goto :eof
if defined DRYRUN (
	echo [DRYRUN] MD "%~1"
	goto :eof
)
md "%~1" >nul 2>&1
goto :eof

:capture
set "CAP_OUT=%~1"
shift
if "%~1"=="" goto :eof
if defined DRYRUN (
	echo [DRYRUN] %1 %2 %3 %4 %5 %6 %7 %8 %9 ^> "%CAP_OUT%"
	goto :eof
)
call :log Running command: %1 %2 %3 %4 %5 %6 %7 %8 %9
cmd /c %1 %2 %3 %4 %5 %6 %7 %8 %9 > "%CAP_OUT%" 2>&1
goto :eof

:copy_file
if not exist "%~1" (
	call :log Missing file: %~1
	goto :eof
)
call :mkdir "%~2"
if defined DRYRUN (
	echo [DRYRUN] COPY /Y "%~1" "%~2\"
	goto :eof
)
call :log Copying file: %~1
copy /y "%~1" "%~2\" >nul 2>&1
if errorlevel 1 call :log Failed to copy file: %~1
goto :eof

:copy_dir
if not exist "%~1" (
	call :log Missing directory: %~1
	goto :eof
)
call :mkdir "%~2"
if defined DRYRUN (
	echo [DRYRUN] XCOPY "%~1" "%~2\" /E /H /I /C /K /Y /F
	goto :eof
)
call :log Copying directory: %~1 ^> %~2
xcopy "%~1" "%~2\" /E /H /I /C /K /Y /F
if errorlevel 1 call :log XCOPY reported an issue for: %~1
goto :eof

:copy_pattern
if not exist "%~1" (
	call :log No matches for pattern: %~1
	goto :eof
)
call :mkdir "%~2"
if defined DRYRUN (
	echo [DRYRUN] XCOPY "%~1" "%~2\" /S /H /I /C /K /Y /F
	goto :eof
)
call :log Copying pattern: %~1 ^> %~2
xcopy "%~1" "%~2\" /S /H /I /C /K /Y /F
if errorlevel 1 call :log XCOPY reported an issue for pattern: %~1
goto :eof

:copy_dir_without_user_account_pictures
if not exist "%~1" (
	call :log Missing directory: %~1
	goto :eof
)
call :mkdir "%~2"
set "EXCLUDE_FILE=%TEMP%\coldcase_exclude_%RANDOM%.txt"
if defined DRYRUN (
	echo [DRYRUN] XCOPY "%~1" "%~2\" /E /H /I /C /K /Y /F /EXCLUDE:"%EXCLUDE_FILE%"
	goto :eof
)
>"%EXCLUDE_FILE%" echo User Account Pictures
xcopy "%~1" "%~2\" /E /H /I /C /K /Y /F /EXCLUDE:"%EXCLUDE_FILE%"
if errorlevel 1 call :log XCOPY reported an issue for: %~1
if exist "%EXCLUDE_FILE%" del /f /q "%EXCLUDE_FILE%" >nul 2>&1
goto :eof

:save_hive
if defined DRYRUN (
	echo [DRYRUN] REG SAVE %1 "%~2" /Y
	goto :eof
)
call :log Saving hive %1
reg save %1 "%~2" /y >nul 2>&1
if errorlevel 1 call :log Failed to save hive %1
goto :eof

:collect_system
call :mkdir "%COLLECT_ROOT%\LiveResponse"
call :capture "%COLLECT_ROOT%\LiveResponse\hostname.txt" hostname
call :capture "%COLLECT_ROOT%\LiveResponse\tree.txt" tree /f %TARGET_VOL%\
call :capture "%COLLECT_ROOT%\LiveResponse\codepage.txt" chcp
call :capture "%COLLECT_ROOT%\LiveResponse\systeminfo.txt" systeminfo
call :capture "%COLLECT_ROOT%\LiveResponse\systeminfo.csv" systeminfo /FO CSV
call :capture "%COLLECT_ROOT%\LiveResponse\ipconfig_all.txt" ipconfig /all
call :capture "%COLLECT_ROOT%\LiveResponse\netstat_ano.txt" netstat -ano
call :capture "%COLLECT_ROOT%\LiveResponse\tasklist.txt" tasklist /v
call :capture "%COLLECT_ROOT%\LiveResponse\tasklist.csv" tasklist /v /FO CSV
call :capture "%COLLECT_ROOT%\LiveResponse\driverquery_v.txt" driverquery /V
call :capture "%COLLECT_ROOT%\LiveResponse\driverquery_si.txt" driverquery /SI
call :capture "%COLLECT_ROOT%\LiveResponse\services.txt" sc query 
call :capture "%COLLECT_ROOT%\LiveResponse\shares.txt" net share
call :capture "%COLLECT_ROOT%\LiveResponse\sessions.txt" net session
call :capture "%COLLECT_ROOT%\LiveResponse\users.txt" net user
call :capture "%COLLECT_ROOT%\LiveResponse\localgroups.txt" net localgroup
call :capture "%COLLECT_ROOT%\LiveResponse\routes.txt" route print 
call :capture "%COLLECT_ROOT%\LiveResponse\schtasks.txt" schtasks /query /v
call :capture "%COLLECT_ROOT%\LiveResponse\arp.txt" arp -a
call :capture "%COLLECT_ROOT%\LiveResponse\gpresult_z.txt" gpresult /Z
if exist "%SystemRoot%\pfirewall.log" call :copy_file "%SystemRoot%\pfirewall.log" "%COLLECT_ROOT%\LiveResponse"
goto :eof

:collect_registry
call :mkdir "%COLLECT_ROOT%\Registry"
call :save_hive HKLM\SAM "%COLLECT_ROOT%\Registry\SAM.hiv"
call :save_hive HKLM\SYSTEM "%COLLECT_ROOT%\Registry\SYSTEM.hiv"
call :save_hive HKLM\SOFTWARE "%COLLECT_ROOT%\Registry\SOFTWARE.hiv"
call :save_hive HKLM\SECURITY "%COLLECT_ROOT%\Registry\SECURITY.hiv"
call :save_hive HKU\.DEFAULT "%COLLECT_ROOT%\Registry\DEFAULT.hiv"
call :collect_loaded_user_hives
if exist "%SystemRoot%\repair" call :mkdir "%COLLECT_ROOT%\Registry\repair"
if exist "%SystemRoot%\repair\sam" call :copy_file "%SystemRoot%\repair\sam" "%COLLECT_ROOT%\Registry\repair"
if exist "%SystemRoot%\repair\system" call :copy_file "%SystemRoot%\repair\system" "%COLLECT_ROOT%\Registry\repair"
if exist "%SystemRoot%\repair\software" call :copy_file "%SystemRoot%\repair\software" "%COLLECT_ROOT%\Registry\repair"
if exist "%SystemRoot%\repair\security" call :copy_file "%SystemRoot%\repair\security" "%COLLECT_ROOT%\Registry\repair"
if exist "%SystemRoot%\regback" call :mkdir "%COLLECT_ROOT%\Registry\regback"
if exist "%SystemRoot%\regback\sam" call :copy_file "%SystemRoot%\regback\sam" "%COLLECT_ROOT%\Registry\regback"
if exist "%SystemRoot%\regback\system" call :copy_file "%SystemRoot%\regback\system" "%COLLECT_ROOT%\Registry\regback"
if exist "%SystemRoot%\regback\software" call :copy_file "%SystemRoot%\regback\software" "%COLLECT_ROOT%\Registry\regback"
if exist "%SystemRoot%\regback\security" call :copy_file "%SystemRoot%\regback\security" "%COLLECT_ROOT%\Registry\regback"
goto :eof

:collect_loaded_user_hives
for /f "skip=1 tokens=1" %%K in ('reg query HKU 2^>nul') do call :save_loaded_user_hive "%%K"
goto :eof

:save_loaded_user_hive
set "FULLKEY=%~1"
set "SUBKEY=%FULLKEY:HKEY_USERS\=%"
if /i "%SUBKEY%"==".DEFAULT" goto :eof
echo %SUBKEY% | find /i "_Classes" >nul
if not errorlevel 1 goto :eof
set "SAFE_SUBKEY=%SUBKEY:\=_%"
call :save_hive HKU\%SUBKEY% "%COLLECT_ROOT%\Registry\HKU_%SAFE_SUBKEY%.hiv"
goto :eof

:collect_eventlogs
call :mkdir "%COLLECT_ROOT%\EventLogs"
for %%F in ("%SystemRoot%\system32\config\*.evt") do call :copy_file "%%~fF" "%COLLECT_ROOT%\EventLogs"
for %%F in ("%SystemRoot%\system32\winevt\Logs\*.evtx") do call :copy_file "%%~fF" "%COLLECT_ROOT%\EventLogs"
goto :eof

:collect_filesystem_metadata
call :mkdir "%COLLECT_ROOT%\Filesystem"
call :capture "%COLLECT_ROOT%\Filesystem\volume_label.txt" vol %TARGET_VOL%
call :capture "%COLLECT_ROOT%\Filesystem\dir_created_time.txt" dir %TARGET_VOL%\ /a /s /-c /q /t:c
call :capture "%COLLECT_ROOT%\Filesystem\dir_modified_time.txt" dir %TARGET_VOL%\ /a /s /-c /q /t:w
call :capture "%COLLECT_ROOT%\Filesystem\dir_accessed_time.txt" dir %TARGET_VOL%\ /a /s /-c /q /t:a
call :capture "%COLLECT_ROOT%\Filesystem\file_attributes.txt" attrib %TARGET_VOL%\* /s /d
call :capture "%COLLECT_ROOT%\Filesystem\file_acls.txt" cacls %TARGET_VOL%\* /t /c
if exist "%SystemRoot%\system32\fsutil.exe" (
	call :capture "%COLLECT_ROOT%\Filesystem\fsutil_drives.txt" fsutil fsinfo drives
	call :capture "%COLLECT_ROOT%\Filesystem\fsutil_volumeinfo.txt" fsutil fsinfo volumeinfo %TARGET_VOL%
	call :capture "%COLLECT_ROOT%\Filesystem\fsutil_ntfsinfo.txt" fsutil fsinfo ntfsinfo %TARGET_VOL%
	call :capture "%COLLECT_ROOT%\Filesystem\fsutil_dirty_query.txt" fsutil dirty query %TARGET_VOL%
	call :capture "%COLLECT_ROOT%\Filesystem\fsutil_usn_queryjournal.txt" fsutil usn queryjournal %TARGET_VOL%
	call :capture "%COLLECT_ROOT%\Filesystem\fsutil_usn_enumdata.txt" fsutil usn enumdata 0 0 0x7FFFFFFFFFFFFFFF %TARGET_VOL%
	call :capture "%COLLECT_ROOT%\Filesystem\fsutil_usn_readjournal.txt" fsutil usn readjournal %TARGET_VOL% startusn=0
)
goto :eof

:collect_bodyfile
call :mkdir "%COLLECT_ROOT%\Bodyfile"
if defined DRYRUN (
	echo [DRYRUN] Generate bodyfile for %TARGET_VOL%\ ^> "%COLLECT_ROOT%\Bodyfile\bodyfile.txt"
	goto :eof
)
call :write_bodyfile_vbs "%TEMP%\logical_collection_bodyfile.vbs"
if not exist "%TEMP%\logical_collection_bodyfile.vbs" (
	call :log Failed to write bodyfile helper VBS.
	goto :eof
)
call :log Generating bodyfile: %COLLECT_ROOT%\Bodyfile\bodyfile.txt
cscript //nologo "%TEMP%\logical_collection_bodyfile.vbs" "%TARGET_VOL%\" "%COLLECT_ROOT%\Bodyfile\bodyfile.txt" >> "%LOG_FILE%" 2>&1
if errorlevel 1 call :log Bodyfile generation reported an error.
if exist "%TEMP%\logical_collection_bodyfile.vbs" del /f /q "%TEMP%\logical_collection_bodyfile.vbs" >nul 2>&1
goto :eof

:write_bodyfile_vbs
if exist "%~1" del /f /q "%~1" >nul 2>&1
>"%~1" echo Set args = WScript.Arguments
>>"%~1" echo If args.Count ^< 2 Then WScript.Quit 1
>>"%~1" echo root = args(0)
>>"%~1" echo outPath = args(1)
>>"%~1" echo Set fso = CreateObject("Scripting.FileSystemObject")
>>"%~1" echo If Not fso.FolderExists(root) Then WScript.Quit 2
>>"%~1" echo Set outFile = fso.CreateTextFile(outPath, True)
>>"%~1" echo bias = 0
>>"%~1" echo On Error Resume Next
>>"%~1" echo Set locator = CreateObject("WbemScripting.SWbemLocator")
>>"%~1" echo Set service = locator.ConnectServer(".", "root\cimv2")
>>"%~1" echo Set tzSet = service.ExecQuery("Select Bias from Win32_TimeZone")
>>"%~1" echo For Each tzItem In tzSet
>>"%~1" echo   bias = tzItem.Bias
>>"%~1" echo Next
>>"%~1" echo On Error Goto 0
>>"%~1" echo epochBase = DateSerial(1970,1,1)
>>"%~1" echo Sub ProcessFolder(folder)
>>"%~1" echo   On Error Resume Next
>>"%~1" echo   WriteBodyLine folder, 0
>>"%~1" echo   For Each fil In folder.Files
>>"%~1" echo     WriteBodyLine fil, fil.Size
>>"%~1" echo   Next
>>"%~1" echo   For Each subFolder In folder.SubFolders
>>"%~1" echo     ProcessFolder subFolder
>>"%~1" echo   Next
>>"%~1" echo   On Error Goto 0
>>"%~1" echo End Sub
>>"%~1" echo Sub WriteBodyLine(obj, sz)
>>"%~1" echo   On Error Resume Next
>>"%~1" echo   Dim atime, mtime, crtime, nm
>>"%~1" echo   nm = obj.Path
>>"%~1" echo   Err.Clear
>>"%~1" echo   atime = ToEpoch(obj.DateLastAccessed)
>>"%~1" echo   If Err.Number ^<^> 0 Or IsEmpty(atime) Or IsNull(atime) Then
>>"%~1" echo     Err.Clear
>>"%~1" echo     atime = 0
>>"%~1" echo   End If
>>"%~1" echo   Err.Clear
>>"%~1" echo   mtime = ToEpoch(obj.DateLastModified)
>>"%~1" echo   If Err.Number ^<^> 0 Or IsEmpty(mtime) Or IsNull(mtime) Then
>>"%~1" echo     Err.Clear
>>"%~1" echo     mtime = 0
>>"%~1" echo   End If
>>"%~1" echo   Err.Clear
>>"%~1" echo   crtime = ToEpoch(obj.DateCreated)
>>"%~1" echo   If Err.Number ^<^> 0 Or IsEmpty(crtime) Or IsNull(crtime) Then
>>"%~1" echo     Err.Clear
>>"%~1" echo     crtime = 0
>>"%~1" echo   End If
>>"%~1" echo   nm = Replace(nm, "|", "_")
>>"%~1" echo   outFile.WriteLine "0|" ^& nm ^& "|0|0|0|0|" ^& sz ^& "|" ^& atime ^& "|" ^& mtime ^& "|" ^& mtime ^& "|" ^& crtime
>>"%~1" echo   On Error Goto 0
>>"%~1" echo End Sub
>>"%~1" echo Function ToEpoch(dt)
>>"%~1" echo   Dim utcDt
>>"%~1" echo   utcDt = DateAdd("n", bias, dt)
>>"%~1" echo   ToEpoch = DateDiff("s", epochBase, utcDt)
>>"%~1" echo End Function
>>"%~1" echo ProcessFolder fso.GetFolder(root)
>>"%~1" echo outFile.Close
>>"%~1" echo WScript.Quit 0
goto :eof

:collect_windows_artifacts
call :mkdir "%COLLECT_ROOT%\WindowsArtifacts"
call :mkdir "%COLLECT_ROOT%\WindowsArtifacts\LOG"
call :mkdir "%COLLECT_ROOT%\WindowsArtifacts\LNK"
call :mkdir "%COLLECT_ROOT%\WindowsArtifacts\INF"
call :mkdir "%COLLECT_ROOT%\WindowsArtifacts\Prefetch"
call :mkdir "%COLLECT_ROOT%\WindowsArtifacts\Debug"
call :mkdir "%COLLECT_ROOT%\WindowsArtifacts\Persistence"
call :mkdir "%COLLECT_ROOT%\WindowsArtifacts\Tasks"
call :copy_pattern "%SystemRoot%\*.log" "%COLLECT_ROOT%\WindowsArtifacts\LOG"
call :copy_pattern "%TARGET_VOL%\*.lnk" "%COLLECT_ROOT%\WindowsArtifacts\LNK"
REM call :copy_pattern "%SystemRoot%\*.inf" "%COLLECT_ROOT%\WindowsArtifacts\INF"
REM if exist "%SystemRoot%\inf" call :copy_dir "%SystemRoot%\inf" "%COLLECT_ROOT%\WindowsArtifacts\INF\inf"
if exist "%SystemRoot%\setupapi.log" call :copy_file "%SystemRoot%\setupapi.log" "%COLLECT_ROOT%\WindowsArtifacts\INF"
if exist "%SystemRoot%\Prefetch" call :copy_dir "%SystemRoot%\Prefetch" "%COLLECT_ROOT%\WindowsArtifacts\Prefetch"
if exist "%SystemRoot%\Debug" call :copy_dir "%SystemRoot%\Debug" "%COLLECT_ROOT%\WindowsArtifacts\Debug"
if exist "%SystemRoot%\WINNT" call :copy_dir "%SystemRoot%\WINNT" "%COLLECT_ROOT%\WindowsArtifacts\Persistence"
if exist "%TARGET_VOL%\AUTOEXEC.BAT" call :copy_file "%TARGET_VOL%\AUTOEXEC.BAT" "%COLLECT_ROOT%\WindowsArtifacts\Persistence"
if exist "%SystemRoot%\System32\AUTOEXEC.NT" call :copy_file "%SystemRoot%\System32\AUTOEXEC.NT" "%COLLECT_ROOT%\WindowsArtifacts\Persistence"
if exist "%SystemRoot%\System32\CONFIG.NT" call :copy_file "%SystemRoot%\System32\CONFIG.NT" "%COLLECT_ROOT%\WindowsArtifacts\Persistence"
if exist "%SystemRoot%\System32\CONFIG.TMP" call :copy_file "%SystemRoot%\System32\CONFIG.TMP" "%COLLECT_ROOT%\WindowsArtifacts\Persistence"
if exist "%TARGET_VOL%\CONFIG.SYS" call :copy_file "%TARGET_VOL%\CONFIG.SYS" "%COLLECT_ROOT%\WindowsArtifacts\Persistence"
if exist "%SystemRoot%\WIN.INI" call :copy_file "%SystemRoot%\WIN.INI" "%COLLECT_ROOT%\WindowsArtifacts\Persistence"
if exist "%SystemRoot%\SYSTEM.INI" call :copy_file "%SystemRoot%\SYSTEM.INI" "%COLLECT_ROOT%\WindowsArtifacts\Persistence"
if exist "%SystemRoot%\Tasks" call :copy_dir "%SystemRoot%\Tasks" "%COLLECT_ROOT%\WindowsArtifacts\Tasks"
if exist "%SystemRoot%\Temp" call :copy_dir "%SystemRoot%\Temp" "%COLLECT_ROOT%\WindowsArtifacts\Temp"
if exist "%SystemRoot%\System32\Tasks" call :copy_dir "%SystemRoot%\System32\Tasks" "%COLLECT_ROOT%\WindowsArtifacts\Tasks"
if exist "%SystemRoot%\repair" call :copy_dir "%SystemRoot%\repair" "%COLLECT_ROOT%\WindowsArtifacts\repair"
goto :eof

:collect_profiles
if exist "%TARGET_VOL%\Documents and Settings" (
	for /d %%P in ("%TARGET_VOL%\Documents and Settings\*") do call :collect_one_profile "%%~fP" legacy
	goto :eof
)
if exist "%TARGET_VOL%\Users" (
	for /d %%P in ("%TARGET_VOL%\Users\*") do call :collect_one_profile "%%~fP" modern
)
goto :eof

:collect_recycle_bin
if exist "%TARGET_VOL%\RECYCLER" call :copy_dir "%TARGET_VOL%\RECYCLER" "%COLLECT_ROOT%\RecycleBin\RECYCLER"
if exist "%TARGET_VOL%\Recycled" call :copy_dir "%TARGET_VOL%\Recycled" "%COLLECT_ROOT%\RecycleBin\Recycled"
if exist "%TARGET_VOL%\$Recycle.Bin" call :copy_dir "%TARGET_VOL%\$Recycle.Bin" "%COLLECT_ROOT%\RecycleBin\$Recycle.Bin"
goto :eof

:normalise_attributes
if defined DRYRUN (
	echo [DRYRUN] ATTRIB -H -S "%~1\*" /S /D
	goto :eof
)
call :log Clearing hidden and system attributes: %~1
attrib -h -s "%~1\*" /s /d >nul 2>&1
if errorlevel 1 call :log ATTRIB reported an issue for: %~1
goto :eof

:collect_one_profile
set "PROFILE_PATH=%~1"
set "PROFILE_NAME=%~nx1"
set "PROFILE_LAYOUT=%~2"
call :mkdir "%COLLECT_ROOT%\Profiles\%PROFILE_NAME%"
call :capture "%COLLECT_ROOT%\Profiles\%PROFILE_NAME%\dir_listing.txt" dir /a /s "%PROFILE_PATH%"
if exist "%PROFILE_PATH%\NTUSER.DAT" call :copy_file "%PROFILE_PATH%\NTUSER.DAT" "%COLLECT_ROOT%\Profiles\%PROFILE_NAME%"
if exist "%PROFILE_PATH%\ntuser.dat.LOG" call :copy_file "%PROFILE_PATH%\ntuser.dat.LOG" "%COLLECT_ROOT%\Profiles\%PROFILE_NAME%"
if exist "%PROFILE_PATH%\ntuser.dat.LOG1" call :copy_file "%PROFILE_PATH%\ntuser.dat.LOG1" "%COLLECT_ROOT%\Profiles\%PROFILE_NAME%"
if exist "%PROFILE_PATH%\ntuser.dat.LOG2" call :copy_file "%PROFILE_PATH%\ntuser.dat.LOG2" "%COLLECT_ROOT%\Profiles\%PROFILE_NAME%"
if /i "%PROFILE_LAYOUT%"=="modern" (
	if exist "%PROFILE_PATH%\AppData\Roaming" call :copy_dir "%PROFILE_PATH%\AppData\Roaming" "%COLLECT_ROOT%\Profiles\%PROFILE_NAME%\AppData\Roaming"
	if exist "%PROFILE_PATH%\AppData\Local" call :copy_dir "%PROFILE_PATH%\AppData\Local" "%COLLECT_ROOT%\Profiles\%PROFILE_NAME%\AppData\Local"
	if exist "%PROFILE_PATH%\AppData\LocalLow" call :copy_dir "%PROFILE_PATH%\AppData\LocalLow" "%COLLECT_ROOT%\Profiles\%PROFILE_NAME%\AppData\LocalLow"
) else (
	if exist "%PROFILE_PATH%\Recent" call :copy_dir "%PROFILE_PATH%\Recent" "%COLLECT_ROOT%\Profiles\%PROFILE_NAME%\Recent"
	if exist "%PROFILE_PATH%\All Users\Start Menu" call :copy_dir "%PROFILE_PATH%\All Users\Start Menu" "%COLLECT_ROOT%\Profiles\%PROFILE_NAME%\All Users\Start Menu"
	if exist "%PROFILE_PATH%\Application Data" if /i "%PROFILE_NAME%"=="All Users" (
		call :copy_dir_without_user_account_pictures "%PROFILE_PATH%\Application Data" "%COLLECT_ROOT%\Profiles\%PROFILE_NAME%\Application Data"
	) else if exist "%PROFILE_PATH%\Application Data" call :copy_dir "%PROFILE_PATH%\Application Data" "%COLLECT_ROOT%\Profiles\%PROFILE_NAME%\Application Data"
	if exist "%PROFILE_PATH%\Local Settings\Application Data" call :copy_dir "%PROFILE_PATH%\Local Settings\Application Data" "%COLLECT_ROOT%\Profiles\%PROFILE_NAME%\Local Settings\Application Data"
)
goto :eof

:zip_output
if defined DRYRUN (
	echo [DRYRUN] ZIP "%~1" to "%~2"
	goto :eof
)
call :write_zip_vbs "%TEMP%\logical_collection_zip.vbs"
if not exist "%TEMP%\logical_collection_zip.vbs" (
	call :log Failed to write ZIP helper VBS.
	goto :eof
)
call :log Creating ZIP archive: %~2
cscript //nologo "%TEMP%\logical_collection_zip.vbs" "%~1" "%~2" >> "%LOG_FILE%" 2>&1
if errorlevel 1 call :log ZIP creation reported an error.
if exist "%TEMP%\logical_collection_zip.vbs" del /f /q "%TEMP%\logical_collection_zip.vbs" >nul 2>&1
goto :eof

:cleanup_collection_folder
if defined DRYRUN (
	echo [DRYRUN] RD /S /Q "%~1"
	goto :eof
)
if not exist "%~2" (
	call :log ZIP file not found, keeping uncompressed folder: %~1
	goto :eof
)
call :log Removing uncompressed collection folder: %~1
rd /s /q "%~1" >nul 2>&1
if exist "%~1" (
	echo Warning: failed to remove uncompressed folder "%~1"
) else (
	echo Removed uncompressed collection folder: "%~1"
)
goto :eof

:write_zip_vbs
if exist "%~1" del /f /q "%~1" >nul 2>&1
>"%~1" echo Set args = WScript.Arguments
>>"%~1" echo If args.Count ^< 2 Then WScript.Quit 1
>>"%~1" echo src = args(0)
>>"%~1" echo zipPath = args(1)
>>"%~1" echo Set fso = CreateObject("Scripting.FileSystemObject")
>>"%~1" echo If Not fso.FolderExists(src) Then WScript.Quit 2
>>"%~1" echo If fso.FileExists(zipPath) Then fso.DeleteFile zipPath, True
>>"%~1" echo Set stream = CreateObject("ADODB.Stream")
>>"%~1" echo stream.Type = 2
>>"%~1" echo stream.Charset = "iso-8859-1"
>>"%~1" echo stream.Open
>>"%~1" echo stream.WriteText "PK" ^& Chr(5) ^& Chr(6) ^& String(18, Chr(0))
>>"%~1" echo stream.Position = 0
>>"%~1" echo stream.Type = 1
>>"%~1" echo stream.SaveToFile zipPath, 2
>>"%~1" echo stream.Close
>>"%~1" echo Set shellApp = CreateObject("Shell.Application")
>>"%~1" echo Set srcNs = shellApp.NameSpace(src)
>>"%~1" echo Set zipNs = shellApp.NameSpace(zipPath)
>>"%~1" echo If (srcNs Is Nothing) Or (zipNs Is Nothing) Then WScript.Quit 3
>>"%~1" echo zipNs.CopyHere srcNs.Items, 20
>>"%~1" echo expected = srcNs.Items.Count
>>"%~1" echo stable = 0
>>"%~1" echo Do
>>"%~1" echo   WScript.Sleep 1000
>>"%~1" echo   current = zipNs.Items.Count
>>"%~1" echo   If current ^>= expected Then
>>"%~1" echo     stable = stable + 1
>>"%~1" echo   Else
>>"%~1" echo     stable = 0
>>"%~1" echo   End If
>>"%~1" echo Loop Until stable ^>= 3
>>"%~1" echo WScript.Quit 0
goto :eof