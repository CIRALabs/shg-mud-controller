DESTDIR?=
MUDSUPER=${DESTDIR}/usr/lib/lua/mud-super

all:
	@true

install:
	mkdir -p ${MUDSUPER}
	cp mud_controller.lua ${MUDSUPER}
	cp mud_digger.lua     ${MUDSUPER}
	cp mud_util.lua       ${MUDSUPER}
