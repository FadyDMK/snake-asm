snake.bin: snake.asm
	nasm snake.asm -f bin -o snake.bin
snake.com: snake.asm
	nasm snake.asm -o snake.com -f bin

snake.img: snake.bin
	dd if=/dev/null of=snake.img count=1 bs=512
	dd if=snake.bin of=snake.img conv=notrunc
	touch run

run: snake.bin
	qemu-system-i386 -hda snake.bin

clean:
	rm *.bin *.img *.com run
