:: use this file to run your own startup commands
:: use  in front of the command to prevent printing the command

:: call "%GIT_INSTALL_ROOT%/cmd/start-ssh-agent.cmd"
:: set "PATH=%CMDER_ROOT%\vendor\whatever;%PATH%"

:: Find wagon dir
if not defined WAGON_ROOT (
    for /f "delims=" %%i in ("%ConEmuDir%\..\..\..") do set "WAGON_ROOT=%%~fi"
)

:: Define environment variables
set CMDER_START=%WAGON_ROOT%\uwamp\www
set COMPOSER_HOME=%WAGON_ROOT%\composer
set PHP_INSTSLL_ROOT=%WAGON_ROOT%\uwamp\bin\php\php-7.1.10
set SQLITE_ROOT=%CMDER_ROOT%\vendor\sqlite
set GIT_INSTALL_ROOT=%WAGON_ROOT%\git

:: Set PATH
set PATH=%PHP_INSTSLL_ROOT%;%COMPOSER_HOME%;%COMPOSER_HOME%\vendor\bin;%SQLITE_ROOT%;%CMDER_ROOT%\bin;%CMDER_ROOT%;%PATH%
set PATH=%GIT_INSTALL_ROOT%\bin;%GIT_INSTALL_ROOT%\usr\bin;%GIT_INSTALL_ROOT%\share\vim\vim74;%PATH%

:: Change default working directory
if defined CMDER_START (
    cd /d "%CMDER_START%"
)
