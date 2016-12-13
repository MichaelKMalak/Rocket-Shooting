;;=============================================================================;;   
;;                    Shooting rockets Game                                    ;;
;;                 Tested on DOSBox and emu8086                                ;;
;;=============================================================================;;
;;     Created by: Michael Khalil                               			   ;;
;;     Credit Hour system - ID:1142257                            			   ;;
;;=============================================================================;;

; ما هي اللعبة؟
; صواريخ تتحرك من اسفل لأعلى الشاشة بشكل (يبدو) عشوائي
; على اللاعب تحريك رمز لاسفل و اعلى و من خلال الضغط على مسافة يستطيع اطلق طلاقات
; فى حالة لمس الطلقة أي من الصواريخ يحتسب نقطة واحدة للاعب
;فى حالة تخطى الطلقة للصاروخ يفقد اللاعب نقطة من نقاط الحياة
; نقاط الحياة هم 6
; ف حالة تخطي اكثر من 6 صورايخ تعتبر اللعبة انتهت 
; النتيجة النهائية هي عدد الصواريخ التى ضربت خلال اللعبة الواحدة

Print MACRO row, column, color 
   push ax
   push bx
   push cx
   push dx   
   
   mov Ah, 02h
   mov Bh, 0h
   mov Dh, row
   mov Dl, column
   INT 10h 
   mov Ah, 09
   mov Al, ' '
   mov Bl, color
   mov Cx, 1h
   INT 10h   
   
   pop dx
   pop cx
   pop bx
   pop ax
ENDM Print     

PrintShooter MACRO row
   push ax
   push bx
   push cx
   push dx   
   
   mov Ah, 02h
   mov Bh, 0h
   mov Dh, row
   mov Dl, 0
   INT 10h 
   mov Ah, 09
   mov Al, '}'
   mov Bl, 02h
   mov Cx, 1h
   INT 10h   
   
   pop dx
   pop cx
   pop bx
   pop ax
ENDM PrintShooter    

PrintShot MACRO row, column
   push ax
   push bx
   push cx
   push dx   
   
   mov Ah, 02h
   mov Bh, 0h
   mov Dh, row
   mov Dl, column
   INT 10h 
   mov Ah, 09
   mov Al, 254
   mov Bl, 0Ch
   mov Cx, 1h
   INT 10h   
   
   pop dx
   pop cx
   pop bx
   pop ax
ENDM PrintShot  

PrintText Macro row , column , text
   push ax
   push bx
   push cx
   push dx   
	mov ah,2
	mov bh,0
	mov dl,column
	mov dh,row
	int 10h
	mov ah, 9
    mov dx, offset text
    int 21h
   pop dx
   pop cx
   pop bx
   pop ax
ENDM PrintText

ClearScreen MACRO
        
    ;Clear the screen    
    mov ax, 0600h  ;al=0 => Clear
    mov bh, 07     ;bh=07 => Normal Attributes              
    mov cx, 0      ;From (cl=column, ch=row)
    mov dl, 80     ;To dl=column
    mov dh, 25     ;To dh=row
    int 10h    
    
    ;Move cursor to the beginning of the screen 
    mov ax, 0
    mov ah, 2
    mov dx, 0
    int 10h   
    
ENDM ClearScreen

Delete Macro row, column
   mov Ah, 02h
   mov Bh, 0h
   mov Dh, row
   mov Dl, column
   int 10h 
   mov Ah, 09
   mov Al, ' '
   mov Bl, 0h
   mov Cx, 1h
   int 10h 
ENDM Delete

Delay  Macro
    
    push ax
    push bx
    push cx
    push dx
    push ds
  
    mov cx, 2h		;Cx,Dx : number of microseconds to wait
    mov dx, 0h
    mov ah, 86h
    int 15h
	
    pop ds
    pop dx
    pop cx
    pop bx
    pop ax
    
ENDM Delay 

.MODEL SMALL
.STACK 64    
.DATA 
StartScreen			 db '              ====================================================',0ah,0dh
	db '             ||                                                  ||',0ah,0dh                                        
	db '             ||         >>  Shooting rockets Game  <<            ||',0ah,0dh
	db '             ||__________________________________________________||',0ah,0dh
	db '             ||                                                  ||',0ah,0dh          
	db '             ||     Use up and down key to move gunshooter       ||',0ah,0dh
	db '             ||          and space button to shoot bullet        ||',0ah,0dh
	db '             ||                                                  ||',0ah,0dh
	db '             ||                  You have 6 lifes                ||',0ah,0dh
	db '             ||  Score the highest you can score before you die  ||',0ah,0dh
	db '             ||                                                  ||',0ah,0dh
	db '             ||            Press Enter to start playing          ||',0ah,0dh 
	db '             ||            Press ESC to Exit                     ||',0ah,0dh
	db '              ====================================================',0ah,0dh
	db '$',0ah,0dh
