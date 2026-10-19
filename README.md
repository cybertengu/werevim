# Werevim
## Purpose
A GUI for Neovim, written in Odin with SDL2. Visual Studio Code's (VS Code) vim emulation doesn't support every Vim command, and I wanted an editor without constant update pages. Auto-completion is annoying to me in VS Code when typing.

## Status
Currently in development. It only opens a window and renders text. No Neovim integration yet.

## Goals
Fast startup, fast file open and edit, fast compile time, Windows and macOS.

## Requirements
Odin (dev-2026-01) and Neovim 0.9+ on your PATH (once implemented), and the SDL2_ttf and SDL2 DLL files in Odin's vendor folder for Windows.

The build.bat expects Odin at C:\Odin (not yet set up as an environment variable in build.bat). Edit the paths if yours is elsewhere.

## Build
How to build on Windows:
```
.\build.bat
.\werevim.exe
```
NOTE: this needs to run from the repo folder, because the font path is relative.

## Baseline
Only tested on Windows (debug build), macOS planned. Used flags such as -debug and -show-timings. Odin version is dev-2026-01:0f875727a.

Measured on 12th Gen Intel(R) Core(TM) i9-12900H, 14 Cores, 20 Logical Processors, Windows 11.

Baseline time 2026/10/17:

```
Total Time                         -   455.211 ms - 100.00%
initialization                     -    12.538 ms -   2.75%
parse files                        -    45.834 ms -  10.06%
type check                         -   128.745 ms -  28.28%
LLVM API Code Gen (   60 modules ) -   135.063 ms -  29.67%
msvc-link                          -   133.023 ms -  29.22%
```
2026/10/18
```
Total Time                         -   321.871 ms - 100.00%
initialization                     -     8.435 ms -   2.62%
parse files                        -    24.724 ms -   7.68%
type check                         -    92.806 ms -  28.83%
LLVM API Code Gen (   71 modules ) -    96.222 ms -  29.89%
msvc-link                          -    99.680 ms -  30.96%
```

## License
Werevim is released under the MIT License. See [LICENSE](LICENSE).

The font, JetBrains Mono, is licensed under the SIL Open Font License. See [assets/fonts/OFL.txt](assets/fonts/OFL.txt).

SDL2 and SDL2_ttf have their own licenses. I do not include them in this repo, but you can get them from Odin's vendor folder.
