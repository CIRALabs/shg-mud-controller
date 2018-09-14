PREFIX?=
DESTDIR?=${PREFIX}
MUDSUPER=${DESTDIR}/usr/lib/lua/mud-controller

all:
	@true

install:
	mkdir -p ${MUDSUPER}
	cp *.lua ${MUDSUPER}
	cp init  ${DESTDIR}/etc/init.d/mud-controller
