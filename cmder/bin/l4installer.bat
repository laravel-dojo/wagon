@echo off

:: get params
if "%~1"=="" goto:show_help
if "%~1"=="help" goto:show_help
if "%~1"=="new" if not "%~2"=="" set PROJECT_NAME="%~2" && goto:check_project

:: Missing params
echo provide your project name, please?
goto:eof

:check_project
if not exist %WAGON_ROOT%\uwamp\www\%PROJECT_NAME% goto:create_proejct
echo prject %PROJECT_NAME%already exist!
goto:eof

:create_proejct
echo Creating application...

:: Extra files
7za x %WAGON_ROOT%\laravel\4.2.16.zip -o%WAGON_ROOT%\uwamp\www\%PROJECT_NAME% -y > nul

:: Change to www folder 
cd %WAGON_ROOT%\uwamp\www\%PROJECT_NAME%

:: Run php artisan key:genrate
php artisan key:generate
goto:eof

:: Display wangon help
:show_help
echo.Usage:
echo.  l4installer [command]
echo.   
echo.Commands:
echo.  new 
echo.    Create new laravel project from 4.2.11 archive file.
echo.  help
echo.    Show help message.
goto:eof