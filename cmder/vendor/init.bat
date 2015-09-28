:: Init Script for cmd.exe
:: Sets some nice defaults
:: Created as part of cmder project

:: Find root dir
@if not defined CMDER_ROOT (
    for /f "delims=" %%i in ("%ConEmuDir%\..\..") do @set CMDER_ROOT=%%~fi
)

:: Find wagon dir
@if not defined WAGON_ROOT (
    for /f %%i in ("%ConEmuDir%\..\..\..") do @set WAGON_ROOT=%%~fi
)

:: Change the prompt style
:: Mmm tasty lamb
@prompt $E[1;32;40m$P$S{git}{hg}$S$_$E[1;30;40m{lamb}$S$E[0m

:: Pick right version of clink
@if "%PROCESSOR_ARCHITECTURE%"=="x86" (
    set architecture=86
) else (
    set architecture=64
)

:: Run clink
@"%CMDER_ROOT%\vendor\clink\clink_x%architecture%.exe" inject --quiet --profile "%CMDER_ROOT%\config"

:: Prepare for msysgit

:: I do not even know, copypasted from their .bat
@set PLINK_PROTOCOL=ssh
@if not defined TERM set TERM=cygwin

:: Check if msysgit is installed
@if exist "%ProgramFiles%\Git" (
    set "GIT_INSTALL_ROOT=%ProgramFiles%\Git"
) else if exist "%ProgramFiles(x86)%\Git" (
    set "GIT_INSTALL_ROOT=%ProgramFiles(x86)%\Git"
) else if exist "%CMDER_ROOT%\vendor" (
    set "GIT_INSTALL_ROOT=%CMDER_ROOT%\vendor\msysgit"
)

:: Add git to the path
@if defined GIT_INSTALL_ROOT (
    set "PATH=%GIT_INSTALL_ROOT%\bin;%GIT_INSTALL_ROOT%\share\vim\vim74;%PATH%"
    :: define SVN_SSH so we can use git svn with ssh svn repositories
    if not defined SVN_SSH set "SVN_SSH=%GIT_INSTALL_ROOT:\=\\%\\bin\\ssh.exe"
)

:: Enhance Path
@set CMDER_START=%WAGON_ROOT%\uwamp\www
@set COMPOSER_HOME=%WAGON_ROOT%\composer
@set git_install_root=%WAGON_ROOT%\git
@set php_install_root=%WAGON_ROOT%\uwamp\bin\php\php-5.6.12-Win32-VC11-x86
@set seven_zip_root=%CMDER_ROOT%\vendor\7za920
@set sqlite_root=%CMDER_ROOT%\vendor\sqlite
@set PATH=%CMDER_ROOT%\bin;%php_install_root%;%COMPOSER_HOME%;%COMPOSER_HOME%\vendor\bin;%seven_zip_root%;%sqlite_root%;%git_install_root%\bin;%git_install_root%\mingw\bin;%git_install_root%\cmd;%git_install_root%\share\vim\vim74;%CMDER_ROOT%;%PATH%

:: Add aliases
@doskey /macrofile="%CMDER_ROOT%\config\aliases"

:: Set home path
@if not defined HOME set HOME=%USERPROFILE%

@if defined CMDER_START (
    @cd /d "%CMDER_START%"
) else (
    @if "%CD%\" == "%CMDER_ROOT%" (
        @cd /d "%HOME%"
    )
)

:: @call "%CMDER_ROOT%/bin/agent.cmd"
