.model small
.stack 100h
.data    

; date pentru meniu
menu db "Select an item number:",13,10
     db "1. Draw",13,10
     db "2. Number game",13,10
     db "3. Snake",13,10
     db "4. Quit",13,10  
     

; date pentru desen cu mouse
    oldX dw -1
    oldY dw 0


; date pentru guessing_game     
    number      db  90d    ; variabila cautata
 
    ;LineBreak pentru siruri
    CR          equ 13d
    LF          equ 10d
 
    ;Mesaje pentru utilizator
    prompt      db  CR, LF,'Please enter a valid number : $'
    lessMsg     db  CR, LF,'Value if Less ','$'
    moreMsg     db  CR, LF,'Value is More ', '$'
    equalMsg    db  CR, LF,'You have made fine Guess!', '$'
    overflowMsg db  CR, LF,'Error - Number out of range!', '$'
    retry       db  CR, LF,'Retry [y/n] ? ' ,'$'
 
    guess       db  0d      ; variabila pentru numarul introdus de utilizator
    errorChk    db  0d      ; variabila care verifica daca numarul introdus e in range
 
    param       label Byte         
    

    
; date pentru snake
    s_size  equ     7
    
    ; coordonatele sarpelui
    snake dw s_size dup(0)
    tail    dw      ?
    
    ; constante pentru directie
    left    equ     4bh
    right   equ     4dh
    up      equ     48h
    down    equ     50h
    
    ; directia curenta a sarpelui
    cur_dir db      right
    
    wait_time dw    0




    
.code

start proc    
; creare meniu
    MOV  ax, @data
    MOV  ds, ax
    
    call clear_screen      
    call display_menu    
        
    MOV ah, 0        
    int 16h          
       
    CMP al,'1'
    JE draw 
                
    CMP al,'2'
    JE guessing_game     
      
    CMP al,'3'
    JE snake_start 
      
    CMP al,'4'
    JE Quit
          
    

start endp

; functie pentru afisarea meniului
display_menu proc
    MOV  dx, offset menu
    MOV  ah, 9
    int  21h
    ret
display_menu endp

; functie pentru golirea ecranului
clear_screen proc
    MOV  ah, 0
    MOV  al, 3
    int  10H
    ret
clear_screen endp





; program pentru desen cu mouse-ul  
draw proc
    MOV ah, 00
    MOV al, 13h       
    int 10h
    
    ; reset mouse, pentru a-i lua pozitia
    MOV ax, 0
    int 33h
    CMP ax, 0


check_mouse_button:
    MOV ax, 3
    int 33h
    shr cx, 1       
    CMP bx, 1
    jne xor_cursor:
    MOV al, 1010b   ; culoare pixel
    jmp draw_pixel
    xor_cursor:
    CMP oldX, -1
    je not_required
    push cx
    push dx
    MOV cx, oldX
    MOV dx, oldY
    MOV ah, 0dh     ; citire(get) pixel
    int 10h
    xor al, 1111b   ; culoare pixel
    MOV ah, 0ch     ; setare pixel
    int 10h
    pop dx
    pop cx
    not_required:
    MOV ah, 0dh     ; citire(get) pixel
    int 10h
    xor al, 1111b   ; culoare pixel
    MOV oldX, cx
    MOV oldY, dx
    draw_pixel:
    MOV ah, 0ch     ; setare pixel
    int 10h
    check_esc_key:
    MOV dl, 255
    MOV ah, 6
    int 21h
    CMP al, 27      ; verificam daca este apasat esc pentru iesirea din program
    jne check_mouse_button


stop:
    MOV ax, 3       ; inapoi la modul text
    int 10h
    jmp start
    ret
               
draw endp 
 
 
 
 

; program pentru guessing_game
guessing_game proc
 
    ; setam registrii pe 0
    MOV ax, 0h
    MOV bx, 0h
    MOV cx, 0h
    MOV dx, 0h
 
    MOV BX, OFFSET guess    ; adresa variabilei 'guess' in BX
    MOV BYTE PTR [BX], 0d   ; setam 'guess'  0
 
    MOV BX, OFFSET errorChk ; adresa variabilei ce verifica eroarea in BX
    MOV BYTE PTR [BX], 0d   ; o setam 0
 
 
    MOV ax, @data           ; adresa data in AX
    MOV ds, ax              ; setam 'data segment' cu valoarea din AX (data)
    MOV dx, offset prompt   
 
    MOV ah, 9h              
    INT 21h                 
 
    MOV cl, 0h              ; setam Counter pe 0
    MOV dx, 0h              ; setam registrul de date pentru input pe 0
 
