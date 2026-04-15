; COAL TETRIS Game Project Phase 2
; Made by Muhammad Abdul Rehman and Aiman Aslam
[org 0x0100]

jmp start

gameAreaTopRow: dw 0
gameAreaTopCol: dw 25

gameAreaWidth: dw 15 ; blocks
gameAreaHeight: dw 25

clearBlock: dw 0 ; used to wether to clear the block or not when drawing
blockColor: dw 0x70 ; current color of the block to be printed

isBlockActive: dw 0 ; is block moving?
activeBlockRow: dw 0 ; row of active block
activeBlockCol: dw 0 ; col of active block
activeBlockType: dw 0 ; type of active block ; 0 = O, 1 = I, 2 = S, 3 = L
direction: dw 0 ; -1 = left, 1 = right

isGameOver: dw 1

oldTSR: dd 0 ; old timer service routine

; clears the screen
; void cls()
cls:
    push ax
    push cx
    push di

    mov di, 0
    mov ax, 0x0020
    mov cx, 2000
    
    cld
    REP STOSW

    pop di
    pop cx
    pop ax
ret

; fills the screen with white
; void fls()
fls:
    push ax
    push cx
    push di

    mov di, 0
    mov ax, 0x7020
    mov cx, 2000
    
    cld
    REP STOSW

    pop di
    pop cx
    pop ax
ret

; calculates and updates DI for the given row and col
; void getDI(row, col)
getDI:
    push bp
    mov bp, sp
    push ax
    push bx
    push dx

    mov ax, [bp+6] ; row
    mov bx, [bp+4] ; col

    mov dx, 80
    mul dx ; ax = ax * dx = row * 80

    add ax, bx; ax = ax + bx = row * 80 + col

    shl ax, 1 ; ax = ax * 2 = (row * 80 + col) * 2

    mov di, ax

    pop dx
    pop bx
    pop ax
    pop bp
ret 4

; a function that prints a number that was passed as a param, not updating di after 
; void printNumber(number)
printNumber: 
    push bp 
    mov bp, sp 
    push ax
    push bx
    push cx
    push dx

    mov ax, [bp+4] 
    mov bx, 10 

    mov cx, 0 
    digitToAscii: 
        mov dx, 0 
        div bx 
        add dl, 0x30 
        push dx 

        inc cx 
        cmp ax, 0 
    jnz digitToAscii

    printN: 
        pop dx 
        mov dh, 01110000b 
        ; mov dh, 0x07 
        mov [es:di], dx 
        add di, 2 
    loop printN 

    pop dx
    pop cx
    pop bx
    pop ax
    pop bp 
ret 2 

; printStr(address of string) till null char, not updating di after 
; void printStr(row, col, string)
printStr: 
    push bp 
    mov bp, sp 
    push ax
    push cx
    push si

    mov ah, 01110000b ; attribute
    ; mov ax, 0x0700 ; attribute
    mov si, [cs:bp+4] ; address of string

    push word [cs:bp+8]
    push word [cs:bp+6]
    call getDI

    printString:
        lodsb
        cmp al, 0
        je printStrDone
        stosw
    jmp printString

    printStrDone:
    pop si
    pop cx
    pop ax
    pop bp 
ret 6

; prints string till null char, also adds -'s on the next line, not updating di 
; void printDottedStr(row, col, string)
printDottedStr: 
    push bp 
    mov bp, sp 
    push ax
    push cx
    push si

    mov ah, 01110000b ; attribute

    mov si, [cs:bp+4] 

    push word [cs:bp+8]
    push word [cs:bp+6]
    call getDI

    printDottedString:
        lodsb
        cmp al, 0
        je printDottedStrDone
        ; stosw
        mov [es:di], ax

        mov al, '-'
        add di, 160
        mov [es:di], ax

        sub di, 160

        add di, 2

    jmp printDottedString

    printDottedStrDone:
    pop si
    pop cx
    pop ax
    pop bp 
ret 6

