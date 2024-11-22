org 7c00h       
jmp game_setup	;go directly to the game_setup

;Constants
SNAKECOLOR:	 equ 4020h
SCREENH:	 equ 25
SCREENW:	 equ 80
WINCOND:	 equ 10
BGCOLOR:	 equ 1020h
APPLECOLOR:	 equ 4020h
TIMER:		 equ 046Ch
SNAKEXARRAY:	 equ 1000h
SNAKEYARRAY:	 equ 2000h
;vars
playerX:	dw 40
playerY:	dw 12
appleX:	dw 20
appleY:	dw 12
direction:	db 4 ; 0 right, 1 left, 2 down, 3 up
snakeLength:	dw 1 



game_setup:
	;; These change to VGA mode 03h 80x25
	mov ax, 03h
	int 10h

	mov ax, 0B800h	;the offset to the video memory
	mov es, ax	; we can't do ops directly on es

	;;set snake head
	mov ax, [playerX]
	mov word [SNAKEXARRAY], ax
	mov ax, [playerY]
	mov word [SNAKEYARRAY], ax


	;;this part is to get rid of the cursor
	mov ah, 02h ; set cursor position
	mov dx, 2600h	;put cursor off screen
	int 10h

	
	
;loop
game_loop:
	;;clear screen
	mov ax, BGCOLOR	
	xor di, di	;start at the beginning of the screen
	mov cx, SCREENH*SCREENW 
	rep stosw	

	;;draw snake
	xor bx, bx
	mov cx, [snakeLength]
	mov ax, SNAKECOLOR
	.snake_loop:
		mov di, [SNAKEYARRAY + bx]
		shl di, 1
		add di, [SNAKEXARRAY + bx]
		mov word [es:di], ax
		inc bx
		loop .snake_loop	

jmp game_loop
;;bootSector padding
times 510-($-$$) db 0
dw 0AA55h



