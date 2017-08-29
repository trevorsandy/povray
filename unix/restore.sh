#!/bin/sh

echo "1. Cleaning..."
sudo ./prebuild3rdparty.sh clean
echo "2. Restoring boost library..."
cp -rf ../../libs-povray/libraries/boost ../libraries && echo "3. Boost library restored."
echo "4. Restoring libtiff Makefile.am..."
cp -f ../../libs-povray/libraries/tiff/libtiff/Makefile.am ../libraries/tiff/libtiff && echo "5. Makefile.am restored."
echo "6. Restore finshed."
