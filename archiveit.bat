@setlocal
@set "rev=0.0.2"
@set "lastupdt=2021-05-20"

@if /i "%~1" == "/?" goto help
@if /i "%~1" == "/7z" if exist "%PATH_TO_7Z%" (
    "%PATH_TO_7Z%"
    exit /b
)

@set "target=%~1"
@set "target_filename=%~nx1"
@set "target_dir=%~dp1"
@shift

@if "%target%" == "" (
    @>&2 echo ARCHIVEIT: ERROR: no target provided.
    @>&2 call:HELP
    exit /b 1
)

@if not exist "%target%" (
    @>&2 echo ARCHIVEIT: ERROR: the target provided is invalid.
    @>&2 call:HELP
    exit /b 2
)

@if not defined PATH_TO_7Z set "PATH_TO_7Z=%PROGRAMFILES%\7-Zip\7z.exe"
@if not exist "%PATH_TO_7Z%" (
    @>&2 (
        echo ARCHIVEIT: ERROR: Couldn't find valid 7z executable.
        echo            Current defined PATH_TO_7Z: %PATH_TO_7Z%
        echo            Please fix or define the Environment Variable [PATH_TO_7Z]
    )
    exit /b 3
)

:preparamparse
@set "mx="
@set "args="
@set "archive_dir="
@set "overwrite="

:paramparse
@if "%~1" == "" goto postparamparse
@set "param=%~1"
@if "%param:~0,1%" == "-" (
    if /i "%param:~0,3%" == "-mx" (
        @set "mx=%param%"
    ) else @set "args=%args% %param%"

) else if "%param:~0,1%" == "/" (
    if /i "%param%" == "/o" (
        @set "overwrite=1"
    ) else if /i "%param%" == "/here" (
        @set "archive_dir=%target_dir%"
    ) else if /i "%param%" == "/?" (
        @goto HELP
    ) else if /i "%param%" == "/7z" (
        @"%PATH_TO_7Z%"
        @exit /b
    ) else (
        @>&2 echo ARCHIVEIT: ERROR: invalid switch: %param%.
        exit /b 4
    )

) else (
    pushd "%param%" 1>nul 2>&1 && (
        @set "archive_dir=%param%"
        @popd
    ) || (
        @>&2 echo ARCHIVEIT: ERROR: %param% does not exist or is not a directory.
        exit /b 5
    )
)

@if not defined archive_dir (
    @>&2 echo ARCHIVEIT: ERROR: archive directory is not specified.
    @>&2 call:Help
    exit /b 9
)

@shift
@goto paramparse
    
:postparamparse

@if not exist "%archive_dir%\%target_filename%.7z" goto continue_already_existed
@if defined overwrite goto continue_already_existed
@set ow_confirm=
@set /p "ow_confirm=ARCHIVEIT: %archive_dir%\%target_filename%.7z has alredy existed. Enter Y to overwrite it:"
@if /i "%ow_confirm%" == "y" (
    del /f "%archive_dir%\%target_filename%.7z" || exit /b 6
    goto continue_already_existed
) else (
    @>&2 echo ARCHIVEIT: ABORT: user canceled.
    exit /b 7
)
:continue_already_existed

@if not defined mx @for /f "tokens=3 delims= " %%a in ('robocopy "%~1" "%TEMP%" /S /L /BYTES /XJ /NFL /NDL /NJH /R:0 ^| find "Bytes"') do @if %%a LEQ 1048576 (set "mx=-mx5") else set "mx=-mx9"

@"%PATH_TO_7Z%" a %args% %mx% "%archive_dir%\%target_filename%.7z" "%target%" || exit /b

@if not exist "%archive_dir%\%target_filename%.7z" (
    @>&2 echo ARCHIVEIT: Warning: %archive_dir%\%target_filename%.7z still not exist!
    exit /b 8
)

@exit /b

:HELP
@echo;
@echo     Just Archive It v%rev%
@echo     https://lxvs.net/jai
@echo     Last Update: %lastupdt%
@echo;
@echo USAGE:
@echo;
@echo archiveit.bat ^<target^> ^<archive-directory^> [/?] [/o] [/7z] [^<7z options^> ...]
@echo;
@echo Switches:
@echo(        /?  show help
@echo         /o  overwrite the archive with the same name, without prompts.
@echo             By default, it will prompt user whether to overwrite or not.
@echo         /7z Show 7z's help
@echo;
@echo 7Z options:
@echo         -mx[N] : set compression level: -mx1 ^(fastest^) ... -mx9 ^(ultra^)
@echo         -p{Password} : set Password
@echo         -sdel : delete files after compression
@echo         -sse : stop archive creating, if it can't open some input file
@echo         -stl : set archive timestamp from the most recently modified file
@echo;
@echo         Use '%~nx0 /7z' for complete 7z option list.
@exit /b
