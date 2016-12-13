;;=============================================================================;;   
;;                    Shooting rockets Game                                    ;;
;;                 Tested on DOSBox and emu8086                                ;;
;;=============================================================================;;
;;                  Created by: Michael Malak                        	       ;;
;;=============================================================================;;


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

PrintShooter MACRO column
   push ax
   push bx
   push cx
   push dx   
   
   mov Ah, 02h
   mov Bh, 0h
   mov Dh, 24
   mov Dl, column
   INT 10h 
   mov Ah, 09
   mov Al, 127  ;Arrow shape
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

Delay  Macro Seconds, MilliSeconds
    
    push ax
    push bx
    push cx
    push dx 
	push ds

    mov cx, Seconds		;Cx,Dx : number of microseconds to wait
    mov dx, MilliSeconds
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
	db '             ||     Use left and right key to move gunshooter    ||',0ah,0dh
	db '             ||          and space button to shoot bullet        ||',0ah,0dh
	db '             ||                                                  ||',0ah,0dh
	db '             ||              You begin with 6 lifes              ||',0ah,0dh
	db '             ||  Score the highest you can score before you die  ||',0ah,0dh
	db '             ||        Scoring points increase your lifes        ||',0ah,0dh
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
RocketColLeft          db       ? 										 
RocketColRight         db       ? 
RocketColCenter	       db		?


RocketRow              db       15    
RocketColor            db      0d0h    


ShooterCol             db      40
   
ShotRow                db      ?
ShotCol                db      ?
ShotStatus             db      0    		;1 means there exist a displayed shot, 0 otherwise

lifes                  db      6
Misses                 db      0
Hits                   db      0
PlayerName			   db 15, ?,  15 dup('$')
AskPlayerName		   db 'Enter your name: ','$'
Disp_Hits			   db 'Score: 00','$'
Disp_lifes			   db 'lifes: ?','$'
GameTitle			   db ' >>  Shooting rockets Game  << ','$'
FinalScoreString	   db ' your final score is ?','$'
RocketDirection		   db 0						;0=Left, 1=Right
EasyMode			   db 'Easy Mode','$'
HardMode			   db 'Hard Mode','$'
ExtremeMode			   db 'Extreme Mode','$'
;==================================================
.CODE   
MAIN    PROC FAR  
    mov ax, @DATA
    mov ds, ax  
  ClearScreen
  Call StartMenu
  ClearScreen
  call DrawInterface
  call ResetRocket
  PrintShooter 40
  call UpdateStrings
  
  MainLoop:
   cmp RocketDirection, 1
   jz moveRocketRight
   call RocketMoveLeft
   jmp AfterRocketMove
   moveRocketRight:
   call RocketMoveRight
   
   AfterRocketMove:
   cmp ShotStatus, 1
   jnz NoShotExist
   call CheckShotStatus			;I'll see if the shotStatus alter to 0
   cmp ShotStatus, 1
   jnz NoShotExist
   call MoveShot
   PrintShooter ShooterCol		;since the shot deletes the shooter at the beginning
   NoShotExist:       
    mov ah,1h
    int 16h             ;ZF=1 when a key is pressed                        
    jz NokeyPress
      call KeyisPressed
    NokeyPress:
	call Difficulty
	EndOfMainLoop:
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
    add ah, 30h
    mov Disp_lifes[7], ah
	
	PrintText 1 , 60 , Disp_Hits
	PrintText 1 , 70 , Disp_lifes	

	pop ax
	ret             
    
UpdateStrings ENDP 

RocketMoveLeft Proc   
    dec RocketColLeft
    Print   RocketRow ,RocketColLeft, RocketColor 
    Delete RocketRow, RocketColRight     
    dec RocketColRight  
	dec RocketColCenter
	
    cmp RocketColLeft ,0   
    Jnz endOfRocketMoveLeft 
    call DeleteRocket
	call ResetRocket
    endOfRocketMoveLeft: ret              
RocketMoveLeft ENDP 

RocketMoveRight Proc   
    inc RocketColRight
    Print   RocketRow ,RocketColRight, RocketColor 
    Delete RocketRow, RocketColLeft     
    inc RocketColleft 
	inc RocketColCenter
	
    cmp RocketColRight ,80   
    Jnz endOfRocketMoveRight 
    call DeleteRocket
	call ResetRocket
    endOfRocketMoveRight: ret              
RocketMoveRight ENDP 

KeyisPressed  Proc 
    mov ah,0
    int 16h

    cmp ah,4bh                            ;Move Shooter Left if left button is pressed
    jnz NotLeftKey
		call MoveShooterLeft 
	jmp EndofKeyisPressed
	
    NotLeftKey:
    cmp ah,4dh					
    jnz NotRightKey						  ;Move Shooter Right if Right button is pressed
		call MoveShooterRight
	jmp EndofKeyisPressed
	
    NotRightKey:
	cmp ah,1H                 		      ;Esc to exit the game
    ;try: cmp ax, 011bh
	
	Jnz NotESCKey
		call Gameover 
		
	NotESCKey:
    cmp ah,39h                            ;go spaceKey if up button is pressed
    ;try:cmp ax,3920
	
	jnz EndofKeyisPressed
    cmp ShotStatus, 1
    jz EndofKeyisPressed
            mov al,1                      ;intialize a new shot
            mov ShotStatus,1 
            mov al, ShooterCol
            mov ShotCol, al
            mov al, 24					 ;it will be decremented in the new MainLoop
            mov ShotRow,al 
			
    EndofKeyisPressed:
    ret
