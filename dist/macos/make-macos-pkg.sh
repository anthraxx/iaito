#!/bin/sh

# based on
# http://blog.coolaj86.com/articles/how-to-unpackage-and-repackage-pkg-macos.html

# to uninstall:
# sudo pkgutil --forget org.radare.iaito

SRC=/tmp/iaito-macos
PREFIX=/usr/local
DST="$(pwd)/macos-pkg/iaito.unpkg"
if [ -n "$1" ]; then
	VERSION="$1"
else
	VERSION="`../../configure -qV`"
	[ -z "${VERSION}" ] && VERSION=5.2.1
fi
[ -z "${MAKE}" ] && MAKE=make

while : ; do
	[ -x "$PWD/configure" ] && break
	[ "$PWD" = / ] && break
	cd ..
done

[ ! -x "$PWD/configure" ] && exit 1

pwd
if [ ! -d build/iaito.app ]; then
	rm -rf "${SRC}"
	${MAKE} mrproper 2>/dev/null
	# ${MAKE} -j4 || exit 1
fi
export CFLAGS=-O2
./configure --prefix="${PREFIX}" || exit 1
make -C .. translations
${MAKE} install PREFIX="${PREFIX}" DESTDIR=${SRC} || exit 1
mkdir -p "${DST}"
if [ -d "${SRC}" ]; then
	(
		cd ${SRC} && \
		find . | cpio -o --format odc | gzip -c > "${DST}/Payload"
	)
	mkbom ${SRC} "${DST}/Bom"
	# Repackage
	pkgutil --flatten "${DST}" "${DST}/../iaito-${VERSION}.pkg"
else
	echo "Failed install. DESTDIR is empty"
	exit 1
fi
