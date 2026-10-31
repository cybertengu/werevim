# Werevim
## Purpose
A GUI for Neovim, written in Odin with SDL2. Visual Studio Code's (VS Code) vim emulation doesn't support every Vim command, and I wanted an editor without constant update pages. Auto-completion is annoying to me in VS Code when typing.

## Status
This can be used as an editor. No mouse support. Laggy live resize on Wayland. The CJK fallback font exists on Fedora. I got a few polishing ideas to do.

## Goals
Fast startup, fast file open and edit, fast compile time, Windows and macOS.

## Building on Fedora
Install the dependencies
```
sudo dnf install llvm-devel clang sdl2-compat-devel SDL2_ttf-devel neovim
```

Build Odin from source and add it to your PATH. Tested with Odin dev-2026-10:
```
git clone https://github.com/odin-lang/Odin ~/Odin
cd ~/Odin && ./build_odin.sh release
echo 'export PATH="$HOME/Odin:$PATH"' >> ~/.bashrc
```

Then build and run Werevim from the repo folder:
```
./build.sh
./werevim
```

## Building on Windows
Odin (dev-2026-10:779c8c0a4) and Neovim 0.9+ on your PATH (once implemented), and the SDL2_ttf and SDL2 DLL files in Odin's vendor folder for Windows.

The build.bat expects Odin at C:\Odin (not yet set up as an environment variable in build.bat). Edit the paths if yours is elsewhere.

```
.\build.bat
.\werevim.exe
```
NOTE: I have not tested on Windows. I don't have one anymore.

## Baseline Build Time (I think I won't update this anymore)
Tested on Windows (debug build, but I don't have a Windows computer anymore), macOS planned. Used flags such as -debug and -show-timings. Tested on Fedora.

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
2026/10/20
```
Total Time                         -   355.928 ms - 100.00%
initialization                     -     8.848 ms -   2.48%
parse files                        -    28.018 ms -   7.87%
type check                         -   105.253 ms -  29.57%
LLVM API Code Gen (   72 modules ) -   109.665 ms -  30.81%
msvc-link                          -   104.137 ms -  29.25%
```

Measured with Intel(R) Core(TM) i7-1065G7 @ 1.30GHz, 4 Cores, 8 Logical Processors, 16 GB RAM.
Fedora Linux 44 (Workstation), kernel 7.2.13, GNOME on Wayland.
Odin dev-2026-10:f9f544ec4, Neovim 0.12.6, SDL2_ttf 2.24.0, sdl2-compat 2.32.74 (SDL3 3.4.18).
2026/10/30:
```
Total Time                         -   453.628 ms - 100.00%
initialization                     -    14.581 ms -   3.21%
parse files                        -    54.737 ms -  12.06%
type check                         -    66.230 ms -  14.60%
LLVM API Code Gen (   98 modules ) -   205.280 ms -  45.25%
ld-link                            -   112.785 ms -  24.86%
```

## License
Werevim is released under the MIT License. See [LICENSE](LICENSE).

The font, JetBrains Mono, is licensed under the SIL Open Font License. See [assets/fonts/OFL.txt](assets/fonts/OFL.txt).

SDL2 and SDL2_ttf have their own licenses. I do not include them in this repo, but you can get them from Odin's vendor folder.