KeyisPressed  ENDP 

MoveShooterLeft  Proc  
     cmp ShooterCol, 0
     JZ NoMoveLeft
     dec ShooterCol
     PrintShooter ShooterCol 
     mov al, ShooterCol   
     inc al
     delete 24, al
    NoMoveLeft:
    ret
MoveShooterLeft  ENDP 

MoveShooterRight  Proc 
     cmp ShooterCol, 79
     JZ NoMoveRight
     inc ShooterCol
     PrintShooter ShooterCol  
     mov al, ShooterCol   
     dec al
     delete 24, al 
     NoMoveRight:
    ret
MoveShooterRight  ENDP 

MoveShot  Proc 
    dec ShotRow
    PrintShot ShotRow,ShotCol 
    mov al, ShotRow  
    inc al
    delete al, ShotCol    
    ret
MoveShot  ENDP 

CheckShotStatus  Proc
    push ax
	
    mov ah,RocketRow
    inc ah              ;Checking the row I {WILL} draw the shot in if occupied by a rocket
    cmp ah, ShotRow  
    JNZ CheckEndRange 
						;Check if it was a hit
        mov al,ShotCol
        cmp al, RocketColLeft
        JZ Hit      
		cmp al, RocketColCenter
		JZ Hit
        cmp al, RocketColRight
        JZ Hit 	
		cmp RocketDirection, 0
		jnz RightDirection
		mov ah, RocketColLeft
		dec ah
		cmp al, ah
        JZ Hit
		jmp CheckEndRange
		RightDirection:
		mov ah, RocketColRight
		inc ah
		cmp al, ah
        JZ Hit
		
    CheckEndRange:
	 cmp ShotRow, 2			;It stops while printed on the number of row I put here
	 jnz noChange			
	 dec Lifes
	 cmp lifes, 0
     jnz ResetTheShot
     call Gameover
	 
     Hit: inc Hits
	 inc lifes
	 call DeleteRocket
	 call ResetRocket
	 ResetTheShot:
     call ResetShot
     call UpdateStrings
     noChange:
	 
    pop ax
    ret    
CheckShotStatus ENDP 

DeleteRocket Proc
	 Delete RocketRow, RocketColLeft
	 Delete RocketRow, RocketColCenter
	 Delete RocketRow, RocketColRight
	ret
DeleteRocket ENDP

RandomiseRocketRow Proc    
   push ax
   push bx
   push cx
   push dx 
   
   ; Range of row= [5,24]
   mov ah, 2ch                
   int 21h                      ; get system time where DH = second   Dl=MilliSeconds
   xor ax, ax
   mov al, dl
   mov bl, 20					; That limits the remainder to be [0,19]
   div bl
   add ah, 3					;The range would be= [3,22]
   mov RocketRow, ah   	 		
   
   ;Change the color of rocket
   NotBlack:
   add RocketColor ,10h			;Add one to background color
   cmp RocketColor ,00h
   jz NotBlack
        
   pop dx
   pop cx
   pop bx
   pop ax
   ret  
RandomiseRocketRow ENDP 

ResetRocket Proc
    call RandomiseRocketDirection
	call RandomiseRocketRow
	
	cmp RocketDirection, 1
	jnz movementLeft
	mov RocketColLeft, 0	 
    mov RocketColCenter, 1
	mov RocketColRight, 2
	jmp EndOfResetRocket
	
	movementLeft:
	mov RocketColLeft, 78	
	mov RocketColCenter, 79
	mov RocketColRight, 80
    
    EndOfResetRocket: 
    ret 
ResetRocket ENDP 

RandomiseRocketDirection Proc
   push ax
   push bx
   push cx
   push dx 

   mov ah, 2ch                
   int 21h                      ; get system time where DH = second   Dl=MilliSeconds
   xor ax, ax
   mov al, dl
   mov bl, 2					;That limits the remainder to be [0,1]
   div bl						
   mov RocketDirection,ah

   pop dx
   pop cx
   pop bx
   pop ax
   ret  
	ret
RandomiseRocketDirection ENDP

ResetShot Proc
	 delete ShotRow, ShotCol  
     mov al,0          
     mov ShotStatus,al 
	ret
ResetShot ENDP 

StartMenu Proc
    
    push ax
    push bx
    push cx
    push dx
    push ds 
    
	ClearScreen
    
	LoopOnName:
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
	
	mov al, 0
	mov cx, 80
	DrawLineloop:
		Print 1, al, 30h
		inc al
	loop DrawLineloop

	mov al,' '
	mov PlayerName[0],al
	mov PlayerName[1],al
	PrintText 1 , 0 , PlayerName
	PrintText 1 , 60 , Disp_Hits
	PrintText 1 , 70 , Disp_lifes	
	PrintText 1 , 24 , GameTitle
	PrintText 0, 70, EasyMode
	
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
 
Difficulty Proc
	
	cmp Hits, 5
	jle EasyGame					
	cmp Hits, 10
	jle HardGame
	Delay 0,10000
	PrintText 0, 67, ExtremeMode ;Extreme Mode when 10<Hits
	jmp EndDifficulty
	
	HardGame: Delay 0,20000		;Hard Mode when 10<=Hits<5
	PrintText 0, 70, HardMode
	jmp EndDifficulty
	
	EasyGame: Delay 1,0			;Easy Mode when Hits<=5
	EndDifficulty:
	ret
Difficulty ENDP

END MAIN    
