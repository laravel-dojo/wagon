@ECHO OFF
cd %~dp0
SET SOURCE=.\..\src\*
SET TARGET=wagon.7z
SET TARGET_EXE=wagon.exe
SET CONFIG=config.txt
del /Q %TARGET% %TARGET_EXE%
7za.exe a -t7z %TARGET% %SOURCE%
copy /b 7zsd.sfx + %CONFIG% + %TARGET% %TARGET_EXE%