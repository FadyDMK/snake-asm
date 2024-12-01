org 7c00h       
jmp game_setup	;go directly to the game_setup

;;SNAKE game made for 16 bits systems.
;;You will need Qemu and Nasm to run this code.
;;To compile: make
;;To run: make run



;;TODO fix winning condition / fix reset game / add score preview?

;Constants
SNAKECOLOR:	 equ 2020h	;green snake
SCREENH:	 equ 25
SCREENW:	 equ 80
WINCOND:	 equ 10		;score needed to win
BGCOLOR:	 equ 1020h	;blue background
APPLECOLOR:	 equ 4020h	;red apple
TIMER:		 equ 046Ch
SNAKEXARRAY:	 equ 1000h	;this is where I store the X coordinates of the snake when it grows in size
SNAKEYARRAY:	 equ 2000h	;same but for Y coordinates
UP:		 equ 0
DOWN:		 equ 1
LEFT:		 equ 2
RIGHT:		 equ 3
;vars
playerX:	dw 40
playerY:	dw 12
appleX:	dw 20
appleY:	dw 12
direction:	db 4 ; 0 up, 1 down, 2 left, 3 right
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
	mov dword [ES:0000], snakeLength


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
	mov cx, [snakeLength] ;loop counter
	mov ax, SNAKECOLOR
	.snake_loop:
		;; Calculate DI based on snake position
        mov dx, [SNAKEYARRAY + bx]  ; Get the Y position
        imul dx, SCREENW            ; Multiply Y by SCREENW (row offset in cells)
        shl dx, 1                   ; Convert cell offset to byte offset (*2)
        mov di, dx                  ; Load row offset into DI
        mov dx, [SNAKEXARRAY + bx]  ; Get the X position
        shl dx, 1                   ; Convert column offset to byte offset (*2)
        add di, dx                  ; Final DI = row offset + column offset

        ;; Write snake segment to video memory
        mov [es:di], ax             ; Write the snake color and character

        add bx, 2                   ; Move to the next segment in the array
	loop .snake_loop

	;;draw apple

	imul di, [appleY], SCREENW*2 
	imul dx , [appleX], 2
	add di, dx
	mov ax, APPLECOLOR
	stosw
	
	;;controls
	mov al, [direction]
	cmp al, UP
	je move_up
	cmp al, DOWN
	je move_down
	cmp al, LEFT
	je move_left
	cmp al, RIGHT
	je move_right

	jmp update_snake

	move_up:
		dec word [playerY]
		jmp update_snake
	move_down:
		inc word [playerY]
		jmp update_snake
	move_left:
		dec word [playerX]
		jmp update_snake
	move_right:
		inc word [playerX]
		jmp update_snake		


	update_snake:
		imul bx, [snakeLength], 2
		.snake_loop:
			mov ax, [SNAKEXARRAY-2+bx]			;X value
			mov word [SNAKEXARRAY + bx], ax
			mov ax, [SNAKEYARRAY -2+ bx]			;Y value
			mov word [SNAKEYARRAY + bx ], ax
			sub bx, 2							;previous arr element
			jnz .snake_loop


	mov ax, [playerX]	;store the new head x coordinate
	mov word [SNAKEXARRAY], ax
	mov ax, [playerY]	;store the new head y coordinate
	mov word [SNAKEYARRAY], ax

	;;lose conditions
	;;1) hit the wall
	cmp word [playerY], -1
	jl game_over

	cmp word [playerY], SCREENH
	jg game_over

	cmp word [playerX], -1
	jl game_over

	cmp word [playerX], SCREENW
	jg game_over

	;;2) hit itself
	cmp word [snakeLength], 1
	je player_input

	mov bx, 2				;start at the second element of the snake
	mov cx, [snakeLength]	;loop counter
	check_snake:
		mov ax, [SNAKEXARRAY + bx]
		cmp ax, [playerX]
		jne .increment
		mov ax, [SNAKEYARRAY + bx]
		cmp ax, [playerY]
		je game_over
		.increment:
			add bx, 2
	loop check_snake



	player_input:
		mov bl, [direction]

		mov ah, 1					;func to check if key is pressed
		int 16h
		jz check_apple							;if no key is pressed, check if the snake ate the apple

		xor ah, ah
		int 16h									;get the key

		cmp al, 'w'
		je press_w
		cmp al,'s'
		je press_s
		cmp al,'a'
		je press_a
		cmp al,'d'
		je press_d

		jmp check_apple

		press_w:
			mov bl, UP
			jmp check_apple
		press_a:
			mov bl, LEFT
			jmp check_apple
		press_s:
			mov bl, DOWN
			jmp check_apple
		press_d:
			mov bl, RIGHT
			jmp check_apple
	check_apple:
		mov byte [direction], bl

		mov ax, [playerX]
		cmp ax, [appleX]
		jne delay_loop

		mov ax, [playerY]
		cmp ax, [appleY]
		jne delay_loop

		;;snake ate the apple => increase length
		inc word [snakeLength]
		cmp word [snakeLength], WINCOND
		je game_won

	next_apple:
		;;random apple position
		;;first for the X coordinate
		xor ah, ah
		int 1Ah ;we use timer as seed for random number
		mov ax, dx
		xor dx, dx
		mov cx, SCREENW
		div cx
		mov word [appleX], dx

		;;now for the Y coordinate
		xor ah, ah
		int 1Ah
		mov ax, dx
		xor dx, dx
		mov cx, SCREENH
		div cx
		mov word [appleY], dx

	;;check if apple is in a valid position
	xor bx, bx ;index for the snake array
	mov cx, [snakeLength]
	.check_apple:
		mov ax, [SNAKEXARRAY + bx]
		cmp ax, [appleX]
		jne .increment_apple
		mov ax, [SNAKEYARRAY + bx]
		cmp ax, [appleY]
		je next_apple
		.increment_apple:
			add bx, 2
	loop .check_apple

	delay_loop:
	mov bx, [TIMER]
	add bx, 2
	.delay:
		cmp [TIMER], bx
		jl .delay
jmp game_loop




;;game over and game won messages and reset
game_won:
	mov dword [ES:0000], 1F491F57h	; WI
	mov dword [ES:0004], 1F211F4Eh	; N!
	jmp reset_game
game_over:
	mov dword [ES:0000], 1F4F1F4Ch	;game over message
	mov dword [ES:0004], 1F451F53h 
	jmp reset_game
reset_game:
	xor ah, ah
	int 16h
	jmp 0fffh:0000h
	int 10h
;;bootSector padding
times 510-($-$$) db 0
dw 0AA55h



