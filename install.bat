@echo off
setlocal EnableExtensions EnableDelayedExpansion
pushd "%~dp0"

set "profile=default"

set x64suffix=
if /i "%~1" == "x64" set "x64suffix= (x64)"
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

if not exist "%Config_TargetDirectory%" md "%Config_TargetDirectory%"

setlocal DisableDelayedExpansion
>"%TEMP%\jai.bat" (
echo @echo off
echo setlocal
echo;
echo @echo;
echo @echo     Just Archive It v%rev%
echo @echo     Date: %lastupdt%
echo @echo     %website%
echo @echo;
echo;
echo pushd %%~dp0
echo;
echo if "%%~1" == "" goto help
echo if /i "%%~1" == "/?" goto help
echo if /i "%%~1" == "noterm" ^(
echo     set "pause=pause"
echo     title Just Archive It v%rev%
echo     shift
echo ^) else set "pause="
echo;
echo if /i "%%~1" == "/7z" ^(
echo     7za.exe
echo     %%pause%%
echo     exit /b
echo ^)
echo;
echo set "target=%%~1"
echo set "target_filename=%%~nx1"
echo set "target_dir=%%~dp1"
echo if "%%target_dir:~-1%%" == "\" set "target_dir=%%target_dir:~0,-1%%"
echo shift
echo;
echo if not exist "%%target%%" ^(
echo     ^>^&2 echo error: the target provided is invalid.
echo     ^>^&2 call:HELP
echo     %%pause%%
echo     exit /b 2
echo ^)
echo;
echo :preparamparse
echo set "mx="
echo set "args="
echo set "archive_dir="
echo set "overwrite="
echo;
echo :paramparse
echo if "%%~1" == "" goto postparamparse
echo set "param=%%~1"
echo if "%%param:~0,1%%" == "-" ^(
echo     if /i "%%param:~0,3%%" == "-mx" ^(
echo         set "mx=%%param%%"
echo     ^) else set "args=%%args%% %%param%%"
echo;
echo ^) else if "%%param:~0,1%%" == "/" ^(
echo     if /i "%%param%%" == "/o" ^(
echo         set "overwrite=1"
echo     ^) else if /i "%%param%%" == "/here" ^(
echo         set "archive_dir=%%target_dir%%"
echo     ^) else if /i "%%param%%" == "/?" ^(
echo         goto HELP
echo     ^) else if /i "%%param%%" == "/7z" ^(
echo         7za.exe
echo         %%pause%%
echo         exit /b
echo     ^) else ^(
echo         ^>^&2 echo error: invalid switch: `%%param%%'
echo         %%pause%%
echo         exit /b 4
echo     ^)
echo;
echo ^) else ^(
echo     pushd "%%param%%" 1^>nul 2^>^&1 ^&^& ^(
echo         set "archive_dir=%%param%%"
echo         popd
echo     ^) ^|^| ^(
echo         ^>^&2 echo error: `%%param%%' does not exist or is not a directory.
echo         %%pause%%
echo         exit /b 5
echo     ^)
echo ^)
echo;
echo shift
echo goto paramparse
echo;
echo :postparamparse
echo;
echo if not defined archive_dir ^(
echo     ^>^&2 echo error: archive directory not specified
echo     ^>^&2 call:Help
echo     %%pause%%
echo     exit /b 9
echo ^)
echo;
echo if not exist "%%archive_dir%%\%%target_filename%%.7z" goto continue_already_existed
echo if defined overwrite goto continue_already_existed
echo set ow_confirm=
echo set /p "ow_confirm=%%archive_dir%%\%%target_filename%%.7z has alredy existed. Enter Y to overwrite it: "
echo if /i "%%ow_confirm%%" == "y" ^(
echo     del /f "%%archive_dir%%\%%target_filename%%.7z" ^|^| ^(
echo         %%pause%%
echo         exit /b 6
echo     ^)
echo     goto continue_already_existed
echo ^) else ^(
echo     ^>^&2 echo operation canceled.
echo     %%pause%%
echo     exit /b 7
echo ^)
echo :continue_already_existed
echo;
echo if not defined mx set "mx=-mx9"
echo;
echo 7za.exe a %%args%% %%mx%% "%%archive_dir%%\%%target_filename%%.7z" "%%target%%" ^|^| ^(
echo     %%pause%%
echo     exit /b
echo ^)
echo;
echo exit /b
echo;
echo :HELP
echo @echo usage: jai.bat ^^^<target^^^> ^^^<archive-directory^^^> [/?] [/o] [/7z] [^^^<7z options^^^> ...]
echo @echo;
echo @echo         ^^^<target^^^>                The directory to be archived
echo @echo         ^^^<archive-directory^^^>     Where archives go.
echo @echo                                 /here means the same location as ^^^<target^^^>.
echo @echo;
echo @echo^(        /?  show help
echo @echo         /o  overwrite the archive with the same name, without prompts.
echo @echo             By default, it will prompt user whether to overwrite or not.
echo @echo         /7z Show 7z's help
echo @echo;
echo @echo 7Z options:
echo @echo         -mx[N] : set compression level: -mx1 ^^^(fastest^^^) ... -mx9 ^^^(ultra^^^)
echo @echo         -p{Password} : set Password
echo @echo         -sdel : delete files after compression
echo @echo         -sse : stop archive creating, if it can't open some input file
echo @echo         -stl : set archive timestamp from the most recently modified file
echo @echo;
echo @echo         Use `%%~nx0 /7z' for complete 7z option list.
echo exit /b
)
endlocal

if defined x64suffix (set "x64infix=x64\") else (set x64infix=)
1>nul (
    copy /y "%TEMP%\jai.bat" "%Config_TargetDirectory%\jai.bat"
    del "%TEMP%\jai.bat"
    copy /y "License.txt" "%Config_TargetDirectory%\License.txt"
    copy /y "%x64infix%7za.exe" "%Config_TargetDirectory%\7za.exe"
    copy /y "%x64infix%7za.dll" "%Config_TargetDirectory%\7za.dll"
    copy /y "License-7z.txt" "%Config_TargetDirectory%\License-7z.txt"
    reg add "HKCU\Software\jai" /v "version" /d "%rev%" /f
    reg add "HKCU\Software\jai" /v "target" /d "%Config_TargetDirectory%" /f
    reg add "HKCU\Software\jai" /v "amount" /d "%Config_ItemAmount%" /f
    for /L %%i in (1,1,%Config_ItemAmount%) do if defined item_%%i if defined Item%%i_Options if defined Item%%i_Destination (
        reg add "%RegPath%\jai_%%i" /ve /d "!item_%%i!" /f
        reg add "%RegPath%\jai_%%i\command" /ve /d "\"%jai_bat%\" noterm \"%%1\" \"!Item%%i_Destination!\" !Item%%i_Options!" /f
    )
)

for /f "skip=2 tokens=1,2*" %%a in ('reg query "HKCU\Environment" /v "Path" 2^>NUL') do if /i "%%~a" == "path" (set "UserPath=%%c")
setx Path "%Config_TargetDirectory%;%UserPath%" 1>nul

@echo Complete.
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
if "%readconf_fn%" == "" set "readconf_fn=default"
call:_ReadConf "%readconf_fn%.ini" || exit /b
call:_ReadConf "%readconf_fn%.custom.ini" || exit /b 0
exit /b

:_ReadConf
pushd %~dp0
set "_readconf_fn=%~1"
if not exist "%_readconf_fn%" exit /b 1
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
if "%~1" == "" exit /b 1
set "assertion=%~1"
if %assertion:$$="% exit /b 0
:assert_echo
if "%~2" NEQ "" >&2 echo %~2
shift /2
if "%~2" NEQ "" goto assert_echo
goto errexit

:errexit
popd
pause
exit /b 1
