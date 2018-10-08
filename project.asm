.Model Small

draw_row Macro x
    Local l1
; draws a line in row x from col 10 to col 300
    MOV AH, 0CH
    MOV AL, 3
    MOV CX, 10
    MOV DX, x
L1: INT 10h
    INC CX
    CMP CX, 310
    JL L1
    EndM

draw_col Macro y
    Local l2
; draws a line col y from row 10 to row 189
    MOV AH, 0CH
    MOV AL, 3
    MOV CX, y
    MOV DX, 10
L2: INT 10h
    INC DX
    CMP DX, 190
    JL L2
    EndM
    
.Stack 100h
.Data
GAME_TITLE       DB  "<SNAKE>$"
ERROR            DB  "fILE READ ERR$"
CONTINUE_TEXT    DB  "CONTINUE GAME$"
START_TEXT       DB  "NEW GAME$"
SCORE_TEXT       DB  "HIGH SCORE$"
CURR_SCORE       DB  "YOUR SCORE IS : $"
CURR_SCORE_VALUE DB  5 DUP (24H)
MENU_FLAG        DB  0
GAME_FLAG        DB  0
PLAYER_NAME      DB  20 DUP (24H)
HIGH_SCORE       DB  20 DUP (24H)
HIGH_SCORE_VALUE DW  0
NAME_FILE        DB  "player.txt",0
SCORE_FILE       DB  "score.txt",0
POINT            DW  0
NEW_TIMER_VEC    dw  ?,?
OLD_TIMER_VEC    dw  ?,?
NEW_KEY_VEC      dw  ?,?
OLD_KEY_VEC      dw  ?,?
SCAN_CODE        db  0
KEY_FLAG         db  0
timer_flag       db  0
vel_x            dw  5
vel_y            dw  0
vel              dw  5
ROW1    DW  64H,64H,64H,64H,100 DUP (64H)
COL1    DW  96H,91H,8CH,87H,100 DUP (96H)
ROW    DW  64H,64H,64H,64H,100 DUP (64H)
COL    DW  96H,91H,8CH,87H,100 DUP (96H)
L         DW     10
FOOD_X    DW     90
FOOD_Y    DW     70
INC_F     DB     0
R         DW     ?
C         DW     ?
END_F     DW     0
END_W     DW     0
MSG_1     DB 'GAME OVER $'
MSG_2     DB 'YOUR SCORE :$'
SCORE     DB  0
SCORE_MSG DB  '1$'
OBSTR     DW  20 DUP(25),20 DUP(175),2 DUP(30,35,40,45,50,150,155,160,165,170),20 DUP(50),20 DUP(150)
OBSTC     DW  2 DUP(30,35,40,45,50,55,60,65,70,75,240,245,250,255,260,265,270,275,280,285),10 DUP (30),10 DUP (285),2 DUP(105,110,115,120,125,130,135,140,145,150,155,160,165,170,175,180,185,190,195,200) 
;scan codes 
UP_ARROW    = 72  
DOWN_ARROW  = 80 
LEFT_ARROW  = 75  
RIGHT_ARROW = 77    
ESC_KEY     = 1 
;

.Code

set_display_mode Proc
; sets display mode and draws boundary
    MOV AH, 0
    MOV AL, 04h; 320x200 4 color
    INT 10h
; select palette    
    MOV AH, 0BH
    MOV BH, 1
    MOV BL, 0
    INT 10h
; set bgd color
    MOV BH, 0
    MOV BL, 0; cyan
    INT 10h
; draw boundary
    draw_row 10
    draw_row 189
    draw_col 10
    draw_col 309    
    RET
set_display_mode EndP

