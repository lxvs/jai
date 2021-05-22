@setlocal
@set "rev=0.1.0"
@set "lastupdt=2021-05-22"

@echo;
@echo     Just Archive It v%rev%
@echo     https://github.com/lxvs/jai
@echo     Last Update: %lastupdt%
@echo;

@if /i "%~1" == "/?" goto help
@if /i "%~1" == "noterm" (
    @set "pause=@pause"
    @title Just Archive It v%rev%
    @shift
) else @set "pause="

@if not defined PATH_TO_7Z set "PATH_TO_7Z=%PROGRAMFILES%\7-Zip\7z.exe"

@if not exist "%PATH_TO_7Z%" (
    @>&2 (
        echo JAI: ERROR: Couldn't find valid 7z executable.
        echo      Current defined PATH_TO_7Z: %PATH_TO_7Z%
        echo      Please fix or define the Environment Variable [PATH_TO_7Z]
    )
    %pause%
    exit /b 3
)

@if /i "%~1" == "/7z" (
    "%PATH_TO_7Z%"
    %pause%
    @exit /b
)

@set "target=%~1"
@set "target_filename=%~nx1"
@set "target_dir=%~dp1"
@shift

@if "%target%" == "" (
    @>&2 echo JAI: ERROR: no target provided.
    @>&2 call:HELP
    %pause%
    exit /b 1
)

@if not exist "%target%" (
    @>&2 echo JAI: ERROR: the target provided is invalid.
    @>&2 call:HELP
    %pause%
    exit /b 2
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
        %pause%
        @exit /b
    ) else (
        @>&2 echo JAI: ERROR: invalid switch: %param%.
        %pause%
        exit /b 4
    )

) else (
    pushd "%param%" 1>nul 2>&1 && (
        @set "archive_dir=%param%"
        @popd
    ) || (
        @>&2 echo JAI: ERROR: %param% does not exist or is not a directory.
        %pause%
        exit /b 5
    )
)

@shift
@goto paramparse

:postparamparse

@if not defined archive_dir (
    @>&2 echo JAI: ERROR: archive directory is not specified.
    @>&2 call:Help
    %pause%
    exit /b 9
)

@if not exist "%archive_dir%\%target_filename%.7z" goto continue_already_existed
@if defined overwrite goto continue_already_existed
@set ow_confirm=
@set /p "ow_confirm=JAI: %archive_dir%\%target_filename%.7z has alredy existed. Enter Y to overwrite it:"
@if /i "%ow_confirm%" == "y" (
    del /f "%archive_dir%\%target_filename%.7z" || (
        %pause%
        exit /b 6
    )
    goto continue_already_existed
) else (
    @>&2 echo JAI: ABORT: user canceled.
    %pause%
    exit /b 7
)
:continue_already_existed

@if not defined mx @for /f "tokens=3 delims= " %%a in ('robocopy "%~1" "%TEMP%" /S /L /BYTES /XJ /NFL /NDL /NJH /R:0 ^| find "Bytes"') do @if %%a LEQ 1048576 (set "mx=-mx5") else set "mx=-mx9"

@"%PATH_TO_7Z%" a %args% %mx% "%archive_dir%\%target_filename%.7z" "%target%" || (
    %pause%
    @exit /b
)

@if not exist "%archive_dir%\%target_filename%.7z" (
    @>&2 echo JAI: Warning: %archive_dir%\%target_filename%.7z still not exist!
    %pause%
    exit /b 8
)

@exit /b

:HELP
@echo USAGE:
@echo;
@echo jai.bat ^<target^> ^<archive-directory^> [/?] [/o] [/7z] [^<7z options^> ...]
@echo;
@echo         ^<target^>                The directory to be archived
@echo         ^<archive-directory^>     Where archives go.
@echo                                 /here means the same location as ^<target^>.
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
