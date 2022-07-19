@echo off
setlocal EnableExtensions EnableDelayedExpansion
pushd "%~dp0"

set "profile=default"

set x64suffix=
if /i "%~1" == "x64" (set "x64suffix= (x64)")
set "RegPath=HKCU\Software\Classes\Directory\shell"
set "rev=0.6.1"
set "lastupdt=2022-07-18"
set "website=https://lxvs.net/jai"

call:Logo
call:Assert "exist %profile%.ini" "error: couldn't find profile `%profile%'" || exit /b
call:ReadConf "%profile%" || (
    >&2 echo error: error reading configurations
    goto errexit
)
call:Assert "defined Config_TargetDirectory" "error: `target directory' not defined" || exit /b
call:Assert "defined Config_ItemAmount" "error: `item amount' not defined" || exit /b
call:Assert "%%Config_ItemAmount%% GTR 0" "error: `item amount' must be greater than 0" || exit /b

if "%Config_TargetDirectory:~-1%" == "\" (set "Config_TargetDirectory=%Config_TargetDirectory:~0,-1%")
set "jai_bat=%Config_TargetDirectory%\jai.bat"

@echo This script is used to add JAI ^(Just Archive It^) to right-click context menus of directories.
@echo;
@echo By entering Y, you mean to add following items:
@echo;

for /L %%i in (1,1,%Config_ItemAmount%) do (
    call:Assert "$$!Item%%i_Title!$$ NEQ $$$$" "error: title of item %%i is empty." || exit /b
    if defined Item%%i_ShortcutKey (
        set "item_%%i=!Item%%i_Title! (&!Item%%i_ShortcutKey!)"
        set "item_%%i_disp=!Item%%i_Title! (!Item%%i_ShortcutKey!)"
    ) else (
        set "item_%%i=!Item%%i_Title!"
        set "item_%%i_disp=!Item%%i_Title!"
    )
)

for /L %%i in (1,1,%Config_ItemAmount%) do (
    @echo     Item %%i Title:           !item_%%i_disp!
    @echo     Item %%i Options:         !Item%%i_Options!
    @echo     Item %%i Destination:     !Item%%i_Destination!
    @echo;
)
@echo If not, enter N and write modifications in `%profile%.custom.ini'.
@echo Items defined in `%profile%.custom.ini' will overwrite ones of the same name in `%profile%.ini'.
@echo;
set /p "confirm=Please confirm your decision (Y/N): "

if /i not "%confirm%" == "Y" (
    popd
    exit /b
)

call uninstall.bat --silent

if not exist "%Config_TargetDirectory%" (md "%Config_TargetDirectory%")

