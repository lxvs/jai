@echo off
setlocal EnableExtensions EnableDelayedExpansion
@REM ======================================================================
@REM Customization starts

set /a "item_amount=4"

set "item_1=Archive It (&A)"
set "item_1_options=-sse -sdel -stl"
set "item_1_destination=%USERPROFILE%\Documents"

set "item_2=Archive It Here (&Z)"
set "item_2_options=-sse -sdel -stl"
set "item_2_destination=/here"

set "item_3=Archive It Here (duplicate) (&Q)"
set "item_3_options=-sse -stl"
set "item_3_destination=/here"

set "item_4=Archive It With a Password (EXAMPLE123) (&X)"
set "item_4_options=-sse -sdel -stl -pEXAMPLE123"
set "item_4_destination=%USERPROFILE%\Documents"

set "target_dir=%USERPROFILE%\jai"

@REM Customization ends
@REM =======================================================================
if "%target_dir:~-1%" == "\" set "target_dir=%target_dir:~0,-1%"
set "jai_bat=%target_dir%\jai.bat"
set x64suffix=
if /i "%~1" == "x64" set "x64suffix= (x64)"
set "RegPath=HKCU\SOFTWARE\Classes\Directory\shell"
set "rev=0.3.0"
set "lastupdt=2021-07-08"
set "website=https://lxvs.net/jai"

@echo;
@echo     Just Archive It v%rev%%x64suffix% Installation
@echo     %website%
@echo     Last updated: %lastupdt%
@echo;

pushd %~dp0

call:Assert "defined item_amount" ^
    "ERROR: Item Amount is not defined." || exit /b 4
call:Assert "%%item_amount%% GTR 0" ^
    "ERROR: Item Amount must be greater than 0." || exit /b 5

@echo This script is used to add JAI ^(Just Archive It^) to right-click context
@echo menus of directories.
@echo;
@echo By entering Y, you mean to add such items:
@echo;

for /L %%i in (1,1,%item_amount%) do if defined item_%%i if defined item_%%i_options if defined item_%%i_destination (
    @echo     item %%i:                 !item_%%i!
    @echo     item %%i options:         !item_%%i_options!
    @echo     item %%i destination:     !item_%%i_destination!
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
for /L %%i in (1,1,%item_amount%) do if defined item_%%i if defined item_%%i_options if defined item_%%i_destination (
    reg add "%RegPath%\JAI_%%i" /ve /d "!item_%%i!" /f 1>nul
    reg add "%RegPath%\JAI_%%i\command" /ve /d "\"%jai_bat%\" noterm \"%%1\" \"!item_%%i_destination!\" !item_%%i_options!" /f 1>nul
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

:Assert
if "%~1" == "" exit /b 1
if %~1 exit /b 0
:assert_echo
if "%~2" NEQ "" >&2 echo %~2
shift /2
if "%~2" NEQ "" goto assert_echo
popd
pause
exit /b 1