INITIALIZE_SNAKE PROC
    PUSH BX
    PUSH SI
    MOV FOOD_X,90
    MOV FOOD_Y,70
    MOV POINT,0
    MOV END_F,0
    MOV END_W,0
    MOV vel_Y,0
    MOV vel_x,5
    MOV VEL,5
    MOV L,10
    MOV INC_F,0
    MOV SI,L
    LOP_CP:
    MOV BX,[COL1+SI]
    MOV [COL+SI],BX
    MOV BX,[ROW1+SI]
    MOV [ROW+SI],BX
    SUB SI,2
    CMP SI,0
    JNL LOP_CP
    
    POP SI
    POP BX
    RET
INITIALIZE_SNAKE ENDP

DRAW_OBST PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    ;MOV AH,2
    ;MOV DH,0
    ;MOV DL,0
    ;INT 10H
    ;LEA SI,MSG_2
    ;CALL PRINT_MENU_ITEMS
    POP DX
    POP CX
    POP BX
    POP AX
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    MOV SI,198
    REEPET:
    MOV CX,[OBSTC+SI]
    MOV DX,[OBSTR+SI]
    
    ;DRAW SNAKE CELL
    MOV BX,4
    CALL DRAW_CELL
    
    SUB SI,2
    CMP SI,0
    JNL REEPET
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET 
DRAW_OBST ENDP 
       

DRAW_CELL PROC
;INPUT BX:SIZE OF CELL
;INPUT CX:COL OF CELL
;INPUT DX:ROW OF CELL
    PUSH CX
    PUSH DX 
    
    MOV AH,0CH ; write pixel
    
    MOV R,BX
    
    FLOP1:
    MOV C,BX
    FLOP2:
    INT 10h
    INC CX      ; NEXT COL
    DEC C
    JNZ FLOP2
    
    SUB CX,BX
    INC DX      ; NEXT ROW
    DEC R
    JNZ FLOP1
    
    POP DX      ; restore CX,DX
    POP CX
    RET
DRAW_CELL ENDP

display_SNAKE Proc
; displays ball at col CX and row DX with color given in AL
; input: AL = color of ball
;    CX = col
;    DX = row

    PUSH BX
    MOV SI,L
REPET:
    MOV CX,[COL+SI]
    MOV DX,[ROW+SI]
    
    ;DRAW SNAKE CELL
    MOV BX,4
    CALL DRAW_CELL
    
    SUB SI,2
    CMP SI,0
    JNL REPET
    
    POP BX
    RET 
display_SNAKE EndP

timer_tick Proc
    PUSH DS
    PUSH AX
    
    MOV AX, Seg timer_flag
    MOV DS, AX
    MOV timer_flag, 1
    
    POP AX
    POP DS
    
    IRET
timer_tick EndP

move_ball Proc
; erase ball at current position and display at new position
; input: CX = col of ball position
;    DX = rwo of ball position
; erase ball

    MOV AL, 0
    CALL display_SNAKE

    MOV SI,L
POS_UPDT:
    SUB SI,2
    MOV CX,[COL+SI]
    MOV [COL+SI+2],CX
    MOV DX,[ROW+SI]
    MOV [ROW+SI+2],DX
    CMP SI,0
    JNE POS_UPDT 
    
; get new position
    MOV CX,[COL]
    MOV DX,[ROW]
    ADD CX, vel_x
    ADD DX, vel_y
    
; check boundary
    CALL CK_CLS
    CALL CHECK_FOOD
    CALL check_boundary
    
    
    MOV [COL],CX
    MOV [ROW],DX
; wait for 1 timer tick to display ball
t_timer:
    CMP timer_flag, 1
    JNE t_timer
    MOV timer_flag, 0
    MOV AL, 3
    CALL display_SNAKE
    RET 
move_ball EndP