GameoverScreen			 db '          __________________________________________________',0ah,0dh
	db '             ||                                                  ||',0ah,0dh                                        
	db '             ||               >> GAMEOVER <<                     ||',0ah,0dh
	db '             ||__________________________________________________||',0ah,0dh	
	db '$',0ah,0dh
RocketYabove         db       24 										 
RocketYBelow         db       25 
RocketCol              db       0    
RocketColor          db      0d0h    
RandomCheck          db      1  
RocketUpperLimit     equ     4  
ShooterY             db      14   
ShotX                db      ?
ShotY                db      ?
ShotStatus           db      0    
lifes                equ     6
Misses               db      0
Hits                 db      0
PlayerName			 db 15, ?,  15 dup('$')
AskPlayerName		 db 'Enter your name: ','$'
Disp_Hits			 db 'Score: 00','$'
Disp_lifes			 db 'lifes: ?','$'
GameTitle			 db ' >>  Shooting rockets Game  << ','$'
FinalScoreString	 db ' your final score is ?','$'
;==================================================
.CODE   
MAIN    PROC FAR  
    mov ax, @DATA
    mov ds, ax  
  ClearScreen
  Call StartMenu
  ClearScreen
  call DrawInterface
  call RandomiseRocketRow 
  Print  RocketYabove, RocketCol, RocketColor 
  Print  RocketYBelow, RocketCol, RocketColor 
  PrintShooter ShooterY
  MainLoop:
   call UpdateStrings
   call RocketUp
   
	
	
   cmp ShotStatus, 1
   jnz NoShotExist
   call MoveShot
   ;call MoveShot
   
   
   NoShotExist:       
    mov ah,1h
    int 16h             ;ZF=1 when a key is pressed                        
    jz NokeyPress
      call KeyisPressed
    NokeyPress:
	Delay
  jmp MainLoop

hlt
    
    
MAIN        ENDP 
UpdateStrings Proc  
	 push ax
	 
	 mov al, Hits
	 add al, 30h
	 mov Disp_Hits[8], al
	 mov FinalScoreString[21], al
		
   mov ah,lifes
   sub ah, Misses
   jnz continueTheGame
   call Gameover
   continueTheGame:
   add ah, 30h
   mov Disp_lifes[7], ah
	
	PrintText 2 , 40 , Disp_Hits
	PrintText 2 , 60 , Disp_lifes	
	pop ax
	ret             
    
UpdateStrings ENDP 
RocketUp Proc   
    dec RocketYabove
    Print  RocketYabove, RocketCol, RocketColor 
    Delete RocketYBelow, RocketCol     
    dec RocketYBelow  
    cmp RocketYabove,RocketUpperLimit   
    Jnz endRocketUp 
    Delete RocketUpperLimit, RocketCol 
    Delete RocketUpperLimit+1, RocketCol
	call resetRocket
	;call resetShot
    endRocketUp: ret              
    
RocketUp ENDP 
KeyisPressed  Proc 
    mov ah,0
    int 16h

    cmp ah,48h                            ;go upKey if up button is pressed
    jnz NotUPKey
    call MoveShooterUp 
    jmp EndofKeyisPressed
    NotUPKey:
    cmp ah, 50h
    jnz NotDOWNKey
    call MoveShooterDown
    jmp EndofKeyisPressed
    NotDOWNKey:
	cmp ah,1H                 		 ;Esc to exit the game
    Jnz NotESCKey
	call Gameover 
	NotESCKey:
    cmp ah,39h                            ;go spaceKey if up button is pressed
    jnz EndofKeyisPressed
        cmp ShotStatus, 1
        jz EndofKeyisPressed
            mov al,1                      ;intialize a new shot
            mov ShotStatus,1 
            mov al, ShooterY
            mov ShotY, al
            mov al, 2
            mov ShotX,al 
			
    EndofKeyisPressed:
    ret
KeyisPressed  ENDP 

MoveShooterUp  Proc  
     cmp ShooterY, RocketUpperLimit
     JZ NoMoveUp
     dec ShooterY
     PrintShooter ShooterY 
     mov al, ShooterY   
     inc al
     delete al, 0
    NoMoveUp:
    ret
MoveShooterUp  ENDP 

MoveShooterDown  Proc 
     cmp ShooterY, 24
     JZ NoMoveDown
     inc ShooterY
     PrintShooter ShooterY  
     mov al, ShooterY   
     dec al
     delete al, 0   
     NoMoveDown:
    ret
MoveShooterDown  ENDP 

MoveShot  Proc 
    inc ShotX
    PrintShot ShotY,ShotX 
    mov al, ShotX   
    dec al
    delete ShotY, al
        call CheckShotStatus  
    ret
MoveShot  ENDP 

