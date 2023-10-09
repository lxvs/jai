@echo off
setlocal
set p7za="%~dp07za.exe"

if "%~1" == "" (goto help)
if /i "%~1" == "/?" (goto help)
set pause=
if /i "%~1" == "--pause-when-error" (
    set "pause=pause"
    shift /1
)

if /i "%~1" == "--7z-help" (
    %p7za% --help
    %pause%
    exit /b
)

:preparamparse
set mx=
set flags_7z=
set target=
set dest=
set force=
set here=
set args=

:paramparse
if "%~1" == "" (goto postparamparse)
set "param=%~1"
if "%param%" == "/?" (
    goto help
) else if "%param:~0,1%" == "-" (
    if /i "%param:~0,3%" == "-mx" (
        set "mx=%param%"
    ) else if /i "%param%" == "-f" (
        set force=1
    ) else if /i "%param%" == "--force" (
        set force=1
    ) else if /i "%param%" == "--here" (
        set here=1
    ) else if /i "%param%" == "--in-place" (
        set here=1
    ) else if /i "%param%" == "--version" (
        goto Logo
    ) else if "%param%" == "-?" (
        goto help
    ) else if /i "%param%" == "-h" (
        goto help
    ) else if /i "%param%" == "--help" (
        goto help
    ) else if /i "%param%" == "--7z-help" (
        %p7za% --help
        %pause%
        exit /b
    ) else if "%param%" == "--" (
        shift /1
        goto skipswitches
    ) else (
        set "flags_7z=%flags_7z% %param%"
    )
) else (
    call:append_args "%~1"
)
shift /1
goto paramparse

:append_args
set "args=%args% %1"
exit /b

:skipswitches
if "%~1" == "" (goto postparamparse)
set "args=%args% %1"
shift /1
goto skipswitches

:postparamparse
if not defined mx (set "mx=-mx9")
call:parseargs %args% || goto errexit
if not defined target (
    >&2 echo error: TARGET not specified
    >&2 echo Try `jai --help' for more information
    goto errexit
)
if not exist "%target%" (
    call:err "error: TARGET `%target%' does not exist"
    goto errexit
)
if "%target:~-1%" == "\" (set "target=%target:~0,-1%")
if defined here (
    if defined dest (
        >&2 echo error: --here/--in-place and DESTINATION are both present
        >&2 echo Try `jai --help' for more information
        goto errexit
    )
    set "dest=%target_dir%"
) else if not defined dest (
    >&2 echo error: DESTINATION not specified
    >&2 echo Try `jai --help' for more information
    goto errexit
)
if "%dest:~-1%" == "\" (set "dest=%dest:~0,-1%")

if not exist "%dest%\%target_filename%.7z" (goto continue_already_existed)
if defined force (goto continue_already_existed)
set ow_confirm=
set /p "ow_confirm=%dest%\%target_filename%.7z has alredy existed. Enter Y to overwrite it: "
if /i "%ow_confirm%" == "y" (
    del /f "%dest%\%target_filename%.7z" || (
        goto errexit
    )
    goto continue_already_existed
) else (
    >&2 echo operation canceled
    goto errexit
)
:continue_already_existed

call:Logo
%p7za% a %flags_7z% %mx% -- "%dest%\%target_filename%.7z" "%target%" || (goto errexit)
exit /b

:help
@echo usage: jai.bat [SWITCHES] [--] TARGET DESTINATION
@echo;
@echo Comparess TARGET using 7-Zip and copy/move compressed archive into directory DESTINATION.
@echo;
@echo     -h, --help              show help and exit
@echo     --version               show version and exit
@echo     --7z-help               show help of 7-Zip and exit
@echo     -f, --force             overwrite quietly
@echo     --here, --in-place      compress in place
@echo     --pause-when-error      when error occurs, pause before exiting
@echo;
@echo 7-Zip switches:
@echo     -mx[N] : set compression level: -mx1 ^(fastest^) ... -mx9 ^(ultra^)
@echo     -p{Password} : set Password
@echo     -sdel : delete files after compression
@echo     -sse : stop archive creating, if it can't open some input file
@echo     -stl : set archive timestamp from the most recently modified file
@echo;
@echo     Try `jai --7z-help' for more information.
exit /b

:parseargs
if %1. == . (exit /b)
if not defined target (
    set "target=%~1"
    call:GetDirAndName "%~1" target_dir target_filename
    shift /1
    goto parseargs
)
if not defined dest (
    pushd "%~1" 1>nul 2>&1 && (
        set "dest=%~1"
        popd
    ) || (
        call:err "error: `%~1' does not exist or is not a directory"
        exit /b 1
    )
    shift /1
    goto parseargs
)
>&2 echo error: invalid argument `%~1'
exit /b 1

:GetDirAndName
set "gdan_path=%~1"
if "%gdan_path:~-1%" NEQ "\" (
    set "%2=%~dp1"
    set "%3=%~nx1"
    exit /b
)
set "gdan_path=%gdan_path:~0,-1%"
call:GetDirAndName "%gdan_path%" %2 %3
exit /b

:Logo
@echo;
@echo     Just Archive It 0.8.0
@echo     Date: 2023-07-25
@echo     https://github.com/lxvs/jai
exit /b

:err
if %1. == . (exit /b 1)
>&2 echo %~1
shift /1
goto err

:errexit
%pause%
exit /b 1
