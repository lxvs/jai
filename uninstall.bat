@echo off
setlocal
set silent=
if "%~1" == "--silent" (set silent=1)
title Just Archive It Uninstallation
set version=
set target_dir=
set item_amount=
set filetype=
set UserPath=
set "regPathSoftware=HKCU\Software\lzhh\jai"
call:GetReg "%regPathSoftware%" "Version" version
call:GetReg "%regPathSoftware%" "Target" target_dir
if not defined version if not defined target_dir if not defined silent (
    >&2 echo warning: no installation found
    set silent=1
)
if not defined silent (
    @echo Uninstalling JAI %version% installed at `%target_dir%'
)

:start
call:GetReg "HKCU\Environment" "Path" UserPath
setlocal EnableDelayedExpansion
if defined UserPath (
    if defined target_dir (
        if defined silent (
            setx Path "!UserPath:%target_dir%;=!" 1>nul 2>&1
        ) else (
            setx Path "!UserPath:%target_dir%;=!" 1>nul
        )
    )
)
endlocal

if exist "%target_dir%" (
    1>nul 2>&1 (
        del "%target_dir%\jai.bat"
        del "%target_dir%\7za.exe"
        del "%target_dir%\7za.dll"
        del "%target_dir%\License.txt"
        del "%target_dir%\License-7z.txt"
        rmdir "%target_dir%"
    )
)

call:GetReg "%regPathSoftware%" "Amount" item_amount
call:GetReg "%regPathSoftware%" "FileTypes" filetype
set /a "item_amount=item_amount"
set "regPathDir=HKCU\Software\Classes\Directory\shell"
set "regPathDirBg=HKCU\Software\Classes\Directory\Background\shell"
set "regPathFileType=HKCU\Software\Classes\SystemFileAssociations\.$$FileType$$\shell"
setlocal enableDelayedExpansion
if %item_amount% GTR 0 (
    for /L %%i in (1,1,%item_amount%) do (
        reg delete "%regPathDir%\jai_%%i" /f 1>nul 2>&1
        reg delete "%regPathDirBg%\jai_%%i" /f 1>nul 2>&1
        for %%j in (%filetype%) do (
            reg delete "!regPathFileType:$$FileType$$=%%~j!\jai_%%i" /f 1>nul 2>&1
        )
    )
)
endlocal
if defined silent (
    reg delete "%regPathSoftware%" /f 1>nul 2>&1
) else (
    reg delete "%regPathSoftware%" /f 1>nul
    @echo Complete.
    pause
)
exit /b

:GetReg
@REM Path "name"|/ve &variable
if "%~2" == "/ve" (
    set "GetReg_switch=/ve"
    set "GetReg_key="
    set "GetReg_name=(default)"
) else (
    set "GetReg_switch=/v"
    set "GetReg_key=%~2"
    set "GetReg_name=%~2"
)
for /f "skip=2 tokens=1,2*" %%a in ('reg query "%~1" %GetReg_switch% %GetReg_key% 2^>NUL') do if /i "%%~a" == "%GetReg_name%" set "%3=%%c"
exit /b
