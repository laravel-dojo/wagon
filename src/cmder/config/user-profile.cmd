:: use this file to run your own startup commands
:: use  in front of the command to prevent printing the command

:: call "%GIT_INSTALL_ROOT%/cmd/start-ssh-agent.cmd"
:: set "PATH=%CMDER_ROOT%\vendor\whatever;%PATH%"

:: Find wagon dir
if not defined WAGON_ROOT (
    for /f "delims=" %%i in ("%ConEmuDir%\..\..\..") do set "WAGON_ROOT=%%~fi"
)

:: Define git variable and PATCH
set GIT_INSTALL_ROOT=%WAGON_ROOT%\git
set PATH=%GIT_INSTALL_ROOT%\bin;%GIT_INSTALL_ROOT%\usr\bin;%GIT_INSTALL_ROOT%\share\vim\vim74;%PATH%

:: Parse PHP version
FOR /F "tokens=*" %%A IN ('type "%WAGON_ROOT%\uwamp\uwamp.ini" ^| tr -d " "') DO SET %%A

:: Define PHP Composer SQLite variables
set CMDER_START=%WAGON_ROOT%\uwamp\www
set COMPOSER_HOME=%WAGON_ROOT%\composer
set PHP_INSTSLL_ROOT=%WAGON_ROOT%\uwamp\bin\php\php-7.3.11
set SQLITE_ROOT=%CMDER_ROOT%\vendor\sqlite

:: Set PHP Composer SQLite PATH
set PATH=%PHP_INSTSLL_ROOT%;%COMPOSER_HOME%;%COMPOSER_HOME%\vendor\bin;%SQLITE_ROOT%;%CMDER_ROOT%\bin;%CMDER_ROOT%;%PATH%

:: Change default working directory
if defined CMDER_START (
    cd /d "%CMDER_START%"
)