CK_CLS PROC
    PUSH SI
    MOV SI,L

    RPT:
    PUSH CX
    SUB CX,[COL+SI]
    CMP CX,0
    JGE H2
    NEG CX
    H2:
    CMP CX,5
    POP CX
    JGE CL_OK
    
    PUSH DX
    SUB DX,[ROW+SI]
    CMP DX,0
    JGE V2
    NEG DX
    V2:
    CMP DX,5
    POP DX
    JGE CL_OK
    
    MOV END_F,1
    MOV SI,4
    
    CL_OK: 
    SUB SI,2
    CMP SI,4
    JNL RPT
    
    MOV SI,198
    RPT1:
    PUSH CX
    SUB CX,[OBSTC+SI]
    CMP CX,0
    JGE H21
    NEG CX
    H21:
    CMP CX,4
    POP CX
    JGE CL_OK1
    
    PUSH DX
    SUB DX,[OBSTR+SI]
    CMP DX,0
    JGE V21
    NEG DX
    V21:
    CMP DX,4
    POP DX
    JGE CL_OK1
    
    MOV END_F,1
    MOV SI,0
    
    CL_OK1: 
    SUB SI,2
    CMP SI,0
    JNL RPT1
    
    POP SI
    RET
CK_CLS ENDP

OUTDEC   PROC   
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX  
    PUSH SI 
    INC POINT
    MOV AX,POINT

    XOR CX,CX
    MOV BX,10D

    @REPEAT1:
    XOR DX,DX
    DIV BX
    PUSH DX
    INC CX
    OR AX,AX
    JNE @REPEAT1
    CLD
    
    MOV DL,13
    MOV SI,CX
@PRINT_LOOP:
    CMP SI,0
    JE EXIT_OUTDEC
    MOV AH,2
    MOV DH,0   
    INT 10H
    POP AX
    OR AL,30H
    MOV AH,9
    MOV CX,1
    MOV BL,3
    INC DL
    INT 10H
    DEC SI
    JMP @PRINT_LOOP
    
    
    ;LEA SI,SCORE_MSG
    ;CALL PRINT_MENU_ITEMS
    ;LEA SI,SCORE_MSG
    ;INC [SI]
EXIT_OUTDEC:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    
    RET            
OUTDEC  ENDP 

CHECK_FOOD PROC
    PUSH CX
    PUSH DX
    PUSH BX
    
    SUB CX,FOOD_X
    SUB DX,FOOD_Y
    CMP CX,0
    JGE H
    NEG CX
    H:
    CMP CX,4
    JNL EX1
    
    CMP DX,0
    JGE V
    NEG DX
    V:
    CMP DX,4    
    JNL EX1
    
    MOV CX,FOOD_X
    MOV DX,FOOD_Y
    
    MOV AL,0
    MOV BX,5
    CALL DRAW_CELL
    INC L
    INC L
    MOV BL,SCORE
    
    ADD BL,20
    MOV SCORE,BL
    CALL OUTDEC
    CMP L,100
    JE WIN
    INC INC_F
    CMP INC_F,10
    JE INC_V
    BAC:
    ADD CX,100
    CMP CX,295
    JG INC_X
    X1:
    ADD DX,50
    CMP DX,185
    JG INC_Y
    X2:
    PUSH SI
    MOV SI,L
    JMP REPT
    EX1:
    JMP EX
    WIN:
        MOV END_W,1
        JMP EX
    INC_V:
        INC VEL
        MOV INC_F,0
        JMP BAC
    INC_X:
        SUB CX,250
        JMP X1
    INC_Y:
        SUB DX,150
        JMP X2   
REPT:
    PUSH CX
    SUB CX,[COL+SI]
    CMP CX,0
    JGE H1
    NEG CX
    H1:
    CMP CX,VEL
    POP CX 
    JGE FD_OK
    
    PUSH DX
    SUB DX,[ROW+SI]
    CMP DX,0
    JGE V1
    NEG DX
    V1:
    CMP DX,VEL
    POP DX 
    JGE FD_OK
    
    MOV SI,L
    MOV CX,[COL+SI]
    ADD CX,VEL
    MOV DX,[ROW+SI]
    ADD DX,VEL
    MOV SI,2
    FD_OK:
    SUB SI,2
    CMP SI,2
    JNL REPT
    
    POP SI
    MOV FOOD_X,CX
    MOV FOOD_Y,DX
    
    MOV AL, 1
    MOV BX,5
    CALL DRAW_CELL    
    EX:
    POP BX
    POP DX
    POP CX
    RET

