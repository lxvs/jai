@echo off
setlocal
title Just Archive It Uninstallation
set version=
set target_dir=
set item_amount=
set UserPath=
call:GetReg "HKCU\Software\jai" "version" version
@echo;
@echo     Uninstalling JAI %version%
@echo;
call:GetReg "HKCU\Software\jai" "target" target_dir
call:GetReg "HKCU\Environment" "Path" UserPath
setlocal EnableDelayedExpansion
if defined UserPath setx PATH "!UserPath:%target_dir%;=!" 1>nul
endlocal

if exist "%target_dir%" (
    1>nul (
        del "%target_dir%\jai.bat"
        del "%target_dir%\7za.exe"
        del "%target_dir%\7za.dll"
        del "%target_dir%\License.txt"
        del "%target_dir%\License-7z.txt"
        rmdir "%target_dir%" 2>&1
        reg delete "HKCU\Software\jai" /f
    )
)


call:GetReg "HKCU\Software\jai" "amount" item_amount
set /a "item_amount=item_amount"
set "RegShell=HKCU\Software\Classes\Directory\shell"
if %item_amount% GTR 0 (
    for /L %%i in (1,1,%item_amount%) do 1>nul reg delete "%RegShell%\jai_%%i" /f
)
@echo Complete.
pause
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
