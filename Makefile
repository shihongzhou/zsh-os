BUILD:=./build

HD_IMG_NAME:= "hd.img"
FLOPPY_IMG_NAME = floppy.img

all: ${BUILD}/boot/boot.o #${BUILD}/boot/setup.o
#	$(shell rm -rf $(HD_IMG_NAME))
#	bximage -q -hd=16 -func=create -sectsize=512 -imgmode=flat $(HD_IMG_NAME)
#	dd if=${BUILD}/boot/boot.o of=hd.img bs=512 seek=0 count=1 conv=notrunc
	$(shell rm -rf $(FLOPPY_IMG_NAME))
	bximage -q -fd=1.44M -func=create $(FLOPPY_IMG_NAME)
	dd if=${BUILD}/boot/boot.o of=$(FLOPPY_IMG_NAME) bs=512 seek=0 count=1 conv=notrunc
	echo -n "Hello, Floppy!" | dd of=$(FLOPPY_IMG_NAME) bs=512 seek=1 count=1 conv=notrunc

	#dd if=${BUILD}/boot/boot.o of=hd.img bs=512 seek=1 count=2 conv=notrunc

${BUILD}/boot/%.o: %.asm
	$(shell mkdir -p ${BUILD}/boot)
	nasm $< -o $@

clean:
	$(shell rm -rf ${BUILD})

bochs: all
	bochs -q -f bochsrc

qemu: all
	qemu-system-x86_64 -hda hd.img

qemus: all
	qemu-system-x86_64 -fda floppy.img