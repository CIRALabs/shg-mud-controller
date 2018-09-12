PREFIX?=
DESTDIR?=${PREFIX}
MUDSUPER=${DESTDIR}/usr/lib/lua/mud-controller

all:
	@true

install:
	mkdir -p ${MUDSUPER}
	cp *.lua ${MUDSUPER}
