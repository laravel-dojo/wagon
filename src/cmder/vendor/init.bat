@echo off

set CMDER_INIT_START=%time%

:: Init Script for cmd.exe
:: Created as part of cmder project

:: !!! THIS FILE IS OVERWRITTEN WHEN CMDER IS UPDATED
:: !!! Use "%CMDER_ROOT%\config\user_profile.cmd" to add your own startup commands

:: Use /v command line arg or set to > 0 for verbose output to aid in debugging.
if not defined verbose_output set verbose_output=0

:: Use /d command line arg or set to 1 for debug output to aid in debugging.
if not defined debug_output set debug_output=0

:: Use /t command line arg or set to 1 to display init time.
if not defined time_init set time_init=0

:: Use /f command line arg to speed up init at the expense of some functionality.
if not defined fast_init set fast_init=0

:: Use /max_depth 1-5 to set max recurse depth for calls to `enhance_path_recursive`
if not defined max_depth set max_depth=1

:: Add *nix tools to end of path. 0 turns off *nix tools, 2 adds *nix tools to the front of thr path.
if not defined nix_tools set nix_tools=1

set "CMDER_USER_FLAGS= "

:: Find root dir
if not defined CMDER_ROOT (
    if defined ConEmuDir (
        for /f "delims=" %%i in ("%ConEmuDir%\..\..") do (
            set "CMDER_ROOT=%%~fi"
        )
    ) else (
        for /f "delims=" %%i in ("%~dp0\..") do (
            set "CMDER_ROOT=%%~fi"
        )
    )
)

:: Remove trailing '\' from %CMDER_ROOT%
if "%CMDER_ROOT:~-1%" == "\" SET "CMDER_ROOT=%CMDER_ROOT:~0,-1%"

call "%cmder_root%\vendor\bin\cexec.cmd" /setpath
call "%cmder_root%\vendor\lib\lib_base"
call "%cmder_root%\vendor\lib\lib_path"
call "%cmder_root%\vendor\lib\lib_console"
call "%cmder_root%\vendor\lib\lib_git"
call "%cmder_root%\vendor\lib\lib_profile"

:var_loop
    if "%~1" == "" (
        goto :start
    ) else if /i "%1" == "/f" (
        set fast_init=1
    ) else if /i "%1" == "/t" (
        set time_init=1
    ) else if /i "%1"=="/v" (
        set verbose_output=1
    ) else if /i "%1"=="/d" (
        set debug_output=1
    ) else if /i "%1" == "/max_depth" (
        if "%~2" geq "1" if "%~2" leq "5" (
            set "max_depth=%~2"
            shift
        ) else (
            %print_error% "'/max_depth' requires a number between 1 and 5!"
            exit /b
        )
    ) else if /i "%1" == "/c" (
        if exist "%~2" (
            if not exist "%~2\bin" mkdir "%~2\bin"
            set "cmder_user_bin=%~2\bin"
            if not exist "%~2\config\profile.d" mkdir "%~2\config\profile.d"
            set "cmder_user_config=%~2\config"
            shift
        )
    ) else if /i "%1" == "/user_aliases" (
        if exist "%~2" (
            set "user_aliases=%~2"
            shift
        )
    ) else if /i "%1" == "/git_install_root" (
        if exist "%~2" (
            set "GIT_INSTALL_ROOT=%~2"
            shift
        ) else (
            %print_error% "The Git install root folder "%~2", you specified does not exist!"
            exit /b
        )
    ) else if /i "%1"=="/nix_tools" (
        if "%2" equ "0" (
            REM Do not add *nix tools to path
            set nix_tools=0
            shift
        ) else if "%2" equ "1" (
            REM Add *nix tools to end of path
            set nix_tools=1
            shift
        ) else if "%2" equ "2" (
            REM Add *nix tools to front of path
            set nix_tools=2
            shift
        )
    ) else if /i "%1" == "/home" (
        if exist "%~2" (
            set "HOME=%~2"
            shift
        ) else (
            %print_error% The home folder "%2", you specified does not exist!
            exit /b
        )
    ) else if /i "%1" == "/svn_ssh" (
        set SVN_SSH=%2
        shift
    ) else (
      set "CMDER_USER_FLAGS=%1 %CMDER_USER_FLAGS%"
    )
    shift