setlocal DisableDelayedExpansion
>"%TEMP%\jai.bat" (
echo @echo off
echo setlocal
echo set p7za="%%~dp07za.exe"
echo;
echo @echo;
echo @echo     Just Archive It %rev%
echo @echo     Date: %lastupdt%
echo @echo     %website%
echo @echo;
echo;
echo if "%%~1" == "" ^(goto help^)
echo if /i "%%~1" == "/?" ^(goto help^)
echo set pause=
echo if /i "%%~1" == "--not-in-term" ^(
echo     set "pause=pause"
echo     title Just Archive It %rev%
echo     shift /1
echo ^)
echo;
echo if /i "%%~1" == "--7z-help" ^(
echo     %%p7za%% --help
echo     %%pause%%
echo     exit /b
echo ^)
echo;
echo :preparamparse
echo set mx=
echo set flags_7z=
echo set target=
echo set dest=
echo set force=
echo set here=
echo set args=
echo;
echo :paramparse
echo if "%%~1" == "" ^(goto postparamparse^)
echo set "param=%%~1"
echo if "%%param%%" == "/?" ^(
echo     goto help
echo ^) else if "%%param:~0,1%%" == "-" ^(
echo     if /i "%%param:~0,3%%" == "-mx" ^(
echo         set "mx=%%param%%"
echo     ^) else if /i "%%param%%" == "-f" ^(
echo         set force=1
echo     ^) else if /i "%%param%%" == "--force" ^(
echo         set force=1
echo     ^) else if /i "%%param%%" == "--here" ^(
echo         set here=1
echo     ^) else if /i "%%param%%" == "--in-place" ^(
echo         set here=1
echo     ^) else if "%%param%%" == "-?" ^(
echo         goto help
echo     ^) else if /i "%%param%%" == "-h" ^(
echo         goto help
echo     ^) else if /i "%%param%%" == "--help" ^(
echo         goto help
echo     ^) else if /i "%%param%%" == "--7z-help" ^(
echo         %%p7za%% --help
echo         %%pause%%
echo         exit /b
echo     ^) else if "%%param%%" == "--" ^(
echo         shift /1
echo         goto skipswitches
echo     ^) else ^(
echo         set "flags_7z=%%flags_7z%% %%param%%"
echo     ^)
echo ^) else ^(
echo     set "args=%%args%% %%1"
echo ^)
echo shift /1
echo goto paramparse
echo;
echo :skipswitches
echo if "%%~1" == "" ^(goto postparamparse^)
echo set "args=%%args%% %%1"
echo shift /1
echo goto skipswitches
echo;
echo :postparamparse
echo if not defined mx ^(set "mx=-mx9"^)
echo call:parseargs %%args%% ^|^| goto errexit
echo if not defined target ^(
echo     ^>^&2 echo error: TARGET not specified
echo     ^>^&2 echo Try `jai --help' for more information
echo     goto errexit
echo ^)
echo if not exist "%%target%%" ^(
echo     ^>^&2 echo error: TARGET `%%target%%' does not exist
echo     goto errexit
echo ^)
echo if "%%target:~-1%%" == "\" ^(set "target=%%target:~0,-1%%"^)
echo if defined here ^(
echo     if defined dest ^(
echo         ^>^&2 echo error: --here/--in-place and DESTINATION are both present
echo         ^>^&2 echo Try `jai --help' for more information
echo         goto errexit
echo     ^)
echo     set "dest=%%target_dir%%"
echo ^) else if not defined dest ^(
echo     ^>^&2 echo error: DESTINATION not specified
echo     ^>^&2 echo Try `jai --help' for more information
echo     goto errexit
echo ^)
echo if "%%dest:~-1%%" == "\" ^(set "dest=%%dest:~0,-1%%"^)
echo;
echo if not exist "%%dest%%\%%target_filename%%.7z" ^(goto continue_already_existed^)
echo if defined force ^(goto continue_already_existed^)
echo set ow_confirm=
echo set /p "ow_confirm=%%dest%%\%%target_filename%%.7z has alredy existed. Enter Y to overwrite it: "
echo if /i "%%ow_confirm%%" == "y" ^(
echo     del /f "%%dest%%\%%target_filename%%.7z" ^|^| ^(
echo         goto errexit
echo     ^)
echo     goto continue_already_existed
echo ^) else ^(
echo     ^>^&2 echo operation canceled
echo     goto errexit
echo ^)
echo :continue_already_existed
echo;
echo %%p7za%% a %%flags_7z%% %%mx%% -- "%%dest%%\%%target_filename%%.7z" "%%target%%" ^|^| ^(goto errexit^)
echo exit /b
echo;
echo :help
echo @echo usage: jai.bat [SWITCHES] [--] TARGET DESTINATION
echo @echo;
echo @echo Comparess TARGET using 7-Zip and copy/move compressed archive into directory DESTINATION.
echo @echo;
echo @echo     -h, --help              show help
echo @echo     -f, --force             overwrite quietly
echo @echo     --here, --in-place      compress in place
echo @echo     --7z-help               show help on 7-Zip
echo @echo;
echo @echo 7-Zip switches:
echo @echo     -mx[N] : set compression level: -mx1 ^^^(fastest^^^) ... -mx9 ^^^(ultra^^^)
echo @echo     -p{Password} : set Password
echo @echo     -sdel : delete files after compression
echo @echo     -sse : stop archive creating, if it can't open some input file
echo @echo     -stl : set archive timestamp from the most recently modified file
echo @echo;
echo @echo     Try `jai --7z-help' for more information.
echo exit /b
echo;
echo :parseargs
echo if %%1. == . ^(exit /b^)
echo if not defined target ^(
echo     set "target=%%~1"
echo     call:GetDirAndName "%%~1" target_dir target_filename
echo     shift /1
echo     goto parseargs
echo ^)
echo if not defined dest ^(
echo     pushd "%%~1" 1^>nul 2^>^&1 ^&^& ^(
echo         set "dest=%%~1"
echo         popd
echo     ^) ^|^| ^(
echo         ^>^&2 echo error: `%%~1' does not exist or is not a directory
echo         exit /b 1
echo     ^)
echo     shift /1
echo     goto parseargs
echo ^)
echo ^>^&2 echo error: invalid argument `%%~1'
echo exit /b 1
echo;
echo :GetDirAndName
echo set "gdan_path=%%~1"
echo if "%%gdan_path:~-1%%" NEQ "\" ^(
echo     set "%%2=%%~dp1"
echo     set "%%3=%%~nx1"
echo     exit /b
echo ^)
echo set "gdan_path=%%gdan_path:~0,-1%%"
echo call:GetDirAndName "%%gdan_path%%" %%2 %%3
echo exit /b
echo;
echo :errexit
echo %%pause%%
echo exit /b 1
)
endlocal

if defined x64suffix (set "x64infix=x64\") else (set x64infix=)
set "regPathSoftware=HKCU\Software\lxvs\jai"
1>nul (
    copy /y "%TEMP%\jai.bat" "%Config_TargetDirectory%\jai.bat"
    del "%TEMP%\jai.bat"
    copy /y "License.txt" "%Config_TargetDirectory%\License.txt"
    copy /y "%x64infix%7za.exe" "%Config_TargetDirectory%\7za.exe"
    copy /y "%x64infix%7za.dll" "%Config_TargetDirectory%\7za.dll"
    copy /y "License-7z.txt" "%Config_TargetDirectory%\License-7z.txt"
    reg add "%regPathSoftware%" /v "version" /d "%rev%" /f
    reg add "%regPathSoftware%" /v "target" /d "%Config_TargetDirectory%" /f
    reg add "%regPathSoftware%" /v "amount" /d "%Config_ItemAmount%" /f
    for /L %%i in (1,1,%Config_ItemAmount%) do if defined item_%%i if defined Item%%i_Options if defined Item%%i_Destination (
        reg add "%RegPath%\jai_%%i" /ve /d "!item_%%i!" /f
        reg add "%RegPath%\jai_%%i\command" /ve /d "\"%jai_bat%\" --not-in-term \"%%1\" \"!Item%%i_Destination!\" !Item%%i_Options!" /f
    )
)

for /f "skip=2 tokens=1,2*" %%a in ('reg query "HKCU\Environment" /v "Path" 2^>NUL') do if /i "%%~a" == "path" (set "UserPath=%%c")
setx Path "%Config_TargetDirectory%;%UserPath%" 1>nul

@echo Complete
popd
pause
exit /b

:Logo
@echo;
@echo     Just Archive It v%rev%%x64suffix% Installation
@echo     %website%
@echo     Last updated: %lastupdt%
@echo;
exit /b 0

:ReadConf
@REM %1: Config file name without .ini
set "readconf_fn=%~1"
if "%readconf_fn%" == "" (set "readconf_fn=default")
call:_ReadConf "%readconf_fn%.ini" || exit /b
call:_ReadConf "%readconf_fn%.custom.ini" || exit /b 0
exit /b

:_ReadConf
pushd "%~dp0"
set "_readconf_fn=%~1"
if not exist "%_readconf_fn%" (exit /b 1)
for /f "usebackq delims=" %%a in ("%_readconf_fn%") do (
    set "line=%%~a"
    if "!line:~0,1!" == "[" (
        set "section=!line:~1,-1!"
    ) else (
        for /f "tokens=1,2 delims==" %%A in ("!line!") do (
            call set "!section!_%%~A=%%~B"
        )
    )
)
popd
exit /b

:Assert
if "%~1" == "" (exit /b 1)
set "assertion=%~1"
if %assertion:$$="% (exit /b 0)
:assert_echo
if "%~2" NEQ "" (>&2 echo %~2)
shift /2
if "%~2" NEQ "" (goto assert_echo)
goto errexit

:errexit
popd
pause
exit /b 1