CHECK_FOOD ENDP

check_boundary Proc
; determine if ball is outside screen, if so move it back in and 
; change ball direction
; input: CX = col of ball
;    DX = row of ball
; output: CX = valid col of ball
;     DX = valid row of ball
  ; check col value
  
    PUSH BX
    CMP CX, 10
    JG LP1
    MOV CX, 310
    SUB CX,5
    JMP LP2 
  LP1:
    MOV BX,310
    SUB BX,4  
    CMP CX,BX
    JL LP2
    MOV CX, 11
    
  ; check row value
  LP2:    
    CMP DX, 10
    JG LP3
    MOV DX, 190
    SUB DX,5
    JMP RETURN
  LP3:
    MOV BX,190
    SUB BX,4  
    CMP DX,BX  
    JL RETURN
    MOV DX, 11
    
RETURN:
    POP BX
    RET 
check_boundary EndP


setup_int Proc
; save old vector and set up new vector
; input: al = interrupt number
;    di = address of buffer for old vector
;    si = address of buffer containing new vector

; save old interrupt vector
    PUSH ES 
    MOV AH, 35h ; get vector
    INT 21h
    MOV [DI], BX    ; save offset
    MOV [DI+2], ES  ; save segment
    
; setup new vector
    MOV DX, [SI]    ; dx has offset
    PUSH DS     ; save ds
    
    MOV DS, [SI+2]  ; ds has the segment number
    MOV AH, 25h ; set vector
    INT 21h
    POP DS
    POP ES
    RET
setup_int EndP

KEYBOARD_INT PROC
    ;keyboard interrupt routine 
    ; save registers 
    
    PUSH DS
    PUSH ES
    PUSH AX 
    
    ; set up DS 
    MOV AX,SEG SCAN_CODE 
    MOV DS,AX 
    
    ; input scan code
    IN AL, 60H
    PUSH AX 
    IN AL,61H   ;control port value       
    MOV AH,AL
    OR AL,80H   ; set bit tor keyboard 
    OUT 61H,AL  ;write? back 
    XCHG AH,AL  ; get back control value
    OUT 61H,AL  ;reset control port
    POP AX      ;recover scan code
    MOV AH, AL
    TEST AL,80H ; test for break code
    JNE KEY_0   ;yes, clear flags, goto KEY_0
    
    ;make code
   MOV SCAN_CODE,AL ;save in variable
   MOV KEY_FLAG,1H  ; set key flag
   KEY_0: 
   MOV AL,20H       ;reset interrupt
   OUT 20H,AL  
   
   ;restore registers 
   POP AX 
   POP ES
   POP DS 
   IRET 
   ;END KEYBOARD ROUTINE 
    
KEYBOARD_INT ENDP


SCORE_VIEW PROC
    CALL SET_DISPLAY_MODE

    LEA SI,SCORE_TEXT
    MOV AH,2
    MOV DH,10
    MOV DL,7
    INT 10H
    CLD
    CALL PRINT_MENU_ITEMS
    
    MOV AH,3DH
    MOV AL,0
    LEA DX,SCORE_FILE    
    INT 21H
    MOV BX,AX
    MOV AH,3FH
    MOV CX,10
    LEA DX,HIGH_SCORE
    INT 21H
    MOV AH,3EH
    INT 21H
    LEA SI,HIGH_SCORE
    MOV AH,2
    MOV DH,10
    MOV DL,20
    INT 10H
    CLD
    CALL PRINT_MENU_ITEMS
PUSH BX
PUSH CX
PUSH DX

LEA SI,HIGH_SCORE

