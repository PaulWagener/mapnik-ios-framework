
LIBRARY = libmapnik.a

all: update libmapnik.a
libmapnik.a: build_arches
	echo "Making libmapnik or something"

update:
	git submodule init
	git submodule update

# Build separate architectures
build_arches:
	${MAKE} ${CURDIR}/build/armv7/lib/libmapnik.a ARCH=armv7

PREFIX = ${CURDIR}/build/${ARCH}
LIBDIR = ${PREFIX}/lib
INCLUDEDIR = ${PREFIX}/include

XCODE_DEVELOPER = $(shell xcode-select --print-path)

IOS_SDK = ${XCODE_DEVELOPER}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk

CXX = ${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++
CC = ${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
CFLAGS = -isysroot ${IOS_SDK} -I${IOS_SDK}/usr/include -arch ${ARCH}
CXXFLAGS = -stdlib=libc++ -isysroot ${IOS_SDK} -I${IOS_SDK}/usr/include -arch ${ARCH}
LDFLAGS = -stdlib=libc++ -isysroot ${IOS_SDK} -L${IOS_SDK}/usr/lib -L${LIBDIR} -arch ${ARCH}

${LIBDIR}/libmapnik.a: ${LIBDIR}/libpng.a ${LIBDIR}/libproj.a ${LIBDIR}/libtiff.a ${LIBDIR}/libjpeg.a ${LIBDIR}/libicuuc.a ${LIBDIR}/libboost_system.a ${LIBDIR}/libcairo.a ${LIBDIR}/libfreetype.a
	# Building architecture: ${ARCH}
	cd mapnik && ./configure CXX=${CXX} CC=${CC} \
		CUSTOM_CFLAGS="${CFLAGS} -I${IOS_SDK}/usr/include/libxml2" \
		CUSTOM_CXXFLAGS="${CXXFLAGS} -DUCHAR_TYPE=char16_t -std=c++11 -I${IOS_SDK}/usr/include/libxml2" \
		CUSTOM_LDFLAGS="${LDFLAGS}" \
		FREETYPE_CONFIG=${PREFIX}/bin/freetype-config XML2_CONFIG=/bin/false \
		{LTDL_INCLUDES,OCCI_INCLUDES,SQLITE_INCLUDES,RASTERLITE_INCLUDES}=. \
		{BOOST_PYTHON_LIB,LTDL_LIBS,OCCI_LIBS,SQLITE_LIBS,RASTERLITE_LIBS}=. \
		BOOST_INCLUDES=${PREFIX}/include \
		BOOST_LIBS=${PREFIX}/lib \
		ICU_INCLUDES=${PREFIX}/include \
		ICU_LIBS=${PREFIX}/lib \
		PROJ_INCLUDES=${PREFIX}/include \
		PROJ_LIBS=${PREFIX}/lib \
		PNG_INCLUDES=${PREFIX}/include \
		PNG_LIBS=${PREFIX}/lib \
		CAIRO_INCLUDES=${PREFIX} \
		CAIRO_LIBS=${PREFIX} \
		JPEG_INCLUDES=${PREFIX}/include \
		JPEG_LIBS=${PREFIX}/lib \
		TIFF_INCLUDES=${PREFIX}/include \
		TIFF_LIBS=${PREFIX}/lib \
		INPUT_PLUGINS=shape \
		BINDINGS=none \
		LINKING=static \
		DEMO=no \
		RUNTIME_LINK=static \
		PREFIX=${PREFIX}


# LibPNG
${LIBDIR}/libpng.a:
	cd libpng && env CXX=${CXX} CC=${CC} CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" ./configure --host=arm-apple-darwin --disable-shared --prefix=${PREFIX} && ${MAKE} clean install

# LibProj
${LIBDIR}/libproj.a:
	cd libproj && env CXX=${CXX} CC=${CC} CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" ./configure --host=arm-apple-darwin --disable-shared --prefix=${PREFIX} && ${MAKE} clean install

# LibTiff
${LIBDIR}/libtiff.a:
	cd libtiff && env CXX=${CXX} CC=${CC} CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" ./configure --host=arm-apple-darwin --disable-shared --prefix=${PREFIX} && ${MAKE} clean install

# LibJpeg
${LIBDIR}/libjpeg.a:
	cd libjpeg && env CXX=${CXX} CC=${CC} CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" ./configure --host=arm-apple-darwin --disable-shared --prefix=${PREFIX} && ${MAKE} clean install

# LibIcu
libicu_host/config/icucross.mk:
	cd libicu_host && ./configure && ${MAKE}

${LIBDIR}/libicuuc.a: libicu_host/config/icucross.mk
	touch ${CURDIR}/license.html
	cd libicu && env CXX=${CXX} CC=${CC} CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS} -std=c++11 -I${CURDIR}/libicu/tools/tzcode -DUCHAR_TYPE=uint16_t" LDFLAGS="${LDFLAGS}" ./configure --host=arm-apple-darwin --disable-shared --enable-static --prefix=${PREFIX} --with-cross-build=${CURDIR}/libicu_host && ${MAKE} clean install

# Boost
${LIBDIR}/libboost_system.a: ${LIBDIR}/libicuuc.a
	rm -rf boost-build boost-stage
	cd boost && ./bootstrap.sh --with-libraries=thread,signals,filesystem,regex,system,date_time
	cd boost && git checkout tools/build/v2/user-config.jam
	echo "using darwin : iphone \n \
		: ${CXX} -miphoneos-version-min=5.0 -fvisibility=hidden -fvisibility-inlines-hidden ${CXXFLAGS} -I${INCLUDEDIR} -L${LIBDIR} \n \
		: <architecture>arm <target-os>iphone \n \
		;" >> boost/tools/build/v2/user-config.jam
	cd boost && ./bjam -a --build-dir=boost-build --stagedir=boost-stage --prefix=${PREFIX} toolset=darwin architecture=arm target-os=iphone  define=_LITTLE_ENDIAN link=static install

# FreeType
${LIBDIR}/libfreetype.a:
	cd freetype && ./autogen.sh && env CXX=${CXX} CC=${CC} CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" ./configure --host=arm-apple-darwin --disable-shared --prefix=${PREFIX} && ${MAKE} clean install

# Cairo
${LIBDIR}/libcairo.a:
	#cd cairo && ./autogen.sh
	cd cairo && env \
	{GTKDOC_DEPS_LIBS,VALGRIND_LIBS,xlib_LIBS,xlib_xrender_LIBS,xcb_LIBS,xlib_xcb_LIBS,xcb_shm_LIBS,qt_LIBS,drm_LIBS,gl_LIBS,glesv2_LIBS,cogl_LIBS,directfb_LIBS,egl_LIBS,FREETYPE_LIBS,FONTCONFIG_LIBS,LIBSPECTRE_LIBS,POPPLER_LIBS,LIBRSVG_LIBS,GOBJECT_LIBS,glib_LIBS,gtk_LIBS,png_LIBS,pixman_LIBS}=-L${LIBDIR} \
	png_CFLAGS=-I${INCLUDEDIR} \
	pixman_CFLAGS=-I${INCLUDEDIR} \
	PATH=${PREFIX}/bin:$$PATH CXX=${CXX} \
	CC="${CC} ${CFLAGS} -I${INCLUDEDIR}/pixman-1" \
	CFLAGS="${CFLAGS} -DCAIRO_NO_MUTEX=1" \
	CXXFLAGS="-DCAIRO_NO_MUTEX=1 ${CXXFLAGS}" \
	LDFLAGS="-framework Foundation -framework CoreGraphics ${LDFLAGS}" ./configure --host=arm-apple-darwin --prefix=${PREFIX} --enable-static --disable-shared --enable-quartz --disable-quartz-font --without-x --disable-xlib --disable-xlib-xrender --disable-xcb --disable-xlib-xcb --disable-xcb-shm --enable-ft

clean:
	rm -rf libmapnik.a
	rm -rf build
	cd libpng && ${MAKE} clean
	cd libproj && ${MAKE} clean
	cd libtiff && ${MAKE} clean
	cd libjpeg && ${MAKE} clean