; citirea input-ului dat de user
while:
 
    CMP     cl, 5d          
    JG      endwhile        
 
    MOV     ah, 1h          
    INT     21h             
 
    CMP     al, 0Dh         ; compare valoarea citita cu 00h (Enter in ASCII)
    JE      endwhile        ; daca AL = 0Dh, Enter a fost apasat, JUMP la 'endwhile'
 
    SUB     al, 30h         ; Scadem 30h din valoarea ASCII a input-ului pentru a afla numarul 
    MOV     dl, al          
    PUSH    dx              ; punem valoarea in DX pentru a citi valoarea urmatoare
    INC     cl              ; incrementam counter-ul
 
    JMP while               
                          

; sfarsitul citirii input-ului dat de user                          
endwhile:
 
    DEC cl                  ; decrementam counter-ul pentru a contracara incrementarea din ultima iteratie a while-ului
 
    CMP cl, 02h             ; comparam counter-ul cu 2, doar 3 numere sunt acceptate ca fiind in range
    JG  overflow            ; daca counter-ul e mai mare de 3, JUMP la overflow 
 
    MOV BX, OFFSET errorChk 
    MOV BYTE PTR [BX], cl   
 
    MOV cl, 0h              ; reinitializam counter-ul cu 0, deoarece va fi folosit in continuare
             
             
; procesarea input-ului
while2:
 
    CMP cl,errorChk
    JG endwhile2
 
    POP dx                 
 
    MOV ch, 0h              
    MOV al, 1d              
    MOV dh, 10d             
 
 
 while3:
 
    CMP ch, cl             
    JGE endwhile3           ; daca CH >= CL, JUMP la endwhile3
 
    MUL dh                  
 
    INC ch                 
    JMP while3
 
 
 endwhile3:
 
    MUL dl                  ; AX = AL * DL, va fi pozitia actuala a numarului
 
    JO  overflow            ; daca este overflow JUMP la overflow (valori peste 300)
 
    MOV dl, al             
    ADD dl, guess           ; adaugam rezultatul la valoarea variabilei 'guess'
 
    JC  overflow            
 
    MOV BX, OFFSET guess    ; punem adresa variabilei 'guess' in BX
    MOV BYTE PTR [BX], dl   
 
    INC cl                  ; incrementam counter-ul
 
    JMP while2              ; JUMP la while2   
    
        
; sfarsitul procesarii input-ului 
endwhile2:
 
    MOV ax, @data            
    MOV ds, ax              
 
    MOV dl, number          ; punem numarul original in DL
    MOV dh, guess           ; punem numarul ghicit in DH
 
    CMP dh, dl              ; le comparam
   
    ;rezultatul compararii
    JC greater              
    JE equal                
    JG lower                
 
equal:
 
    MOV dx, offset equalMsg 
    MOV ah, 9h              
    INT 21h                 
    JMP exit                ; odata ce valoarea a fost introdusa corect, JUMP la exit
 
greater:
 
    MOV dx, offset moreMsg  
    MOV ah, 9h              
    INT 21h                 
    JMP guessing_game       ; ne intoarcem in program pana valoarea este ghicita        
          
         
lower:
 
    MOV dx, offset lessMsg  
    MOV ah, 9h              
    INT 21h                 
    JMP guessing_game               
 
overflow:
 
    MOV dx, offset overflowMsg 
    MOV ah, 9h              
    INT 21h                 
    JMP guessing_game               

 
exit:
 
