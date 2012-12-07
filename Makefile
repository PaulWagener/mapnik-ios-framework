
LIBRARY = libmapnik.a

all: libmapnik.a
libmapnik.a: build_arches
	echo "Making libmapnik or something"


# Build separate architectures
build_arches:
	make ${CURDIR}/build/armv7/lib/libmapnik.a ARCH=armv7

PREFIX = ${CURDIR}/build/${ARCH}
LIBDIR = ${PREFIX}/lib

XCODE_DEVELOPER = $(shell xcode-select --print-path)

IOS_SDK = ${XCODE_DEVELOPER}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk

CXX = ${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++
CC = ${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
CFLAGS = -isysroot ${IOS_SDK} -I${IOS_SDK}/usr/include -arch ${ARCH}
CXXFLAGS = -stdlib=libc++ -isysroot ${IOS_SDK} -I${IOS_SDK}/usr/include -arch ${ARCH}
LDFLAGS = -stdlib=libc++ -isysroot ${IOS_SDK} -L${IOS_SDK}/usr/lib -arch ${ARCH}

${LIBDIR}/libmapnik.a: ${LIBDIR}/libpng.a
	echo "TODO: Building architecture: ${ARCH}"


# LibPNG
${LIBDIR}/libpng.a:
	cd libpng && env CXX=${CXX} CC=${CC} CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" ./configure --host=arm-apple-darwin --prefix=${PREFIX} && make install

clean:
	rm -rf libmapnik.a
	rm -rf build
	cd libpng && make clean

libpng:
	echo "woop"