XOR BX,BX

XOR CX,CX
LODSB
@REPEAT2:


AND AX,000FH
PUSH AX

MOV AX,10
MUL BX
POP BX
ADD BX,AX
LODSB
CMP AL,'$'
JNE @REPEAT2

MOV AX,BX

OR CX,CX
JE @EXIT

NEG AX

@EXIT:
MOV HIGH_SCORE_VALUE,AX
;MOV AH,2
;MOV DX,HIGH_SCORE_VALUE
;INT 21H
POP DX
POP CX
POP BX
JMP LP
LP:
    MOV AH,0
    INT 16H
    CMP AL,'B'
    JNE LP
    RET
SCORE_VIEW ENDP


GAME_OVER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    CALL SET_DISPLAY_MODE
    MOV GAME_FLAG,0
    LEA SI,MSG_1
    MOV AH,2
    MOV DH,8
    MOV DL,15
    INT 10H
    CLD
    CALL PRINT_MENU_ITEMS
    LEA SI,CURR_SCORE
    MOV AH,2
    MOV DH,10
    MOV DL,10
    INT 10H
    CLD
    CALL PRINT_MENU_ITEMS
    
    
     
    MOV AX,POINT
    
    XOR CX,CX
    MOV BX,10D

    @REPEAT1G:
    XOR DX,DX
    DIV BX
    PUSH DX
    INC CX
    OR AX,AX
    JNE @REPEAT1G
    CLD
    LEA DI,CURR_SCORE_VALUE
    MOV DL,26
    MOV SI,CX
    @PRINT_LOOPG:
    CMP SI,0
    JE LPG
    MOV AH,2
    MOV DH,10   
    INT 10H
    POP AX
    OR AL,30H
    STOSB
    MOV AH,9
    MOV CX,1
    MOV BL,3
    INC DL
    INT 10H
    
    DEC SI
    JMP @PRINT_LOOPG 
WRITE_SCORE:
    MOV AH,3DH
    MOV AL,1
    LEA DX,SCORE_FILE    
    INT 21H
    MOV BX,AX 
    MOV AH,40H
    MOV CX,2
    LEA DX,CURR_SCORE_VALUE
    INT 21H
    MOV AH,3EH
    INT 21H
    JMP EXIT_G
       
        
    LPG:
    MOV AX,HIGH_SCORE_VALUE
    CMP AX,POINT
    JL WRITE_SCORE
EXIT_G:
    MOV AH,0
    INT 16H
    CMP AL,'B'
    JNE EXIT_G
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
    GAME_OVER ENDP
    
    
        

PRINT_MENU_ITEMS PROC 

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    
PRINT_START:
    LODSB
    CMP AL,'$'
    JE EXIT
    MOV AH,0EH
    MOV CX,1
    MOV BL,2
    INT 10H
    JMP PRINT_START
    
EXIT:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
    
PRINT_MENU_ITEMS ENDP

ARROW PROC
    MOV AH,9
    MOV AL,'>'
    MOV CX,1
    INT 10H
    RET
    
ARROW ENDP

WITH_CONTINUE PROC
FRONT_C:
    CALL SET_DISPLAY_MODE
    MOV AH,2
    MOV DH,5
    MOV DL,15
    INT 10H
    LEA SI,GAME_TITLE
    CLD
    MOV AH,1
    MOV CH,0
    MOV CL,13
    INT 10H
    PRINT_START2:
    LODSB
    CMP AL,'$'
    JE NXT1
    MOV AH,0EH
    MOV CX,1
    MOV BL,3
    INT 10H
    JMP PRINT_START2
    NXT1:    
    MOV AH,2
    MOV DH,12
    MOV DL,10
    INT 10H
    LEA SI,CONTINUE_TEXT
    CLD
    CALL PRINT_MENU_ITEMS
    MOV AH,2
    MOV DH,14
    MOV DL,10
    INT 10H
    LEA SI,START_TEXT
    CLD
    CALL PRINT_MENU_ITEMS
    MOV AH,2
    MOV DH,16
    MOV DL,10
    INT 10H
    LEA SI,SCORE_TEXT
    CLD
    CALL PRINT_MENU_ITEMS
    
    MOV AH,2
    MOV DH,12
    MOV DL,9
    INT 10H
    MOV BL,2
    CALL ARROW 
    MOV MENU_FLAG,0 
   