; intrebam user-ul daca vrea sa incerce din nou
retry_while:
 
    MOV dx, offset retry    ; incarcam mesajul in DX
 
    MOV ah, 9h             
    INT 21h                
 
    MOV ah, 1h              
    INT 21h                 
 
    CMP al, 6Eh             ; verificam daca inpu-ul este 'n' (nu)
    JE return_to_menu       ; ne intoarcem la meniu
 
    CMP al, 79h             ; verificam daca input-ul este 'y' (da)
    JE restart              ; restartam jocul
                            
    JMP retry_while         ; daca input-ul nu este nici 'n', nici 'y', se repeta intrebarea
 
retry_endwhile:
 
restart:
    JMP guessing_game               ; JUMP la inceputul programului pentru restart

return_to_menu:  
    call clear_screen
    JMP start 
    ret  
    
guessing_game endp



    

; incepem jocul snake
snake_start proc

MOV     ah, 1
MOV     ch, 2bh
MOV     cl, 0bh
int     10h           


game_loop:

MOV     al, 0  
MOV     ah, 05h
int     10h

; afisarea capului
MOV     dx, snake[0]

; setam cursor-ul
MOV     ah, 02h
int     10h

; printam '*' la locatia respectiva
MOV     al, '*'
MOV     ah, 09h
MOV     bl, 0eh 
MOV     cx, 1   
int     10h

; pastrarea cozii
MOV     ax, snake[s_size * 2 - 2]
MOV     tail, ax

call    MOVe_snake


; stergem pozitia precedenta a cozii
MOV     dx, tail

; setam cursor-ul
MOV     ah, 02h
int     10h

; printam ' ' la locatia respectiva
MOV     al, ' '
MOV     ah, 09h
MOV     bl, 0eh 
MOV     cx, 1   
int     10h


; verificam comenzile user-ului
check_for_key:

MOV     ah, 01h
int     16h
jz      no_key

MOV     ah, 00h
int     16h

CMP     al, 1bh    ; in cazul in care este apasat esc oprim jocul
je      stop_game  

MOV     cur_dir, ah


; asteptam in cazul in care nu exista input
no_key:

MOV     ah, 00h
int     1ah
CMP     dx, wait_time
jb      check_for_key
add     dx, 4
MOV     wait_time, dx


; folosim un game loop infinit
jmp     game_loop


; oprim jocul si ne intoarcem la meniu
stop_game:

call clear_screen
jmp start
ret 

snake_start endp



; program pentru miscarea sarpelui
move_snake proc near

MOV     ax, 40h
MOV     es, ax

  ; punem DI pe coada
  MOV   di, s_size * 2 - 2
  ; mutam toate partile corpului (coada veche este stearsa)
  MOV   cx, s_size-1
  move_array:
  MOV   ax, snake[di-2]
  MOV   snake[di], ax
  sub   di, 2
  loop  MOVe_array


  CMP   cur_dir, left
  je    MOVe_left
  CMP   cur_dir, right
  je    MOVe_right
  CMP   cur_dir, up
  je    MOVe_up
  CMP   cur_dir, down
  je    MOVe_down

  jmp     stop_MOVe       ; nici o directie


move_left:
  MOV   al, b.snake[0]
  dec   al
  MOV   b.snake[0], al
  CMP   al, -1
  jne   stop_MOVe       
  MOV   al, es:[4ah]    
  dec   al
  MOV   b.snake[0], al  
  jmp   stop_MOVe

move_right:
  MOV   al, b.snake[0]
  inc   al
  MOV   b.snake[0], al
  CMP   al, es:[4ah]      
  jb    stop_MOVe
  MOV   b.snake[0], 0   
  jmp   stop_MOVe

move_up:
  MOV   al, b.snake[1]
  dec   al
  MOV   b.snake[1], al
  CMP   al, -1
  jne   stop_MOVe
  MOV   al, es:[84h]    
  MOV   b.snake[1], al  
  jmp   stop_MOVe

move_down:
  MOV   al, b.snake[1]
  inc   al
  MOV   b.snake[1], al
  CMP   al, es:[84h]    
  jbe   stop_MOVe
  MOV   b.snake[1], 0   
  jmp   stop_MOVe

stop_move:
  ret        
  
  CMP  al,'0'
  call clear_screen
  jmp start
  
move_snake endp





; program pentru Quit din meniu
Quit proc
   MOV   ah,4ch
   int   21h
   ret
quit endp