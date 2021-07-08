@echo off
setlocal
title Just Archive It Uninstallation
set "product="
set "target_dir="
set "item_amount="
set "UserPath="
call:GetReg "HKCU\SOFTWARE\JAI" /ve product
if not defined product (
    >&2 echo Couldn't detect any installed Just Archive It.
    >&2 echo Re-install it and try again.
    pause
    exit /b 1
)
title %product% Uninstallation
@echo;
@echo     %product% Uninstallation
@echo;
call:GetReg "HKCU\SOFTWARE\JAI" "Target" target_dir
call:GetReg "HKCU\SOFTWARE\JAI" "Amount" item_amount
call:GetReg "HKCU\Environment" "Path" UserPath
setlocal EnableDelayedExpansion
if defined UserPath setx PATH "!UserPath:%target_dir%;=!" 1>nul
endlocal

if exist "%target_dir%" (
    1>nul del /f "%target_dir%\jai.bat"
    1>nul del /f "%target_dir%\7za.exe"
    1>nul del /f "%target_dir%\7za.dll"
    1>nul del /f "%target_dir%\License.txt"
    1>nul del /f "%target_dir%\License-7z.txt"
    rmdir "%target_dir%" 1>nul 2>&1
) else (
    >&2 echo Warning: %target_dir% does not exist!
)

1>nul reg delete "HKCU\SOFTWARE\JAI" /f

set /a "item_amount=item_amount"
if %item_amount% LEQ 0 (
    >&2 echo Warning: item_amount should greater than 0!
    goto AmountLeq0
)
set "RegShell=HKCU\SOFTWARE\Classes\Directory\shell"
for /L %%i in (1,1,%item_amount%) do 1>nul reg delete "%RegShell%\JAI_%%i" /f
:AmountLeq0
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
