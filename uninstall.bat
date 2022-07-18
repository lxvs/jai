@echo off
setlocal
set silent=
if "%~1" == "--silent" (set silent=1)
title Just Archive It Uninstallation
set version=
set target_dir=
set item_amount=
set UserPath=
set "regPathSoftware=HKCU\Software\lxvs\jai"
call:GetReg "%regPathSoftware%" "version" version
call:GetReg "%regPathSoftware%" "target" target_dir
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
    if defined silent (
        setx PATH "!UserPath:%target_dir%;=!" 1>nul 2>&1
    ) else (
        setx PATH "!UserPath:%target_dir%;=!" 1>nul
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

call:GetReg "%regPathSoftware%" "amount" item_amount
set /a "item_amount=item_amount"
set "RegShell=HKCU\Software\Classes\Directory\shell"
if %item_amount% GTR 0 (
    for /L %%i in (1,1,%item_amount%) do (
        if defined silent (
            reg delete "%RegShell%\jai_%%i" /f 1>nul 2>&1
        ) else (
            reg delete "%RegShell%\jai_%%i" /f 1>nul
        )
    )
)
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