BACK1_:
    MOV AH,0
    INT 16H
    CMP AH,80
    JE DOWN1_
    CMP AH,72
    JE UP1_
    CMP AL,'S'
    JE SELECTED1
    JMP BACK1_
    
UP1_:
    CMP MENU_FLAG,0
    JE MENUUP0
    CMP MENU_FLAG,1
    JE MENUUP1
    CMP MENU_FLAG,2
    JE MENUUP2    
MENUUP0:
    MOV MENU_FLAG,2
    MOV BL,0
    CALL ARROW
    MOV AH,2
    MOV DH,16
    MOV DL,9
    INT 10H
    MOV BL,2
    CALL ARROW
    JMP BACK1_
MENUUP1:
    DEC MENU_FLAG
    MOV BL,0
    CALL ARROW
    MOV AH,2
    MOV DH,12
    MOV DL,9
    INT 10H
    MOV BL,2
    CALL ARROW
    JMP BACK1_
MENUUP2:
    DEC MENU_FLAG
    MOV BL,0
    CALL ARROW
    MOV AH,2
    MOV DH,14
    MOV DL,9
    INT 10H
    MOV BL,2
    CALL ARROW
    JMP BACK1_
    
SELECTED1:
    CMP DH,12
    JE CONTINUE_GAME
    CMP DH,14
    JE NEW_GAME_C
    CMP DH,16
    JE SCORE_VIEWER_C
    JMP BACK1_
    
DOWN1_:
    CMP MENU_FLAG,0
    JE MENUDOWN0
    CMP MENU_FLAG,1
    JE MENUDOWN1
    CMP MENU_FLAG,2
    JE MENUDOWN2    
MENUDOWN0:
    INC MENU_FLAG
    MOV BL,0
    CALL ARROW
    MOV AH,2
    MOV DH,14
    MOV DL,9
    INT 10H
    MOV BL,2
    CALL ARROW
    JMP BACK1_
MENUDOWN1:
    INC MENU_FLAG
    MOV BL,0
    CALL ARROW
    MOV AH,2
    MOV DH,16
    MOV DL,9
    INT 10H
    MOV BL,2
    CALL ARROW
    JMP BACK1_
MENUDOWN2:
    MOV MENU_FLAG,0
    MOV BL,0
    CALL ARROW
    MOV AH,2
    MOV DH,12
    MOV DL,9
    INT 10H
    MOV BL,2
    CALL ARROW
    JMP BACK1_
    
SCORE_VIEWER_C:
    CALL SCORE_VIEW
    JMP FRONT_C
CONTINUE_GAME:
    CALL NEW_GAME
    CMP GAME_FLAG,0
    JE EXIT_C
    JMP FRONT_C
    
NEW_GAME_C:
    CALL INITIALIZE_SNAKE
    CALL NEW_GAME
    CMP GAME_FLAG,0
    JE EXIT_C
    JMP FRONT_C
EXIT_C:
    RET

    
EXIT_WITH_CONTINUE:
    RET
WITH_CONTINUE ENDP


WITHOUT_CONTINUE PROC
FRONT:
    
    CALL SET_DISPLAY_MODE
    
    MOV AH,2
    MOV DH,5
    MOV DL,15
    INT 10H
    LEA SI,GAME_TITLE
    CLD
    MOV AH,1
    MOV CH,0
    MOV CL,13
    INT 10H
    PRINT_START1:
    LODSB
    CMP AL,'$'
    JE NXT
    MOV AH,0EH
    MOV CX,1
    MOV BL,3
    INT 10H
    JMP PRINT_START1
