@ECHO OFF
cd %~dp0
SET SOURCE=.\..\src\*
SET TARGET=wagon.7z
SET TARGET_EXE=wagon.exe
SET CONFIG=config.txt
del /Q %TARGET% %TARGET_EXE%
7zr.exe a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on %TARGET% %SOURCE%
copy /b installer.sfx + %CONFIG% + %TARGET% %TARGET_EXE%