goto var_loop

:start
:: Sets CMDER_SHELL, CMDER_CLINK, CMDER_ALIASES
%lib_base% cmder_shell
%print_debug% init.bat "Env Var - CMDER_ROOT=%CMDER_ROOT%"
%print_debug% init.bat "Env Var - debug_output=%debug_output%"

if defined CMDER_USER_CONFIG (
    %print_debug% init.bat "CMDER IS ALSO USING INDIVIDUAL USER CONFIG FROM '%CMDER_USER_CONFIG%'!"

    if not exist "%CMDER_USER_CONFIG%\..\opt" md "%CMDER_USER_CONFIG%\..\opt"
)

:: Pick right version of clink
if "%PROCESSOR_ARCHITECTURE%"=="x86" (
    set clink_architecture=x86
    set architecture_bits=32
) else (
    set clink_architecture=x64
    set architecture_bits=64
)

if "%CMDER_CLINK%" == "1" (
  %print_verbose% "Injecting Clink!"

  :: Run clink
  if defined CMDER_USER_CONFIG (
    if not exist "%CMDER_USER_CONFIG%\settings" if not exist "%CMDER_USER_CONFIG%\clink_settings" (
      echo Generating clink initial settings in "%CMDER_USER_CONFIG%\clink_settings"
      copy "%CMDER_ROOT%\vendor\clink_settings.default" "%CMDER_USER_CONFIG%\clink_settings"
      echo Additional *.lua files in "%CMDER_USER_CONFIG%" are loaded on startup.
    )

    if not exist "%CMDER_USER_CONFIG%\cmder_prompt_config.lua" (
      echo Creating Cmder prompt config file: "%CMDER_USER_CONFIG%\cmder_prompt_config.lua"
      copy "%CMDER_ROOT%\vendor\cmder_prompt_config.lua.default" "%CMDER_USER_CONFIG%\cmder_prompt_config.lua"
    )

    REM Cleanup lagacy Clink Settings file
    if exist "%CMDER_USER_CONFIG%\settings" if exist "%CMDER_USER_CONFIG%\clink_settings" (
      del "%CMDER_USER_CONFIG%\settings"
    )

    REM Cleanup legacy CLink history file
    if exist "%CMDER_USER_CONFIG%\.history" if exist "%CMDER_USER_CONFIG%\clink_history" (
      del "%CMDER_USER_CONFIG%\.history"
    )
    "%CMDER_ROOT%\vendor\clink\clink_%clink_architecture%.exe" inject --quiet --profile "%CMDER_USER_CONFIG%" --scripts "%CMDER_ROOT%\vendor"
  ) else (
    if not exist "%CMDER_ROOT%\config\settings" if not exist "%CMDER_ROOT%\config\clink_settings" (
      echo Generating clink initial settings in "%CMDER_ROOT%\config\clink_settings"
      copy "%CMDER_ROOT%\vendor\clink_settings.default" "%CMDER_ROOT%\config\clink_settings"
      echo Additional *.lua files in "%CMDER_ROOT%\config" are loaded on startup.
    )

    if not exist "%CMDER_ROOT%\config\cmder_prompt_config.lua" (
      echo Creating Cmder prompt config file: "%CMDER_ROOT%\config\cmder_prompt_config.lua"
      copy "%CMDER_ROOT%\vendor\cmder_prompt_config.lua.default" "%CMDER_ROOT%\config\cmder_prompt_config.lua"
    )

    REM Cleanup lagacy Clink Settings file
    if exist "%CMDER_ROOT%\config\settings" if exist "%CMDER_ROOT%\config\clink_settings" (
      del "%CMDER_ROOT%\config\settings"
    )

    REM Cleanup legacy Clink history file
    if exist "%CMDER_ROOT%\config\.history" if exist "%CMDER_ROOT%\config\clink_history" (
      del "%CMDER_ROOT%\config\.history"
    )

    "%CMDER_ROOT%\vendor\clink\clink_%clink_architecture%.exe" inject --quiet --profile "%CMDER_ROOT%\config" --scripts "%CMDER_ROOT%\vendor"
  )
) else (
  %print_verbose% "WARNING: Incompatible 'ComSpec/Shell' Detetected Skipping Clink Injection!"
)