txtTitle: db     "   COAL TETRIS   ", 0
txtHowToPlay: db "      Goal       ", 0
txtHTP1: db      "  Fill as many   ", 0
txtHTP2: db " rows as you can ", 0
txtHTP3: db " before the time ", 0
txtHTP4: db "     runs out    ", 0
txtHTP5: db "      Rules      ", 0
txtHTP6: db "     5 minutes   ", 0
txtHTP7: db " +10 points/line ", 0
txtHTP8: db "    Have Fun!    ", 0
txtTimeLeft: db " Time left     :   ", 0
txtScore: db        " Score             ", 0
txtNextShape: db    "    Next Shape     ", 0
; draws the borders and other UI elements
drawUI:
    push di
    
    push 0 ; row
    push 55 ; col
    push 25 ; width
    push 25 ; height
    call drawRect ; right fill

  ; Time left string
    mov di, 602
    push 3
    push 58
    push txtTimeLeft
    call printDottedStr

     ; Score string
    push 8
    push 58
    push txtScore
    call printDottedStr

    ; next Shape string
    push 15
    push 58
    push txtNextShape
    call printDottedStr

    push word [Score]
    mov di, 1424
    call printNumber

    call printTime

    ; How to play string
    push 0 ; row
    push 0 ; col
    push 25 ; width
    push 25 ; height
    call drawRect

    push 3
    push 4
    push txtTitle
    call printStr

    push 1+5
    push 4
    push txtHowToPlay
    call printDottedStr

    push 2+6
    push 4
    push txtHTP1
    call printStr

    push 3+6
    push 4
    push txtHTP2
    call printStr

    push 4+6
    push 4
    push txtHTP3
    call printStr

    push 5+6
    push 4
    push txtHTP4
    call printStr

    push 8+7
    push 4
    push txtHTP5
    call printDottedStr

    push 9+8
    push 4
    push txtHTP6
    call printStr

    push 10+8
    push 4
    push txtHTP7
    call printStr

    push 22
    push 4
    push txtHTP8
    call printDottedStr

    pop di
ret

; draws a rectangle at the given position, relative to the screen
; void drawRect(row, col, width, height)
drawRect:
    push bp
    mov bp, sp
    push ax
    push cx
    push di

    ; [bp+10] = row
    ; [bp+8]  = col
    ; [bp+6]  = width
    ; [bp+4]  = height

    mov cx, [bp+4]
    
    rowing:
        push word[bp+10]
        push word[bp+8] 
        call getDI

        push cx
        mov cx, [bp+6]
        coling: 
            mov ax, 0x7020
            stosw
        loop coling
        pop cx

        add word[bp+10], 1

    loop rowing

    pop di
    pop cx
    pop ax
    pop bp
ret 8

; draws a single block of size 1 row and 2 cols at the given position, relative to the game area
; void drawBlock(row, col)
drawBlock:
    push bp
    mov bp, sp
    push ax
    push bx
    push di

    mov ax, [bp+6] ; row
    add ax, [gameAreaTopRow]
    mov bx, [bp+4] ; col
    shl bx, 1
    add bx, [gameAreaTopCol]


    push ax
    push bx
    call getDI

    mov ax, 0x7020 ; white on black
    mov ah, [blockColor]

    cmp word [clearBlock], 1
    jne drawBlockNormal
    mov ah, 00000000b
    drawBlockNormal:

    stosw
    stosw

    pop di
    pop bx
    pop ax
    pop bp
ret 4

; checks if the block at the given position is empty i.e all black pixels
; bool isBlockEmpty(row, col)
isBlockEmpty:
    push bp
    mov bp, sp
    push ax
    push bx
    push di

    mov ax, [bp+6] ; row
    add ax, [gameAreaTopRow]
    mov bx, [bp+4] ; col
    shl bx, 1
    add bx, [gameAreaTopCol]

    push ax
    push bx
    call getDI

    inc di
    cmp byte [es:di], 00000000b
    jne isBlockEmptyNot

    add di, 2
    cmp byte [es:di], 00000000b
    jne isBlockEmptyNot

    mov word [bp+8], 1
    jmp isBlockEmptyEnd
    isBlockEmptyNot:
    mov word [bp+8], 0

    isBlockEmptyEnd:
    pop di
    pop bx
    pop ax
    pop bp
