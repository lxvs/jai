@setlocal EnableExtensions EnableDelayedExpansion

@REM ======================================================================

@set /a "item_amount=4"

@set "item_1=Archive It (&A)"
@set "item_1_options=-sse -sdel -stl"
@set "item_1_destination=%USERPROFILE%\Documents"

@set "item_2=Archive It Here (&Z)"
@set "item_2_options=-sse -sdel -stl"
@set "item_2_destination=/here"

@set "item_3=Archive It Here (duplicate) (&Q)"
@set "item_3_options=-sse -stl"
@set "item_3_destination=/here"

@set "item_4=Archive It With a Password (EXAMPLE123) (&X)"
@set "item_4_options=-sse -sdel -stl -pEXAMPLE123"
@set "item_4_destination=%USERPROFILE%\Documents"

@REM =======================================================================

@set "jai_bat=%~dp0"
@if "%jai_bat:~-1%" == "\" (
    @set "jai_bat=%jai_bat%jai.bat"
) else (
    @set "jai_bat=%jai_bat%\jai.bat"
)

@echo;
@echo     Just Archive It Installation
@echo;

@if not exist "%jai_bat%" (
    @>&2 echo ERROR: Coundn't found jai.bat ^(%jai_bat%^)
    @pause
    exit /b 1
)

@echo This script is used to add JAI ^(Just Archive It^) to right-click context
@echo menus of directories.
@echo;
@echo By entering Y, you mean to add such items:
@echo;

@if not defined item_amount (
    @>&2 echo ERROR: item_amount is not defined!
    @pause
    exit /b 2
)

@for /L %%i in (1,1,%item_amount%) do @if defined item_%%i if defined item_%%i_options if defined item_%%i_destination (
    @echo     item %%i:                 !item_%%i!
    @echo     item %%i options:         !item_%%i_options!
    @echo     item %%i destination:     !item_%%i_destination!
    @echo;
)

@echo If not, enter N and edit this script with a text editor.
@echo;
@set /p "confirm=Please confirm your decision (Y/N): "
@echo;

@if /i not "%confirm%" == "Y" (
    @exit /b
)

@for /L %%i in (1,1,%item_amount%) do @if defined item_%%i if defined item_%%i_options if defined item_%%i_destination (
    @reg add "HKEY_CLASSES_ROOT\Directory\shell\jai_%%i" /ve /d "!item_%%i!" /f || (
        @>&2 echo ERROR: failed to add the registry item!
        @>&2 echo        please run this script as administrator.
        @pause
        exit /b 3
    )
    @reg add "HKEY_CLASSES_ROOT\Directory\shell\jai_%%i\command" /ve /d "\"%jai_bat%\" \"%%1\" \"!item_%%i_destination!\" !item_%%i_options!" /f
)

@echo Complete.
@pause
@exit /b