CheckShotStatus  Proc
    push ax
    mov ah,RocketCol
    dec ah              ;thinking that the rocket is a step ahead since I'm comparing before drawing
    cmp ah, ShotX 
    JC ShotXExceededRocket 
    JZ CheckShotHIT  
    jmp noChange
		
		CheckShotHIT: 
        mov ah,ShotY
        cmp ah, RocketYabove
        JZ Hit      
        cmp ah, RocketYBelow
        JZ Hit   
     
	 ShotXExceededRocket: 
	 inc Misses
	 call resetShot
     jmp noChange
	 
     Hit: 
     inc Hits
     call resetShot
	 Delete RocketYabove, RocketCol 
	 Delete RocketYBelow, RocketCol 
     call resetRocket
 
     noChange:
	 
    pop ax
    ret    
CheckShotStatus ENDP 


RandomiseRocketRow Proc    
   push ax
   push bx
   push cx
   push dx 
   
RestartRandomise:
   mov ah, 2ch                
   int 21h                      ; get system time where DH = second   Dl=MilliSeconds
   xor ax, ax
   mov al, dl
   mov bl, 79
   div bl
   mov RocketCol, ah    ;the remainder
   ;;;
   endRandomise: 
   cmp RocketCol, 0
   JZ RestartRandomise
   cmp RocketCol, 1
   JZ RestartRandomise
   
   NotBlack:
   add RocketColor ,10h
   cmp RocketColor ,00h
   jz NotBlack
        
   pop dx
   pop cx
   pop bx
   pop ax
   ret  
RandomiseRocketRow ENDP 

resetRocket Proc
    mov RocketYabove, 24 
    mov RocketYBelow, 25 
    call RandomiseRocketCol 
    ret 
resetRocket ENDP 

resetShot Proc
	 cmp ShotStatus, 00
	 JZ NoShotToDelete
	 delete ShotY, ShotX 
     mov al,0          
     mov ShotStatus,al 
	 NoShotToDelete:
	ret
resetShot ENDP 

StartMenu Proc
    
    push ax
    push bx
    push cx
    push dx
    push ds 
    
	ClearScreen
    
	LoopOnName:
	
;	mov ah,0				;NOT WORKING!!!!
;	mov cx, 79
;	ClearLine:
;	delete 8,ah
;	inc ah
;	loop ClearLine
	
	PrintText 8,8,AskPlayerName
	
	;Receive player name from the user
		mov ah, 0Ah
		mov dx, offset PlayerName
		int 21h
	
	
	cmp PlayerName[1], 0	;Check that input is not empty
	jz LoopOnName
	
	;Checks on the first letter to ensure that it's either a capital letter or a small letter
	cmp PlayerName[2], 40h
	jbe LoopOnName
	cmp PlayerName[2], 7Bh
	jae LoopOnName
	cmp PlayerName[2], 60h
	jbe	anotherCheck
	ja ExitLoopOnName
	anotherCheck:
	cmp PlayerName[2], 5Ah
	ja	LoopOnName
	
	ExitLoopOnName:
	ClearScreen
	PrintText 1,1,StartScreen	
	
	;hide curser
	 mov ah,01h
	  ;If bit 5 of CH is set, that often means "Hide cursor". So CX=2607h is an invisible cursor.
	 mov cx,2607h 
	 int 10h
	 
    checkforinput:
    mov AH,0            		 
    int 16H 
    
    cmp al,13              		     ;Enter to Start Game   
    JE StartTheGame
    
    cmp ah,1H                 		 ;Esc to exit the game
    JE ExitMenu
    JNE checkforinput
    
	
	 
    ExitMenu:
        mov ah,4CH
        int 21H
    
        
    StartTheGame: 
        pop ds
        pop dx
        pop cx
        pop bx
        pop ax 
        RET
StartMenu ENDP

DrawInterface	Proc
	
	push ax
	push cx
	push dx
	
	;Go to the line beginning
	
	mov al,0
	mov ah, RocketUpperLimit
	dec ah
	mov cx, 80
	DrawLineloop:
		Print ah, al, 30h
		inc al
	loop DrawLineloop

	mov al,' '
	mov PlayerName[0],al
	mov PlayerName[1],al
	PrintText 2 , 0 , PlayerName
	PrintText 2 , 40 , Disp_Hits
	PrintText 2 , 60 , Disp_lifes	
	PrintText 0 , 24 , GameTitle

	pop dx
	pop cx
	pop ax
	
	RET
DrawInterface	ENDP

 Gameover Proc 
 ClearScreen

 PrintText 1, 30, PlayerName
 PrintText 3, 25,FinalScoreString
 PrintText 5, 5 ,GameoverScreen

 
    mov ah,4CH
    int 21H 
    ret
 Gameover ENDP   
 
END MAIN    