ret 4

; checks if the I shape can be drawn at the given position (if space below it is empty)
; bool canDrawBlockI(row, col)
canDrawBlockI:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx


    mov ax, [bp+6] ; row
    mov bx, [bp+4] ; col

    mov word [bp + 8], 1 ; assume block can be drawn

    mov cx, 4

    canDrawBlockILoop:
        sub sp, 2
        push ax ; row
        push bx ; col
        call isBlockEmpty
        pop dx

        cmp dx, 0 ; block not empty
        je cantDrawBlockIEnd

        dec ax ; row--

    loop canDrawBlockILoop

    jmp canDrawBlockIEnd
    cantDrawBlockIEnd:
        mov word [bp + 8], 0
    canDrawBlockIEnd:
 
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
ret 4

; Draws the I shape at the given position
; void drawBlockI(row, col)
drawBlockI:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    mov word [blockColor], 00100000b

    mov ax, [bp+6] ; row
    mov bx, [bp+4] ; col

    mov cx, 4

    drawBlockILoop:
        push ax ; row
        push bx ; col
        call drawBlock

        dec ax ; row--

    loop drawBlockILoop

 
    mov word [blockColor], 0x70  
    pop cx
    pop bx
    pop ax
    pop bp
ret 4

; draws the S shape at the given position
; void drawBlockS(row, col)
drawBlockS:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    mov word [blockColor], 01100000b

    mov ax, [bp+6] ; row
    mov bx, [bp+4] ; col

    mov cx, 2

    drawBlockSLoop:
        push ax ; row
        push bx ; col
        call drawBlock

        add bx, 1 ; col++
        push ax ; row
        push bx ; col
        call drawBlock

        dec ax; row--

    loop drawBlockSLoop

    mov word [blockColor], 0x70
    pop cx
    pop bx
    pop ax
    pop bp
ret 4

; checks if the S shape can be drawn at the given position (if space below it is empty)
; bool canDrawBlockS(row, col)
canDrawBlockS:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx

    mov ax, [bp+6] ; row
    mov bx, [bp+4] ; col

    mov word [bp + 8], 1 ; assume block can be drawn

    mov cx, 2

    canDrawBlockSLoop:
        sub sp, 2
        push ax ; row
        push bx ; col
        call isBlockEmpty
        pop dx

        cmp dx, 0 ; block not empty
        je cantDrawBlockSEnd

        add bx, 1 ; col++
        sub sp, 2
        push ax ; row
        push bx ; col
        call isBlockEmpty
        pop dx

        cmp dx, 0 ; block not empty
        je cantDrawBlockSEnd

        dec ax ; row--

    loop canDrawBlockSLoop

    jmp canDrawBlockSEnd
    cantDrawBlockSEnd:
        mov word [bp + 8], 0
    canDrawBlockSEnd:
 
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
ret 4

; draws the O shape at the given position
; void drawBlockO(row, col)
drawBlockO:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    mov word [blockColor], 01000000b

    mov ax, [bp+6] ; row

    mov cx, 2

    drawBlockOLoop:
        mov bx, [bp+4] ; col

        push ax ; row
        push bx ; col
        call drawBlock

        add bx, 1 ; col++
        push ax ; row
        push bx ; col
        call drawBlock

        dec ax ; row--

    loop drawBlockOLoop

    mov word [blockColor], 0x70
    pop cx
    pop bx
    pop ax
    pop bp
ret 4

; checks if the O shape can be drawn at the given position (if space below it is empty)
; bool canDrawBlockO(row, col)
canDrawBlockO:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx

    mov ax, [bp+6] ; row

    mov word [bp + 8], 1 ; assume block can be drawn

    mov cx, 2

    canDrawBlockOLoop:
        mov bx, [bp+4] ; col
        sub sp, 2
        push ax ; row
        push bx ; col
        call isBlockEmpty
        pop dx

        cmp dx, 0 ; block not empty
        je cantDrawBlockOEnd

        add bx, 1 ; col++
        sub sp, 2
        push ax ; row
        push bx ; col
        call isBlockEmpty
        pop dx

        cmp dx, 0 ; block not empty
        je cantDrawBlockOEnd

        dec ax ; row--

    loop canDrawBlockOLoop

    jmp canDrawBlockOEnd
    cantDrawBlockOEnd:
        mov word [bp + 8], 0
    canDrawBlockOEnd:
 
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
ret 4