NXT:    
    MOV AH,2
    MOV DH,14
    MOV DL,10
    INT 10H
    LEA SI,START_TEXT
    CLD
    CALL PRINT_MENU_ITEMS
    MOV AH,2
    MOV DH,16
    MOV DL,10
    INT 10H
    LEA SI,SCORE_TEXT
    CLD
    CALL PRINT_MENU_ITEMS

    MOV AH,2
    MOV DH,14
    MOV DL,9
    INT 10H
    MOV BL,2
    CALL ARROW      
    
BACK_:
    MOV AH,0
    INT 16H
    CMP AH,80
    JE DOWN_
    CMP AH,72
    JE DOWN_
    CMP AL,'S'
    JE SELECTED
    JMP BACK_
    
DOWN_:
    CMP DH,14
    JE SA
    ;MOV AH,2
    ;MOV DH,12
    ;MOV DL,9
    ;INT 10H
    MOV BL,0
    CALL ARROW
    MOV AH,2
    MOV DH,14
    MOV DL,9
    INT 10H
    MOV BL,2
    CALL ARROW
    JMP BACK_
SA:
    ;MOV AH,2
    ;MOV DH,10
    ;MOV DL,9
    ;INT 10H
    MOV BL,0
    CALL ARROW
    MOV AH,2
    MOV DH,16
    MOV DL,9
    INT 10H
    MOV BL,2
    CALL ARROW
    JMP BACK_
SELECTED:
    CMP DH,14
    JE EXIT_WITHOUT_CONTINUE
    CMP DH,16
    JE SCORE_VIEWER
    JMP BACK_
    
SCORE_VIEWER:
    CALL SCORE_VIEW
    JMP FRONT
EXIT_WITHOUT_CONTINUE:
    CALL INITIALIZE_SNAKE
    CALL NEW_GAME
    CMP GAME_FLAG,1
    JE EXIT_F
    JMP FRONT
EXIT_F:
    RET
    
WITHOUT_CONTINUE ENDP


MAIN_MENU PROC 
FRONT_MAIN:  
    CMP GAME_FLAG,0
    JNE WITH_CONTINUE_
    CALL WITHOUT_CONTINUE
    JMP EXIT_MAINMENU    
  
WITH_CONTINUE_:
    CALL WITH_CONTINUE
    
EXIT_MAINMENU:
    JMP FRONT_MAIN
MAIN_MENU ENDP

NEW_GAME PROC 
CALL SET_DISPLAY_MODE 
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    MOV AH,2
    MOV DH,0
    MOV DL,0
    INT 10H
    LEA SI,MSG_2
    CALL PRINT_MENU_ITEMS
    MOV AX,POINT

    XOR CX,CX
    MOV BX,10D

    @REPEAT1n:
    XOR DX,DX
    DIV BX
    PUSH DX
    INC CX
    OR AX,AX
    JNE @REPEAT1n
    CLD
    
    MOV DL,13
    MOV SI,CX
    @PRINT_LOOPn:
    CMP SI,0
    JE EXIT_OUTDEC1
    MOV AH,2
    MOV DH,0   
    INT 10H
    POP AX
    OR AL,30H
    MOV AH,9
    MOV CX,1
    MOV BL,3
    INC DL
    INT 10H
    DEC SI
    JMP @PRINT_LOOPn

    EXIT_OUTDEC1:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
; set up timer interrupt vector
    MOV NEW_TIMER_VEC, OFFSET TIMER_TICK
    MOV NEW_TIMER_VEC+2, CS
    MOV AL, 1CH                              ; interrupt type
    LEA DI, OLD_TIMER_VEC
    LEA SI, NEW_TIMER_VEC
    CALL SETUP_INT
    
