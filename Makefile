PREFIX?=
DESTDIR?=${PREFIX}
MUDSUPER=${DESTDIR}/usr/lib/lua/mud-controller

all:
	@true

install:
	mkdir -p ${MUDSUPER} ${DESTDIR}/etc/init.d
	cp *.lua ${MUDSUPER}
	cp init  ${DESTDIR}/etc/init.d/mud-controller
	chmod a+x ${DESTDIR}/etc/init.d/mud-controller

