#!/bin/bash
#
#  Copyright (c) 2013 leenjewel <leenjewel@gmail.com>
#  MIT License (see LICENSE.md file)
#
#  Based on work by Felix Schulze:
#
#  Automatic build script for libssl and libcrypto 
#  for iPhoneOS and iPhoneSimulator
#
#  Created by Felix Schulze on 16.12.10.
#  Copyright 2010 Felix Schulze. All rights reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

set -u
 
# Setup architectures, library name and other vars + cleanup from previous runs
ARCHS=("android-armv7" "android" "android-x86")
OUTNAME=("armeabi-v7a" "armeabi" "x86")
LIB_NAME="openssl-1.0.2c"
LIB_DEST_DIR="libs"
HEADER_DEST_DIR="include"
rm -rf "${HEADER_DEST_DIR}" "${LIB_DEST_DIR}" "${LIB_NAME}"
NDK=$NDK_ROOT
# Unarchive library, then configure and make for specified architectures
configure_make()
{
   ARCH=$1; OUT=$2;
   tar xfz "${LIB_NAME}.tar.gz"
   pushd .; cd "${LIB_NAME}";

   if [ "$ARCH" == "android-armv7" ]; then
       export ARCH_FLAGS="-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16"
       export ARCH_LINK="-march=armv7-a -Wl,--fix-cortex-a8"
       export TOOL="arm-linux-androideabi"
       NDK_FLAGS="--platform=android-9 --toolchain=arm-linux-androideabi-4.6 --install-dir=`pwd`/android-toolchain"
   elif [ "$ARCH" == "android" ]; then
       export ARCH_FLAGS="-mthumb"
       export ARCH_LINK=""
       export TOOL="arm-linux-androideabi"
       NDK_FLAGS="--platform=android-9 --toolchain=arm-linux-androideabi-4.6 --install-dir=`pwd`/android-toolchain"
   elif [ "$ARCH" == "android-x86" ]; then
       export ARCH_FLAGS="-march=i686 -msse3 -mstackrealign -mfpmath=sse"
       export ARCH_LINK=""
       export TOOL="i686-linux-android"
       NDK_FLAGS="--platform=android-9 --toolchain=x86-4.6 --install-dir=`pwd`/android-toolchain"
   fi
   $NDK/build/tools/make-standalone-toolchain.sh $NDK_FLAGS
   export TOOLCHAIN_PATH=`pwd`/android-toolchain/bin
   export NDK_TOOLCHAIN_BASENAME=${TOOLCHAIN_PATH}/${TOOL}
   export CC=$NDK_TOOLCHAIN_BASENAME-gcc
   export CXX=$NDK_TOOLCHAIN_BASENAME-g++
   export LINK=${CXX}
   export LD=$NDK_TOOLCHAIN_BASENAME-ld
   export AR=$NDK_TOOLCHAIN_BASENAME-ar
   export RANLIB=$NDK_TOOLCHAIN_BASENAME-ranlib
   export STRIP=$NDK_TOOLCHAIN_BASENAME-strip
   export CPPFLAGS=" ${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -finline-limit=64 "
   export CXXFLAGS=" ${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -finline-limit=64 -frtti -fexceptions "
   export CFLAGS=" ${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -finline-limit=64 "
   export LDFLAGS=" ${ARCH_LINK} "
   ./Configure $ARCH
   PATH=$TOOLCHAIN_PATH:$PATH make
   mkdir -p ../$LIB_DEST_DIR/$OUT
   cp libcrypto.a ../$LIB_DEST_DIR/$OUT
   cp libssl.a ../$LIB_DEST_DIR/$OUT
   popd; rm -rf "${LIB_NAME}";
}



for ((i=0; i < ${#ARCHS[@]}; i++))
do
   configure_make "${ARCHS[i]}" "${OUTNAME[i]}"
done

mkdir -p "${HEADER_DEST_DIR}/openssl"
tar xfz "${LIB_NAME}.tar.gz"
cp ${LIB_NAME}/include/openssl/*.h ${HEADER_DEST_DIR}/openssl/
