#	@(#)Makefile	8.1 (Berkeley) 6/19/93

SUBDIR=	bin contrib games include lib libexec old sbin \
	share usr.bin usr.sbin

afterinstall:
	(cd share/man && ${MAKE} makedb)

#
# Build the whole DESTDIR tree.
#
build:
	${MAKE} -Cetc distribution
	${MAKE} -Cinclude install
	${MAKE} cleandir
	${MAKE} -Clib depend all install
	${MAKE} depend all install

# Filesystem and swap sizes.
ROOT_MBYTES = 200
SWAP_MBYTES = 32
U_MBYTES    = 100
UFSTOOL     = contrib/ufstool/ufstool

#
# Create disk image from DESTDIR directory contents.
#
fs:     sdcard.img

.PHONY: sdcard.img
sdcard.img: ${UFSTOOL} etc/rootfs.manifest
	rm -f $@
	${UFSTOOL} --repartition=fs=${ROOT_MBYTES}M:swap=${SWAP_MBYTES}M:fs=${U_MBYTES}M $@
	${UFSTOOL} --new --partition=1 --manifest=etc/rootfs.manifest $@ ${DESTDIR}
	${UFSTOOL} --new --partition=3 $@

#
# Write disk image to SD card.
#
installfs:
.if defined(SDCARD)
	@[ -f sdcard.img ] || $(MAKE) sdcard.img
	sudo dd bs=32k if=sdcard.img of=$(SDCARD)
.else
	@echo "Error: No SDCARD defined."
.endif

#
# Build kernel.
#
ARCH    = mips
BOARD   = WIFIRE.pic32

kernel: sys/compile/${BOARD}/Makefile
	${MAKE} -Csys/compile/${BOARD}

sys/compile/${BOARD}/Makefile: sys/${ARCH}/conf/${BOARD}
	(cd sys/${ARCH}/conf; ../../../usr.sbin/config/config -g ${BOARD})
	${MAKE} -Csys/compile/${BOARD} depend

#
# Upload the kernel to chipKIT Wi-Fire board.
#
load:   kernel
	sudo pic32prog -d /dev/ttyUSB0 sys/compile/${BOARD}/vmunix.hex

.include <bsd.subdir.mk>