if "%CMDER_CONFIGURED%" GTR "1" (
  %print_verbose% "Cmder is already configured, skipping Cmder Init!"

  goto USER_ALIASES
) else if "%CMDER_CONFIGURED%" == "1" (
  %print_verbose% "Cmder is already configured, skipping to Cmder User Init!"

  goto USER_CONFIG_START
)

:: Prepare for git-for-windows

:: I do not even know, copypasted from their .bat
set PLINK_PROTOCOL=ssh

:: The idea:
:: * if the users points as to a specific git, use that
:: * test if a git is in path and if yes, use that
:: * last, use our vendored git
:: also check that we have a recent enough version of git by examining the version string
if defined GIT_INSTALL_ROOT (
    if exist "%GIT_INSTALL_ROOT%\cmd\git.exe" goto :SPECIFIED_GIT
) else if "%fast_init%" == "1" (
    if exist "%CMDER_ROOT%\vendor\git-for-windows\cmd\git.exe" (
      %print_debug% init.bat "Skipping Git Auto-Detect!"
      goto :VENDORED_GIT
    )
)

%print_debug% init.bat "Looking for Git install root..."

:: get the version information for vendored git binary
%lib_git% read_version VENDORED "%CMDER_ROOT%\vendor\git-for-windows\cmd" 2>nul
%lib_git% validate_version VENDORED %GIT_VERSION_VENDORED%

:: check if git is in path...
for /F "delims=" %%F in ('where git.exe 2^>nul ^| find "\cmd\git.exe"') do (
    :: get the absolute path to the user provided git binary
    %lib_git% is_git_shim "%%~dpF"
    %lib_git% get_user_git_version
    %lib_git% compare_git_versions

    if defined GIT_INSTALL_ROOT (
        goto :FOUND_GIT
    )
)

:: our last hope: our own git...
:VENDORED_GIT
if exist "%CMDER_ROOT%\vendor\git-for-windows" (
    set "GIT_INSTALL_ROOT=%CMDER_ROOT%\vendor\git-for-windows"
    %print_debug% init.bat "Using vendored Git '%GIT_VERSION_VENDORED%'..."
    goto :CONFIGURE_GIT
) else (
    goto :NO_GIT
)

:SPECIFIED_GIT
%print_debug% init.bat "Using /GIT_INSTALL_ROOT..."
goto :CONFIGURE_GIT

:FOUND_GIT
%print_debug% init.bat "Using found Git '%GIT_VERSION_USER%' from '%GIT_INSTALL_ROOT%..."
goto :CONFIGURE_GIT

:CONFIGURE_GIT
%print_debug% init.bat "Using Git from '%GIT_INSTALL_ROOT%..."
:: Add git to the path
if exist "%GIT_INSTALL_ROOT%\cmd\git.exe" %lib_path% enhance_path "%GIT_INSTALL_ROOT%\cmd" ""

:: Add the unix commands at the end to not shadow windows commands like more
if %nix_tools% equ 1 (
    %print_verbose% "Preferring Windows commands"
    set "path_position=append"
) else (
    %print_verbose% "Preferring *nix commands"
    set "path_position="
)

