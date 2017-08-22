#!/bin/sh

echo "Cleaning..."
sudo ./prebuild3rdparty.sh clean
echo "Restoring boost library..."
cp -rf ../../libs-povray/libraries/boost ../libraries && echo "Boost library restored."
echo "Restoring libtiff Makefile.am..."
cp -f ../../libs-povray/libraries/tiff/libtiff/Makefile.am ../libraries/tiff/libtiff && echo "Makefile.am restored."
echo Finshed.
