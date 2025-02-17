name := kayprint

build:
	# Assemble program
	#scas --listing out/kayprint.list kayprint.asm out/kayprint.com 
	#../spasm-ng/spasm -T kayprint.asm
	#mv kayprint.bin out/kayprint.com
	#mv kayprint.lst out/kayprint.lst
	z88dk-z80asm -O=out -b -l -m $(name).asm
	# Create disk image
	z88dk-appmake +cpmdisk -f kayproii -b out/$(name).bin -o out/$(name).dsk

run: build
	/usr/bin/mame \
		-rompath roms \
		-output console \
		-bios 232 kayproii \
		-flop1 disks/stuff-master.mfi \
		-flop2 out/$(name).dsk \
		-serial null_modem \
		-bitbanger socket.127.0.0.1:2023 \
		-verbose \
		-w -nomax \
		-cheat

debug: build
	/usr/bin/mame \
		-rompath roms \
		-output console \
		-bios 232 kayproii \
		-flop1 disks/stuff-master.mfi \
		-flop2 out/$(name).dsk \
		-serial null_modem \
		-bitbanger socket.127.0.0.1:2023 \
		-verbose \
		-w -nomax \
		-cheat \
		-debugger gdbstub \
		-debug \
		-debugger_port 12000

clean:
	rm out/*