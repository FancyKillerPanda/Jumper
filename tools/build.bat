@echo off

set scriptDir=%~dp0
set projectRoot=%scriptDir%\..

mkdir %projectRoot%\bin\ >nul 2>nul
cd %projectRoot%\bin\

xcopy %projectRoot%\res\ %projectRoot%\bin\res\ /s /e
odin run %projectRoot%\src\ -opt:0 -out:jumper.exe -thread-count:8 -debug

cd %projectRoot%