; draws the L shape at the given position
; void drawBlockL(row, col)
drawBlockL:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    mov word [blockColor], 00010000b
    

    mov ax, [bp+6] ; row
    mov bx, [bp+4] ; col

    mov cx, 3

    drawBlockLLoop:
        push ax ; row
        push bx ; col
        call drawBlock

        dec ax; row--

    loop drawBlockLLoop

    mov ax, [bp+6] ; row
    inc bx
    push ax ; row
    push bx ; col
    call drawBlock

    mov word [blockColor], 0x70
    pop cx
    pop bx
    pop ax
    pop bp
ret 4

; checks if the L shape can be drawn at the given position (if space below it is empty)
; bool canDrawBlockL(row, col)
canDrawBlockL:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx

    mov ax, [bp+6] ; row
    mov bx, [bp+4] ; col

    mov word [bp + 8], 1 ; assume block can be drawn

    mov cx, 3

    canDrawBlockLLoop:
        sub sp, 2
        push ax ; row
        push bx ; col
        call isBlockEmpty
        pop dx

        cmp dx, 0 ; block not empty
        je cantDrawBlockLEnd

        dec ax ; row--

    loop canDrawBlockLLoop

    mov ax, [bp+6] ; row
    inc bx
    sub sp, 2
    push ax ; row
    push bx ; col
    call isBlockEmpty
    pop dx

    cmp dx, 0 ; block not empty
    je cantDrawBlockLEnd


    jmp canDrawBlockLEnd
    cantDrawBlockLEnd:
        mov word [bp + 8], 0
    canDrawBlockLEnd:
 
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
ret 4

; draws a block (same type that is currently active) at the given position
; void drawBlockObject(row, col)
drawBlockObject:
    push bp
    mov bp, sp
    push dx

    push word [bp+6] ; row
    push word [bp+4] ; col
    
    mov dx, [activeBlockType]
    cmp dx, 0 ; O
    je drawBlockObject_O
    cmp dx, 1 ; I
    je drawBlockObject_I
    cmp dx, 2 ; S
    je drawBlockObject_S
    cmp dx, 3 ; L
    je drawBlockObject_L

    mov word [activeBlockType], 0 ; default to O if no match

    drawBlockObject_O:
        call drawBlockO
        jmp drawBlockObjectEnd

    drawBlockObject_I:
        call drawBlockI
        jmp drawBlockObjectEnd

    drawBlockObject_S:
        call drawBlockS
        jmp drawBlockObjectEnd

    drawBlockObject_L:
        call drawBlockL
        jmp drawBlockObjectEnd

    drawBlockObjectEnd:
    mov word [blockColor], 0x70

    pop dx
    pop bp
ret 4

; redraws the upcoming shape in the next block container
; void drawNextBlock()
drawNextBlock:
    push dx

    ; next block container
    push 18 ; row
    push 59 ; col
    push 18 ; width
    push 6 ; height
    call drawRect

    mov dx, [activeBlockType]
    cmp dx, 0 ; O
    je drawNextBlock_I
    cmp dx, 1 ; I
    je drawNextBlock_S
    cmp dx, 2 ; S
    je drawNextBlock_L
    cmp dx, 3 ; L
    je drawNextBlock_O

    mov word [activeBlockType], 0 ; default to O if no match

    drawNextBlock_O:
        push word 20
        push word 20
        call drawBlockO
        jmp drawNextBlockEnd

    drawNextBlock_I:
        push word 21
        push word 21
        call drawBlockI
        jmp drawNextBlockEnd

    drawNextBlock_S:
        push word 20
        push word 20
        call drawBlockS
        jmp drawNextBlockEnd

    drawNextBlock_L:
        push word 21
        push word 20
        call drawBlockL
        jmp drawNextBlockEnd

    drawNextBlockEnd:
    pop dx
ret

