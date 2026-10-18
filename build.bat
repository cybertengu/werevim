@echo off
odin build src -out:werevim.exe -debug -show-timings
if errorlevel 1 exit /b 1
if not exist SDL2.dll (
    copy /Y "C:\odin\vendor\sdl2\SDL2.dll" . >nul
    if errorlevel 1 exit /b 1
)
if not exist SDL2_ttf.dll (
    copy /Y "C:\odin\vendor\sdl2\ttf\SDL2_ttf.dll" . >nul
    if errorlevel 1 exit /b 1
)