;set up keyboard interrupt vector 

    MOV NEW_KEY_VEC, OFFSET KEYBOARD_INT     ;offset 
    MOV NEW_KEY_VEC+2, CS                    ; segment 
    MOV AL, 9H                               ;interrupt number
    LEA DI,OLD_KEY_VEC 
    LEA SI,NEW_KEY_VEC
    CALL SETUP_INT 
; start ball at col = 298, row = 100
; for the rest of the program CX = ball row, DX = ball col
    MOV AL,2
    CALL DRAW_OBST
    MOV AL, 1
    MOV CX,FOOD_X
    MOV DX,FOOD_Y
    MOV BX,5
    CALL DRAW_CELL
    
    MOV AL, 3
    CALL display_SNAKE
    
TEST_KEY:
    CMP KEY_FLAG,1
    JNE LT
    MOV KEY_FLAG,0
    MOV BX,VEL
    CMP SCAN_CODE,ESC_KEY
    JNE TK_UP
    MOV GAME_FLAG,1
    LEA DI,NEW_KEY_VEC
    LEA SI,OLD_KEY_VEC
    MOV AL,9H 
    CALL SETUP_INT
    RET
    
TK_UP:
    CMP SCAN_CODE,UP_ARROW
    JNE TK_DOWN
    CMP VEL_Y,0
    JG TEST_TIMER
    MOV VEL_X,0
    NEG BX
    MOV VEL_Y,BX
    LT:
    JMP TEST_TIMER 
    
TK_DOWN:
    CMP SCAN_CODE,DOWN_ARROW
    JNE TK_LEFT
    CMP VEL_Y,0
    JL TEST_TIMER
    MOV VEL_X,0
    MOV VEL_Y,BX 
    JMP TEST_TIMER   
  LK:
    JMP TEST_KEY
    
TK_LEFT:
    CMP SCAN_CODE,LEFT_ARROW
    JNE TK_RIGHT
    CMP VEL_X,0
    JG TEST_TIMER
    NEG BX 
    MOV VEL_X,BX
    MOV VEL_Y,0
    JMP TEST_TIMER

TK_RIGHT:
    CMP SCAN_CODE,RIGHT_ARROW
    JNE TEST_TIMER
    CMP VEL_X,0
    JL TEST_TIMER    
    MOV VEL_X,BX 
    MOV VEL_Y,0
    JMP TEST_TIMER
    
; wait for timer tick before moving the ball
TEST_TIMER:
    CMP TIMER_FLAG, 1
    JNE LK
    MOV TIMER_FLAG, 0
    CMP END_W,1
    JE END_
    CMP END_F,1
    JE END_
    CALL MOVE_BALL
tt2:
    CMP TIMER_FLAG, 1
    JNE tt2
    MOV TIMER_FLAG, 0
    JMP TEST_TIMER 

F_END:
    JMP DON
WN_END:
    LEA DX,MSG_2
    JMP DON
END_:
    MOV AL, 0
    MOV CX,FOOD_X
    MOV DX,FOOD_Y
    MOV BX,VEL
    SUB BX,2
    CALL DRAW_CELL
    CALL display_SNAKE
    CALL DRAW_OBST
    
    CMP END_F,1 
    JE F_END 
 
    CMP END_W,1
    JE WN_END
    
    DON:
 
    LEA  DI,NEW_TIMER_VEC
    LEA  SI,OLD_TIMER_VEC
    MOV  AL,1CH
    CALL SETUP_INT

    LEA DI,NEW_KEY_VEC
    LEA SI,OLD_KEY_VEC
    MOV AL,9H 
    CALL SETUP_INT
    CALL GAME_OVER
    RET

NEW_GAME ENDP
     

MAIN PROC
    MOV AX, @data
    MOV DS, AX
    MOV ES, AX
    CALL MAIN_MENU   
    MOV AH,4CH
    INT 21H
    
MAIN ENDP
END MAIN
