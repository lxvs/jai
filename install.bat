@echo off
setlocal EnableExtensions EnableDelayedExpansion
pushd %~dp0

@REM set profile here, omit the .ini suffix.
set "profile=default"

set x64suffix=
if /i "%~1" == "x64" set "x64suffix= (x64)"
set "RegPath=HKCU\SOFTWARE\Classes\Directory\shell"
set "rev=0.3.0"
set "lastupdt=2021-07-08"
set "website=https://lxvs.net/jai"

call:Logo
call:Assert "exist %profile%.ini" ^
    "ERROR: Couldn't find profile %profile%." || exit /b 2
call:ReadConf "%profile%" "config" "Target Directory" "target_dir"
call:ReadConf "%profile%" "config" "Item Amount" "item_amount"
call:Assert "defined target_dir" ^
    "ERROR: Target Directory is not defined." || exit /b 3
call:Assert "defined item_amount" ^
    "ERROR: Item Amount is not defined." || exit /b 4
call:Assert "%%item_amount%% GTR 0" ^
    "ERROR: Item Amount must be greater than 0." || exit /b 5

if "%target_dir:~-1%" == "\" set "target_dir=%target_dir:~0,-1%"
set "jai_bat=%target_dir%\jai.bat"

@echo This script is used to add JAI ^(Just Archive It^) to right-click context
@echo menus of directories.
@echo;
@echo By entering Y, you mean to add following items:
@echo;

for /L %%i in (1,1,%item_amount%) do (
    call:ReadConf "%profile%" "Item %%i" "Title" "item_%%i_title"
    call:ReadConf "%profile%" "Item %%i" "Shortcut Key" "item_%%i_sck"
    call:ReadConf "%profile%" "Item %%i" "Options" "item_%%i_opt"
    call:ReadConf "%profile%" "Item %%i" "Destination" "item_%%i_dest"
    call:Assert "$$!item_%%i_title!$$ NEQ $$$$" ^
        "ERROR: Title of item %%i is empty." || exit /b 6
    if defined item_%%i_sck (
        set "item_%%i=!item_%%i_title! (&!item_%%i_sck!)"
        set "item_%%i_disp=!item_%%i_title! (!item_%%i_sck!)"
    ) else (
        set "item_%%i=!item_%%i_title!"
        set "item_%%i_disp=!item_%%i_title!"
    )
    @echo     Item %%i Title:           !item_%%i_disp!
    @echo     Item %%i Options:         !item_%%i_opt!
    @echo     Item %%i Destination:     !item_%%i_dest!
    @echo;
)

@echo If not, enter N and edit this script with a text editor.
@echo;
set /p "confirm=Please confirm your decision (Y/N): "
@echo;

if /i not "%confirm%" == "Y" (
    popd
    exit /b
)

if not exist "%target_dir%" md "%target_dir%"
attrib +h "%target_dir%"

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
echo if not defined mx for /f "tokens=3 delims= " %%%%a in ^('robocopy "%%~1" "%%TEMP%%" /S /L /BYTES /XJ /NFL /NDL /NJH /R:0 ^^^| find "Bytes"'^) do if %%%%a LEQ 1048576 ^(set "mx=-mx5"^) else set "mx=-mx9"
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

copy /y "%TEMP%\jai.bat" "%target_dir%\jai.bat" 1>nul
del /f "%TEMP%\jai.bat" 1>nul
copy /y "License.txt" "%target_dir%\License.txt" 1>nul
if defined x64suffix (set "x64infix=x64\") else set "x64infix="
copy /y "%x64infix%7za.exe" "%target_dir%\7za.exe" 1>nul
copy /y "%x64infix%7za.dll" "%target_dir%\7za.dll" 1>nul
copy /y "License-7z.txt" "%target_dir%\License-7z.txt" 1>nul

reg add "HKCU\SOFTWARE\JAI" /ve /d "Just Archive It v%rev%" /f 1>nul
reg add "HKCU\SOFTWARE\JAI" /v "Target" /d "%target_dir%" /f 1>nul
reg add "HKCU\SOFTWARE\JAI" /v "Amount" /d "%item_amount%" /f 1>nul
for /L %%i in (1,1,%item_amount%) do if defined item_%%i if defined item_%%i_opt if defined item_%%i_dest (
    reg add "%RegPath%\JAI_%%i" /ve /d "!item_%%i!" /f 1>nul
    reg add "%RegPath%\JAI_%%i\command" /ve /d "\"%jai_bat%\" noterm \"%%1\" \"!item_%%i_dest!\" !item_%%i_opt!" /f 1>nul
)

for /f "skip=2 tokens=1,2*" %%a in ('reg query "HKCU\Environment" /v "Path" 2^>NUL') do if /i "%%~a" == "path" set "UserPath=%%c"
setx PATH "%target_dir%;%UserPath%" 1>NUL

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
@REM %2: Section
@REM %3: Key
@REM %4: &Value
@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "file=%~1"
set "section=%~2"
set "key=%~3"
if not defined key exit /b 2
pushd %~dp0
if /i "%file:~-4%" NEQ ".ini" set "file=%file%.ini"
if not exist "%file%" exit /b 3
set activeSection=
for /f "usebackq delims=" %%a in ("%file%") do (
    set "line=%%~a"
    if "!line:~0,1!" == "[" (
        set "actSection=!line!"
    ) else (
        for /f "tokens=1,2 delims==" %%A in ("!line!") do (
            if /i "!actSection!" == "[%section%]" if /i "!key!" == "%%~A" (
                endlocal
                set "%~4=%%~B"
                exit /b 0
            )
        )
    )
)
set "%~4="
exit /b 1

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
