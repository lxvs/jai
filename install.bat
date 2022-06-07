@echo off
setlocal EnableExtensions EnableDelayedExpansion
pushd %~dp0

set "profile=default"

set x64suffix=
if /i "%~1" == "x64" set "x64suffix= (x64)"
set "RegPath=HKCU\SOFTWARE\Classes\Directory\shell"
set "rev=0.4.1"
set "lastupdt=2021-09-24"
set "website=https://lxvs.net/jai"

call:Logo
call:Assert "exist %profile%.ini" ^
    "ERROR: Couldn't find profile %profile%." || exit /b 2
call:ReadConf "%profile%" || (
    >&2 echo ERROR: Failed to read configurations.
    popd
    pause
    exit /b
)
call:Assert "defined Config_TargetDirectory" ^
    "ERROR: Target Directory is not defined." || exit /b 3
call:Assert "defined Config_ItemAmount" ^
    "ERROR: Item Amount is not defined." || exit /b 4
call:Assert "%%Config_ItemAmount%% GTR 0" ^
    "ERROR: Item Amount must be greater than 0." || exit /b 5

if "%Config_TargetDirectory:~-1%" == "\" set "Config_TargetDirectory=%Config_TargetDirectory:~0,-1%"
set "jai_bat=%Config_TargetDirectory%\jai.bat"

@echo This script is used to add JAI ^(Just Archive It^) to right-click context
@echo menus of directories.
@echo;
@echo By entering Y, you mean to add following items:
@echo;

for /L %%i in (1,1,%Config_ItemAmount%) do (
    call:Assert "$$!Item%%i_Title!$$ NEQ $$$$" ^
        "ERROR: Title of item %%i is empty." || exit /b 6
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
@echo If not, enter N and write modifications in '%profile%.custom.ini'.
@echo Hint: Items defined in '%profile%.custom.ini' will overwrite ones
@echo       of the same name in '%profile%.ini'.
@echo;
set /p "confirm=Please confirm your decision (Y/N): "
@echo;

if /i not "%confirm%" == "Y" (
    popd
    exit /b
)

if not exist "%Config_TargetDirectory%" md "%Config_TargetDirectory%"
attrib +h "%Config_TargetDirectory%"

setlocal DisableDelayedExpansion
>"%TEMP%\jai.bat" (
echo @echo off
echo setlocal
echo;
echo @echo;
echo @echo     Just Archive It v%rev%
echo @echo     %website%
echo @echo     Last Update: %lastupdt%
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
echo     ^>^&2 echo JAI: ERROR: the target provided is invalid.
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
echo         ^>^&2 echo JAI: ERROR: invalid switch: %%param%%.
echo         %%pause%%
echo         exit /b 4
echo     ^)
echo;
echo ^) else ^(
echo     pushd "%%param%%" 1^>nul 2^>^&1 ^&^& ^(
echo         set "archive_dir=%%param%%"
echo         popd
echo     ^) ^|^| ^(
echo         ^>^&2 echo JAI: ERROR: %%param%% does not exist or is not a directory.
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
echo     ^>^&2 echo JAI: ERROR: archive directory is not specified.
echo     ^>^&2 call:Help
echo     %%pause%%
echo     exit /b 9
echo ^)
echo;
echo if not exist "%%archive_dir%%\%%target_filename%%.7z" goto continue_already_existed
echo if defined overwrite goto continue_already_existed
echo set ow_confirm=
echo set /p "ow_confirm=JAI: %%archive_dir%%\%%target_filename%%.7z has alredy existed. Enter Y to overwrite it:"
echo if /i "%%ow_confirm%%" == "y" ^(
echo     del /f "%%archive_dir%%\%%target_filename%%.7z" ^|^| ^(
echo         %%pause%%
echo         exit /b 6
echo     ^)
echo     goto continue_already_existed
echo ^) else ^(
echo     ^>^&2 echo JAI: ABORT: user canceled.
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
echo if not exist "%%archive_dir%%\%%target_filename%%.7z" ^(
echo     ^>^&2 echo JAI: Warning: %%archive_dir%%\%%target_filename%%.7z still not exist!
echo     %%pause%%
echo     exit /b 8
echo ^)
echo;
echo exit /b
echo;
echo :HELP
echo @echo USAGE:
echo @echo;
echo @echo jai.bat ^^^<target^^^> ^^^<archive-directory^^^> [/?] [/o] [/7z] [^^^<7z options^^^> ...]
echo @echo;
echo @echo         ^^^<target^^^>                The directory to be archived
echo @echo         ^^^<archive-directory^^^>     Where archives go.
echo @echo                                 /here means the same location as ^^^<target^^^>.
echo @echo;
echo @echo Switches:
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
echo @echo         Use '%%~nx0 /7z' for complete 7z option list.
echo exit /b
)
endlocal

copy /y "%TEMP%\jai.bat" "%Config_TargetDirectory%\jai.bat" 1>nul
del /f "%TEMP%\jai.bat" 1>nul
copy /y "License.txt" "%Config_TargetDirectory%\License.txt" 1>nul
if defined x64suffix (set "x64infix=x64\") else set "x64infix="
copy /y "%x64infix%7za.exe" "%Config_TargetDirectory%\7za.exe" 1>nul
copy /y "%x64infix%7za.dll" "%Config_TargetDirectory%\7za.dll" 1>nul
copy /y "License-7z.txt" "%Config_TargetDirectory%\License-7z.txt" 1>nul

reg add "HKCU\SOFTWARE\JAI" /ve /d "Just Archive It v%rev%" /f 1>nul
reg add "HKCU\SOFTWARE\JAI" /v "Target" /d "%Config_TargetDirectory%" /f 1>nul
reg add "HKCU\SOFTWARE\JAI" /v "Amount" /d "%Config_ItemAmount%" /f 1>nul
for /L %%i in (1,1,%Config_ItemAmount%) do if defined item_%%i if defined Item%%i_Options if defined Item%%i_Destination (
    reg add "%RegPath%\JAI_%%i" /ve /d "!item_%%i!" /f 1>nul
    reg add "%RegPath%\JAI_%%i\command" /ve /d "\"%jai_bat%\" noterm \"%%1\" \"!Item%%i_Destination!\" !Item%%i_Options!" /f 1>nul
)

for /f "skip=2 tokens=1,2*" %%a in ('reg query "HKCU\Environment" /v "Path" 2^>NUL') do if /i "%%~a" == "path" set "UserPath=%%c"
setx PATH "%Config_TargetDirectory%;%UserPath%" 1>NUL

if %ErrorLevel% == 0 (
    @echo Complete.
) else (
    >&2 echo Unspecified error.
)
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
popd
pause
exit /b 1