txtGameOver: db   " Game Over! ", 0
txtTFP: db        " Thanks for playing! ", 0
txtFinalScore: db " Final Score:     ", 0
; draws the game ending screen
; void drawGameOver()
drawGameOver:

    call fls

    push 4
    push 34
    push txtGameOver
    call printDottedStr

    push 12
    push 31
    push txtFinalScore
    call printDottedStr

    push 12
    push 45
    call getDI
    push word [Score]
    call printNumber

    push 20
    push 29
    push txtTFP
    call printDottedStr

ret

; prints the time left in mm:ss format
; void printTime()
printTime:
    push ax
    push bx
    push dx
    push di

    mov ax, 0xb800
    mov es, ax
    mov di, 624

    mov ax, [cs:timeLeft]
    mov dx, 0
    mov bx, 60
    div bx

    push ax
    call printNumber
    add di, 2
    push dx
    call printNumber

    mov ax, 0x7020
    stosw

    pop di
    pop dx
    pop bx
    pop ax
ret

; checks if left or right key was pressed and sets direction accordingly
; void handleInput()
handleInput:
    push ax

    in al, 0x60
    cmp al, 0x4b ; left
    je handleInputLeft
    cmp al, 0x4d ; right
    je handleInputRight
    jmp handleInputEnd

    handleInputLeft:
    mov word [direction], -1
    jmp handleInputEnd

    handleInputRight:
    mov word [direction], 1
    jmp handleInputEnd

    handleInputEnd:

    pop ax
ret

; called every timer tick
; void OnUpdate()
OnUpdate:
    call handleInput
ret

; checks if the current active block type can be drawn at the given position
; bool canDrawNext(row, col)
canDrawNext:
    push bp
    mov bp, sp
    push ax
    push bx
    push dx

    mov word[bp + 8], 1 ; assume block can be drawn

    mov ax, word [bp + 6]
    mov bx, word [bp + 4]

    cmp ax, 25 ; check if block is at bottom
    jge canDrawNext_cant_stop

    sub sp, 2
    push ax 
    push bx

    mov dx, [activeBlockType]
    cmp dx, 0 ; O
    je canDrawNext_O
    cmp dx, 1 ; I
    je canDrawNext_I
    cmp dx, 2 ; S
    je canDrawNext_S
    cmp dx, 3 ; L
    je canDrawNext_L

    mov word [activeBlockType], 0 ; default to O if no match

    canDrawNext_O:
        call canDrawBlockO
        jmp canDrawNextEnd

    canDrawNext_I:
        call canDrawBlockI
        jmp canDrawNextEnd

    canDrawNext_S:
        call canDrawBlockS
        jmp canDrawNextEnd

    canDrawNext_L:
        call canDrawBlockL
        jmp canDrawNextEnd

    canDrawNextEnd:

    pop dx

    cmp dx, 0
    jne canDrawNext_can

    canDrawNext_cant_stop:

    mov word[bp + 8], 0

    canDrawNext_can:

    pop dx
    pop bx
    pop ax
    pop bp
ret 4

; Checks and move the block to the next position if possible (no colissions)
; bool handleColission()
handleColission:
    push ax
    push bx
    push dx

    mov ax, [cs:activeBlockRow]
    mov bx, [cs:activeBlockCol]

    ; check with sides

    add ax, 1
    add bx, [cs:direction]

    sub sp, 2
    push ax
    push bx
    call canDrawNext
    pop dx

    cmp dx, 0
    je handleColission_cantBothDir
    jmp handleColission_canBothDir

    handleColission_canBothDir:
        mov word [cs:direction], 0
        mov word [cs:activeBlockRow], ax
        mov word [cs:activeBlockCol], bx
        jmp handleColission_End

    handleColission_cantBothDir:
        sub bx, [cs:direction]

        sub sp, 2
        push ax
        push bx
        call canDrawNext
        pop dx

        cmp dx, 0
        je handleColission_cantOneDir
        jmp handleColission_canOneDir

        handleColission_canOneDir:
            mov word [cs:activeBlockRow], ax
            mov word [cs:activeBlockCol], bx
            mov word [cs:direction], 0 ; reset direction
            jmp handleColission_End

        handleColission_cantOneDir:
            mov word [cs:isBlockActive], 0 ; is block active? move block down

    handleColission_End:

    pop dx
    pop bx
    pop ax
