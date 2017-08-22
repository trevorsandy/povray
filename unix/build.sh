#!/bin/sh

# https://wiki.eclipse.org/CDT/Autotools/User_Guide
# 


sudo ./prebuild3rdparty.sh
cd ../
PRFX=~/projects/lpub3d_macos_3rdparty
echo $PRFX
sudo ./configure COMPILED_BY="Trevor SANDY <trevor.sandy@gmail.com> for LPub3D." --prefix="$PRFX" LPUB3D_3RD_PARTY="yes" --enable-watch-cursor
#sudo make check
#sudo make install
