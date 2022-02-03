@echo off

set scriptDir=%~dp0
set projectRoot=%scriptDir%\..

if [%~1]==[--release] (
	mkdir %projectRoot%\bin\release\ >nul 2>nul
	cd %projectRoot%\bin\release\

	xcopy %projectRoot%\res\ %projectRoot%\bin\release\res\ /s /e /y /q
	xcopy "C:\Program Files\Odin\vendor\sdl2\SDL2.dll" %projectRoot%\bin\release\ /q /y
	xcopy "C:\Program Files\Odin\vendor\sdl2\image\SDL2_image.dll" %projectRoot%\bin\release\ /q /y
	xcopy "C:\Program Files\Odin\vendor\sdl2\image\libpng16-16.dll" %projectRoot%\bin\release\ /q /y
	xcopy "C:\Program Files\Odin\vendor\sdl2\image\zlib1.dll" %projectRoot%\bin\release\ /q /y
	xcopy "C:\Program Files\Odin\vendor\sdl2\ttf\SDL2_ttf.dll" %projectRoot%\bin\release\ /q /y
	xcopy "C:\Program Files\Odin\vendor\sdl2\ttf\libfreetype-6.dll" %projectRoot%\bin\release\ /q /y
	
	odin run %projectRoot%\src\ -o:size -out:jumper.exe -thread-count:8
) else (
	mkdir %projectRoot%\bin\debug\ >nul 2>nul
	cd %projectRoot%\bin\debug\

	xcopy %projectRoot%\res\ %projectRoot%\bin\debug\res\ /s /e /y /q
	xcopy "C:\Program Files\Odin\vendor\sdl2\SDL2.dll" %projectRoot%\bin\debug\ /q /y
	xcopy "C:\Program Files\Odin\vendor\sdl2\image\SDL2_image.dll" %projectRoot%\bin\debug\ /q /y
	xcopy "C:\Program Files\Odin\vendor\sdl2\image\libpng16-16.dll" %projectRoot%\bin\debug\ /q /y
	xcopy "C:\Program Files\Odin\vendor\sdl2\image\zlib1.dll" %projectRoot%\bin\debug\ /q /y
	xcopy "C:\Program Files\Odin\vendor\sdl2\ttf\SDL2_ttf.dll" %projectRoot%\bin\debug\ /q /y
	xcopy "C:\Program Files\Odin\vendor\sdl2\ttf\libfreetype-6.dll" %projectRoot%\bin\debug\ /q /y
	
	odin run %projectRoot%\src\ -opt:0 -out:jumper.exe -thread-count:8 -debug
)

cd %projectRoot%