ret

; 0 - 25
; checks if a rowin the play area is filled
; bool isLineFilled(row)
isLineFilled:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push di

    mov word [bp+6], 1

    mov ax, [bp+4] ; row
    mov bx, [gameAreaTopCol]

    push ax
    push bx
    call getDI

    mov cx, [gameAreaWidth]

    mov ax, 0x6020

    scoring:
        cmp byte [es:di+1], 00000000b
        je isLineFilled_notFilled

        add di, 4
    loop scoring

    jmp isLineFilled_End
    isLineFilled_notFilled:
        mov word [bp+6], 0
        jmp isLineFilled_End

    isLineFilled_End:

    pop di
    pop cx
    pop bx
    pop ax
    pop bp
ret 2

; checks if a row in the play area is empty
; bool isLineEmpty(row)
isLineEmpty:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push di

    mov word [bp+6], 1

    mov ax, [bp+4] ; row
    mov bx, [gameAreaTopCol]

    push ax
    push bx
    call getDI

    mov cx, [gameAreaWidth]


    isLineEmpty_check:
        cmp byte [es:di+1], 00000000b
        jne isLineEmpty_filled

        add di, 4
    loop isLineEmpty_check

    jmp isLineEmpty_End
    isLineEmpty_filled:
        mov word [bp+6], 0
        jmp isLineEmpty_End

    isLineEmpty_End:

    pop di
    pop cx
    pop bx
    pop ax
    pop bp
ret 2

; clears all the blocks in the given row
; void clearLine(row)
clearLine:
    push bp
    mov bp, sp
    push ax
    push cx
    push ds


    mov ax, [bp+4] ; row

    mov cx, 0

    mov word [cs:clearBlock], 1

    clearLine_l1:
        push ax
        push cx
        call drawBlock

        inc cx
        cmp cx, 15
        jne clearLine_l1

    mov word [cs:clearBlock], 0

    ; move blocks down

    push es
    pop ds

    ; add cx, 
    mov cx, 25

    movingLoop:
        push ax
        push cx
        call getDI

        mov si, di
        sub si, 160

        push cx
        mov cx, 30
        rep movsw
        pop cx

        dec ax
        cmp ax, 0
        jne movingLoop


    pop ds
    pop cx
    pop ax
    pop bp
ret 2

; checks if any row is filled and clears it and adds 10 to the score 
; also scrolls the game area down
; void handleScore()
handleScore:
    push ax
    push cx
    push di

    mov ax, 0xb800
    mov es, ax

    mov cx, 0

    handleScore_l1:
        sub sp, 2
        push cx ; row
        call isLineFilled
        pop dx

        cmp dx, 1
        je handleScore_lineFilled
        jne handleScore_lineNotFilled

        handleScore_lineFilled:
            add word [Score], 10
            push word [Score]
            mov di, 1424
            call printNumber

            push cx ; row
            call clearLine

        handleScore_lineNotFilled:

        inc cx
        cmp cx, 25
        jne handleScore_l1

    pop di
    pop cx
    pop ax
ret

; checks if the top row is filled and ends the game if it is
; void handleTopRow()
handleTopRow:
    push dx
    sub sp, 2
    push 0
    call isLineEmpty
    pop dx

    cmp dx, 1 ; if line is empty
    jne handleTopRow_gameOver

    jmp handleTopRow_end
    handleTopRow_gameOver:
        mov word [cs:isGameOver], 1
        jmp handleTopRow_end

    handleTopRow_end:

    pop dx
ret