if %nix_tools% geq 1 (
    if exist "%GIT_INSTALL_ROOT%\mingw32" (
        %lib_path% enhance_path "%GIT_INSTALL_ROOT%\mingw32\bin" %path_position%
    ) else if exist "%GIT_INSTALL_ROOT%\mingw64" (
        %lib_path% enhance_path "%GIT_INSTALL_ROOT%\mingw64\bin" %path_position%
    )
    if exist "%GIT_INSTALL_ROOT%\usr\bin" (
        %lib_path% enhance_path "%GIT_INSTALL_ROOT%\usr\bin" %path_position%
    )
)

:: define SVN_SSH so we can use git svn with ssh svn repositories
if not defined SVN_SSH set "SVN_SSH=%GIT_INSTALL_ROOT:\=\\%\\bin\\ssh.exe"

:: Find locale.exe: From the git install root, from the path, using the git installed env, or fallback using the env from the path.
if not defined git_locale if exist "%GIT_INSTALL_ROOT%\usr\bin\locale.exe" set git_locale="%GIT_INSTALL_ROOT%\usr\bin\locale.exe"
if not defined git_locale for /F "tokens=* delims=" %%F in ('where locale.exe 2^>nul') do ( if not defined git_locale  set git_locale="%%F" )
if not defined git_locale if exist "%GIT_INSTALL_ROOT%\usr\bin\env.exe" set git_locale="%GIT_INSTALL_ROOT%\usr\bin\env.exe" /usr/bin/locale
if not defined git_locale for /F "tokens=* delims=" %%F in ('where env.exe 2^>nul') do ( if not defined git_locale  set git_locale="%%F" /usr/bin/locale )

setlocal enabledelayedexpansion
if defined git_locale (

  REM %print_debug% init.bat "Env Var - git_locale=!git_locale!"
  if not defined LANG (
      for /F "delims=" %%F in ('!git_locale! -uU 2') do (
          set "LANG=%%F"
      )
  )
)
endlocal && set LANG=%LANG%

%print_debug% init.bat "Env Var - GIT_INSTALL_ROOT=%GIT_INSTALL_ROOT%"
%print_debug% init.bat "Found Git in: '%GIT_INSTALL_ROOT%'"
goto :PATH_ENHANCE

:NO_GIT
:: Skip this if GIT WAS FOUND else we did 'endlocal' above!
endlocal

:PATH_ENHANCE
%lib_path% enhance_path "%CMDER_ROOT%\vendor\bin"

:USER_CONFIG_START
%lib_path% enhance_path_recursive "%CMDER_ROOT%\bin" 0 %max_depth%
if defined CMDER_USER_BIN (
  %lib_path% enhance_path_recursive "%CMDER_USER_BIN%" 0 %max_depth%
)
%lib_path% enhance_path "%CMDER_ROOT%" append

:: Drop *.bat and *.cmd files into "%CMDER_ROOT%\config\profile.d"
:: to run them at startup.
%lib_profile% run_profile_d "%CMDER_ROOT%\config\profile.d"
if defined CMDER_USER_CONFIG (
  %lib_profile% run_profile_d "%CMDER_USER_CONFIG%\profile.d"
)

:USER_ALIASES
:: Allows user to override default aliases store using profile.d
:: scripts run above by setting the 'aliases' env variable.
::
:: Note: If overriding default aliases store file the aliases
:: must also be self executing, see '.\user_aliases.cmd.default',
:: and be in profile.d folder.
if not defined user_aliases (
  if defined CMDER_USER_CONFIG (
     set "user_aliases=%CMDER_USER_CONFIG%\user_aliases.cmd"
  ) else (
     set "user_aliases=%CMDER_ROOT%\config\user_aliases.cmd"
  )
)

