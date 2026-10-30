#!/usr/bin/env bash
set -e
./build.sh && SDL_VIDEODRIVER=x11 ./werevim
