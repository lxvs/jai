@echo off
setlocal EnableExtensions EnableDelayedExpansion
pushd "%~dp0"

set x64suffix=
if /i "%~1" == "x64" (set "x64suffix= (x64)")
set "rev=0.8.1"
set "lastupdt=2023-10-09"
set "website=https://github.com/lxvs/jai"
set "regPathDir=HKCU\Software\Classes\Directory\shell"
set "regPathDirBg=HKCU\Software\Classes\Directory\Background\shell"
set "regPathFileType=HKCU\Software\Classes\SystemFileAssociations\.$$FileType$$\shell"

call:Logo
call:Assert "exist jai.bat" "error: jai.bat not found" || exit /b
call:ReadConf || (
    >&2 echo error: error reading file `install.ini'
    goto errexit
)
call:Assert "defined Config_TargetDirectory" "error: `target directory' not defined" || exit /b
call:Assert "defined Config_ItemAmount" "error: `item amount' not defined" || exit /b
call:Assert "%%Config_ItemAmount%% GTR 0" "error: `item amount' must be greater than 0" || exit /b
if defined Config_DirMenu (
    set /a Config_DirMenu=Config_DirMenu
) else (
    set Config_DirMenu=1
)
if defined Config_DirBackgroundMenu (
    set /a Config_DirBackgroundMenu=Config_DirBackgroundMenu
) else (
    set Config_DirBackgroundMenu=1
)
if not defined Config_FileType (set Config_FileType=txt,log)
set "Config_FileType=%Config_FileType:,= %"

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
@echo If not, enter N and write modifications in `install.custom.ini'.
@echo Items defined in `install.custom.ini' will overwrite ones of the same name in `install.ini'.
@echo;
set /p "confirm=Please confirm your decision (Y/N): "

if /i not "%confirm%" == "Y" (
    popd
    exit /b
)

call uninstall.bat --silent

if not exist "%Config_TargetDirectory%" (md "%Config_TargetDirectory%")

if defined x64suffix (set "x64infix=x64\") else (set x64infix=)
set "regPathSoftware=HKCU\Software\lxvs\jai"
1>nul (
    copy /y "jai.bat" "%Config_TargetDirectory%\jai.bat"
    copy /y "License.txt" "%Config_TargetDirectory%\License.txt"
    copy /y "%x64infix%7za.exe" "%Config_TargetDirectory%\7za.exe"
    copy /y "%x64infix%7za.dll" "%Config_TargetDirectory%\7za.dll"
    copy /y "License-7z.txt" "%Config_TargetDirectory%\License-7z.txt"
    reg add "%regPathSoftware%" /v "Version" /d "%rev%" /f
    reg add "%regPathSoftware%" /v "Target" /d "%Config_TargetDirectory%" /f
    reg add "%regPathSoftware%" /v "Amount" /d "%Config_ItemAmount%" /f
    reg add "%regPathSoftware%" /v "FileTypes" /d "%Config_FileType%" /f
    for /L %%i in (1,1,%Config_ItemAmount%) do if defined item_%%i if defined Item%%i_Options if defined Item%%i_Destination (
        if "%Config_DirMenu%" NEQ "0" (
            reg add "%regPathDir%\jai_%%i" /ve /d "!item_%%i!" /f
            reg add "%regPathDir%\jai_%%i\command" /ve /d "\"%jai_bat%\" --pause-when-error \"%%1\" \"!Item%%i_Destination!\" !Item%%i_Options!" /f
        )
        if "%Config_DirBackgroundMenu%" NEQ "0" (
            reg add "%regPathDirBg%\jai_%%i" /ve /d "!item_%%i!" /f
            reg add "%regPathDirBg%\jai_%%i\command" /ve /d "\"%jai_bat%\" --pause-when-error \"%%1\" \"!Item%%i_Destination!\" !Item%%i_Options!" /f
        )
        for %%j in (%Config_FileType%) do (
            reg add "!regPathFileType:$$FileType$$=%%~j!\jai_%%i" /ve /d "!item_%%i!" /f
            reg add "!regPathFileType:$$FileType$$=%%~j!\jai_%%i\command" /ve /d "\"%jai_bat%\" --pause-when-error \"%%1\" \"!Item%%i_Destination!\" !Item%%i_Options!" /f
        )
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
call:_ReadConf "install.ini" || exit /b
call:_ReadConf "install.custom.ini" || exit /b 0
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
