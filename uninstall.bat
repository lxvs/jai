@REM Just Archive It Uninstallation
@REM https://github.com/lxvs/jai

@echo off
setlocal

set name=jsa
set regpath=HKCU\Software\lxvs\jai
set silent=
set term=
set install=
set exitcode=0
:parseargs
if %1. == . (goto endparseargs)
set term=1
if /i "%~1" == "--silent" (
    set silent=1
    shift /1
    goto parseargs
)
if /i "%~1" == "--install" (
    set install=1
    shift /1
    goto parseargs
)
if "%~1" == "/?" (goto help)
if "%~1" == "-?" (goto help)
if /i "%~1" == "-h" (goto help)
if /i "%~1" == "--help" (goto help)
>&2 echo error: invalid argument `%~1'
>&2 echo Try `uninstall.bat --help' for more information.
exit /b 1
:endparseargs

if defined install (
    if not defined silent (
        call %~dp0install.bat
    ) else (
        call %~dp0install.bat --silent
    )
    exit /b
)
call:getreg "HKCU\Environment" "Path" UserPath
call:getreg "%regpath%" "path" installation
call:getreg "%regpath%" "amount" item_amount
call:getreg "%regpath%" "filetype" filetype
setlocal EnableDelayedExpansion
if defined UserPath (
    if not defined silent (
        if defined installation (
            setx Path "!UserPath:%installation%;=!" 1>nul
        ) else (
            >&2 echo warning: no installation found; try to uninstall anyway
        )
        reg delete "%regpath%" /f 1>nul
        reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\%name%.exe" /f 1>nul
    ) else (
        if defined installation (setx Path "!UserPath:%installation%;=!" 1>nul 2>&1)
        reg delete "%regpath%" /f 1>nul 2>&1
        reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\%name%.exe" /f 1>nul 2>&1
    )
) else (
    if not defined silent (
        >&2 echo error: failed to get user Path
    )
    set exitcode=1
    goto end
)
endlocal

if exist "%installation%" (
    1>nul 2>&1 (
        del "%installation%\jai.bat"
        del "%installation%\7za.exe"
        del "%installation%\7za.dll"
        del "%installation%\License.txt"
        del "%installation%\License-7z.txt"
        rmdir "%installation%"
    )
)

set /a "item_amount=item_amount"
set "regPathDir=HKCU\Software\Classes\Directory\shell"
set "regPathDirBg=HKCU\Software\Classes\Directory\Background\shell"
set "regPathFileType=HKCU\Software\Classes\SystemFileAssociations\.$$FileType$$\shell"
setlocal enableDelayedExpansion
if %item_amount% GTR 0 (
    for /l %%i in (1,1,%item_amount%) do (
        reg delete "%regPathDir%\jai_%%i" /f 1>nul 2>&1
        reg delete "%regPathDirBg%\jai_%%i" /f 1>nul 2>&1
        for %%j in (%filetype%) do (
            reg delete "!regPathFileType:$$FileType$$=%%~j!\jai_%%i" /f 1>nul 2>&1
        )
    )
)
endlocal

if not defined silent (echo Uninstall complete.)
goto end

:getreg
set %3=
set getregretval=
if /i "%~2" == "/ve" (
    set getreg_switch=/ve
    set getreg_key=
    set "getreg_name=(Default)"
) else (
    set getreg_switch=/v
    set getreg_key="%~2"
    set "getreg_name=%~2"
)
for /f "skip=2 tokens=1* delims=" %%a in ('reg query "%~1" %getreg_switch% %getreg_key% 2^>nul') do (
    call:getregparse "%%~a"
)
if defined getregretval (set "%3=%getregretval%")
exit /b

:getregparse
if "%~1" == "" (exit /b 1)
set "getregparse_str=%~1"
set "getregparse_str=%getregparse_str:    =	%
for /f "tokens=1,2* delims=	" %%A in ("%getregparse_str%") do (
    if /i "%getreg_name%" == "%%~A" (set "getregretval=%%~C")
)
exit /b

:help
echo usage: uninstall.bat
echo    or: uninstall.bat --silent
echo    or: uninstall.bat --install
exit /b 0

:end
if not defined term (pause)
exit /b %exitcode%
