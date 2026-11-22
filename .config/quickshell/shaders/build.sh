#!/bin/sh
# Rebuild the compiled shaders (.qsb) after editing a .vert/.frag here.
# Needs Qt's shader tool: pacman -S qt6-shadertools (qsb in /usr/lib/qt6/bin).
set -e
cd "$(dirname "$0")"
QSB=$(command -v qsb || echo /usr/lib/qt6/bin/qsb)
for f in core.vert core.frag membrane.frag; do
    "$QSB" --glsl "100es,120,150" -o "$f.qsb" "$f"
done
echo "shaders built"