if "%CMDER_ALIASES%" == "1" (
  REM The aliases environment variable is used by alias.bat to id
  REM the default file to store new aliases in.
  if not defined aliases (
    set "aliases=%user_aliases%"
  )

  REM Make sure we have a self-extracting user_aliases.cmd file
  if not exist "%user_aliases%" (
      echo Creating initial user_aliases store in "%user_aliases%"...
      copy "%CMDER_ROOT%\vendor\user_aliases.cmd.default" "%user_aliases%"
  ) else (
    %lib_base% update_legacy_aliases
  )

  :: Update old 'user_aliases' to new self executing 'user_aliases.cmd'
  if exist "%CMDER_ROOT%\config\aliases" (
    echo Updating old "%CMDER_ROOT%\config\aliases" to new format...
    type "%CMDER_ROOT%\config\aliases" >> "%user_aliases%"
    del "%CMDER_ROOT%\config\aliases"
  ) else if exist "%user_aliases%.old_format" (
    echo Updating old "%user_aliases%" to new format...
    type "%user_aliases%.old_format" >> "%user_aliases%"
    del "%user_aliases%.old_format"
  )
)

:: Add aliases to the environment
type "%user_aliases%" | findstr /b /l /i "history=cat " >nul
if "%ERRORLEVEL%" == "0" (
  echo Migrating alias 'history' to new Clink 1.x.x...
  call "%CMDER_ROOT%\vendor\bin\alias.cmd" /d history
  echo Restart the session to activate changes!
)

call "%user_aliases%"

if "%CMDER_CONFIGURED%" gtr "1" goto CMDER_CONFIGURED

:: See vendor\git-for-windows\README.portable for why we do this
:: Basically we need to execute this post-install.bat because we are
:: manually extracting the archive rather than executing the 7z sfx
if exist "%GIT_INSTALL_ROOT%\post-install.bat" (
    echo Running Git for Windows one time Post Install....
    pushd "%GIT_INSTALL_ROOT%\"
    "%GIT_INSTALL_ROOT%\git-cmd.exe" --no-needs-console --no-cd --command=post-install.bat
    popd
)

:: Set home path
if not defined HOME set "HOME=%USERPROFILE%"
%print_debug% init.bat "Env Var - HOME=%HOME%"

set "initialConfig=%CMDER_ROOT%\config\user_profile.cmd"
if exist "%CMDER_ROOT%\config\user_profile.cmd" (
    REM Create this file and place your own command in there
    %print_debug% init.bat "Calling - %CMDER_ROOT%\config\user_profile.cmd"
    call "%CMDER_ROOT%\config\user_profile.cmd"
)

if defined CMDER_USER_CONFIG (
  set "initialConfig=%CMDER_USER_CONFIG%\user_profile.cmd"
  if exist "%CMDER_USER_CONFIG%\user_profile.cmd" (
      REM Create this file and place your own command in there
      %print_debug% init.bat "Calling - %CMDER_USER_CONFIG%\user_profile.cmd"
      call "%CMDER_USER_CONFIG%\user_profile.cmd"
  )
)

if not exist "%initialConfig%" (
    echo Creating user startup file: "%initialConfig%"
    copy "%CMDER_ROOT%\vendor\user_profile.cmd.default" "%initialConfig%"
)

if "%CMDER_ALIASES%" == "1" if exist "%CMDER_ROOT%\bin\alias.bat" if exist "%CMDER_ROOT%\vendor\bin\alias.cmd" (
  echo Cmder's 'alias' command has been moved into "%CMDER_ROOT%\vendor\bin\alias.cmd"
  echo to get rid of this message either:
  echo.
  echo Delete the file "%CMDER_ROOT%\bin\alias.bat"
  echo.
  echo or
  echo.
  echo If you have customized it and want to continue using it instead of the included version
  echo   * Rename "%CMDER_ROOT%\bin\alias.bat" to "%CMDER_ROOT%\bin\alias.cmd".
  echo   * Search for 'user-aliases' and replace it with 'user_aliases'.
)

set initialConfig=

:CMDER_CONFIGURED
if not defined CMDER_CONFIGURED set CMDER_CONFIGURED=1

set CMDER_INIT_END=%time%

if %time_init% gtr 0 (
  "%cmder_root%\vendor\bin\timer.cmd" "%CMDER_INIT_START%" "%CMDER_INIT_END%"
)
exit /b