; called every drawing frame interval
; void OnFixedUpdate()
OnFixedUpdate:

    cmp word [cs:isBlockActive], 1 ; is block active? move block down
    jne OnFixedUpdate_BlockIsNotActive

    ; clear previous block
    mov word [cs:clearBlock], 1
    push word [cs:activeBlockRow]
    push word [cs:activeBlockCol]
    call drawBlockObject

    call handleColission ; handle if any colissions and move block down

    ; redraw 
    mov word [cs:clearBlock], 0
    push word [cs:activeBlockRow]
    push word [cs:activeBlockCol]
    call drawBlockObject

    jmp OnFixedUpdateEnd
    OnFixedUpdate_BlockIsNotActive: ; add new block

        call handleTopRow
        call handleScore

        add word [activeBlockType], 1 ; activeBlockType++

        mov ax, 1

        sub sp, 2
        call rand
        pop dx
        add ax, dx 
        add ax, dx 
        add ax, dx 

        mov word [cs:clearBlock], 0
        mov word [cs:activeBlockRow], 0
        mov word [cs:activeBlockCol], ax
        push word [cs:activeBlockRow]
        push word [cs:activeBlockCol]
        call drawBlockObject

        mov word [cs:isBlockActive], 1
        call drawNextBlock

    OnFixedUpdateEnd:

ret 

Score: dw 0
timeLeft: dw 60 * 5 ; 5 minutes
timerTick: dw 0
drawingTick: dw 0
Timer:
    pusha

    cmp word [cs:isGameOver], 1 ; is game over?
    je gameOverEnd

    add word [cs:timerTick], 1
    add word [cs:drawingTick], 1

    ; -- -- -- -- 

    cmp word [cs:timerTick], 18 ; if timerTick <= 18
    jle timerTickEnd

    mov word [cs:timerTick], 0
    sub word [cs:timeLeft], 1

    call printTime

    timerTickEnd:

    ; -- -- -- --

    cmp word [cs:drawingTick], 2 ; if drawingTick <= 2
    jle drawingTickEnd

    mov word [cs:drawingTick], 0

    call OnFixedUpdate

    drawingTickEnd:


    ; -- -- -- -- 

    cmp word [cs:timeLeft], 0 ; if timeLeft > 0 
    jg timerEnd

    mov word [cs:isGameOver], 1 ; game over

    ; -- -- -- -- 

    timerEnd:

    call OnUpdate

    gameOverEnd: ; do nothign if game is over

    popa
    jmp far [cs:oldTSR]

; returns a random number between 0 and 3
; int rand()
rand:
    push bp
    mov bp, sp
    push ax
    push cx
    push dx

    mov ah, 00h
    int 1ah

    randLoop:
    mov ax, dx
    xor dx,dx
    mov cx, 4
    div cx

    cmp dx, 3
    jg randLoop

    mov word [bp+4], dx

    pop dx
    pop cx
    pop ax
    pop bp
ret

txtStart1: db " Press Any Key to Start ", 0
txtStart2: db " Tetris Game - Made by Muhammad Abdul Rehman and Aiman Aslam ", 0
; game area 23 rows and 30 cols (15 if blocks)
start:

    ; setup graphics mode
    push word 0xb800
    pop es

    call fls

    push 10 ; row
    push 28 ; col
    push txtStart1
    call printStr

    push 20 ; row
    push 9 ; col
    push txtStart2
    call printDottedStr
    
    mov ah, 0
    int 16h

    sub sp, 2
    call rand
    pop word [cs:activeBlockType] ; randomize active block type

    ; Hooking custom Timer interrupt, also saving the old one for chaining
    mov ax, 0
    mov es, ax

    mov ax, [es:8*4]
    mov word [cs:oldTSR], ax
    mov ax, [es:8*4+2]
    mov word [cs:oldTSR+2], ax
    cli
    mov word [es:8*4], Timer
    mov word [es:8*4+2], cs
    sti

    ; setup graphics mode
    push word 0xb800
    pop es
    
    call cls

    call drawUI

    mov word [cs:isGameOver], 0 ; start game

    ; infinite loop till game is over
    infi:
    cmp word[isGameOver], 1
    jne infi

    call drawGameOver

    ; Un hooking the timer isr
    mov ax, 0
    mov es, ax

    mov ax, [oldTSR]
    mov bx, [oldTSR + 2]
    cli
    mov word [es:8*4], ax
    mov word [es:8*4+2], bx
    sti

mov ax,0x4c00
int 0x21 