SCK 		BIT 	P0.4;
RCK 		BIT 	P0.5;
RST 		BIT 	P0.6;
DAT 		BIT 	P0.7;
MODE		EQU		01H
TIMES		EQU		10
NOT_TWINKLE	BIT		20H.0		
MINH		EQU		21H
MINL		EQU		22H
SECH		EQU		23H
SECL		EQU		24H
COUNT		EQU		25H

			ORG		0
			AJMP	START
			ORG		03H
			AJMP	RESET
			ORG		0BH
			AJMP	TIMER0
			ORG		13H		 ;设置中断向量INT1
			AJMP	START_OR_STOP
			ORG		1BH
			AJMP	TIMER1		
START:		MOV 	P0, #00H
			MOV		DPTR,#TAB
			MOV		MINH,#0
			MOV		MINL,#0
			MOV		SECH,#0
			MOV		SECL,#0
			SETB 	EA		 ;打开中断总开关
			SETB	EX0		 ;打开中断INT0的开关		
			SETB	ET0		 ;打开计时器TIMER0中断的开关
			SETB	ET1		 ;打开计时器TIMER1中断的开关
			SETB	PT1		 ;提高计时器TIMER1中断的优先级			
			SETB	IT0		 ;INT0采用下降沿触发
			SETB	IT1		 ;INT1采用下降沿触发
			MOV		TMOD,#MODE	;设置定时器模式
			SETB	NOT_TWINKLE
			MOV		TH0,#3CH	;65536-50000 = 3CB0H
			MOV		TL0,#0B0H
			MOV		TH1,#3CH	;65536-25000 = 9E58H
			MOV		TL1,#0B0H
			MOV		R3,#TIMES
			MOV		R5,#TIMES
			MOV		SP,#30H		;移开堆栈指针避免冲突
MAIN_LOOP:	
			ACALL	DISPLAY					
			AJMP	MAIN_LOOP

START_OR_STOP:
			CLR		EX1
			ACALL	DELAY
			JB		IE1,STOP_EXIT
			CPL		TR0
STOP_EXIT:	SETB	EX1
			RETI

RESET:		CLR		EX0
			ACALL	DELAY
			JB		IE0,RESET_EXIT
			CLR		TR0			 ;关闭TIMER0
			SETB	TR1			 ;打开TIMER1
			SETB	EX1		 ;打开中断INT1的开关
			MOV		MINH,#0
			MOV		MINL,#0
			MOV		SECH,#0
			MOV		SECL,#0
SCAN1:		ACALL	SCAN
			CJNE	R4,#0FFH,NEXT1
			SJMP	SCAN1
NEXT1:		MOV		A,R4
			CLR		C
			SUBB	A,#6
			JNC		SCAN1
			MOV		MINH,R4

			ACALL	SCAN_DELAY

SCAN2:		ACALL	SCAN
			CJNE	R4,#0FFH,NEXT2
			SJMP	SCAN2
NEXT2:		MOV		MINL,R4

			ACALL	SCAN_DELAY

SCAN3:		ACALL	SCAN
			CJNE	R4,#0FFH,NEXT3
			SJMP	SCAN3
NEXT3:		MOV		A,R4
			CLR		C
			SUBB	A,#6
			JNC		SCAN3
			MOV		SECH,R4

			ACALL	SCAN_DELAY

SCAN4:		ACALL	SCAN
			CJNE	R4,#0FFH,NEXT4
			SJMP	SCAN4
NEXT4:		MOV		SECL,R4					
RESET_EXIT:	CLR		TR1			 ;关闭TIMER1
			CLR		NOT_TWINKLE	
			SETB	TR0
			SETB	EX0
			RETI




TIMER0:		DJNZ	R3,TIMER0_AGAIN
			ACALL	DECREASE
			MOV		R3,#TIMES
TIMER0_AGAIN:MOV	TH0,#3CH
			MOV		TL0,#0B0H
			SETB	TR0
			RETI

TIMER1:		DJNZ	R5,TIMER1_AGAIN
			CPL		NOT_TWINKLE
			MOV		R5,#TIMES
TIMER1_AGAIN:MOV	TH1,#3CH
			MOV		TL1,#0BH
			SETB	TR1
			RETI
			RETI

TWINKLE:	JB		NOT_TWINKLE,TWINKLE_NEXT
			MOV		P0, #0
			AJMP	TWINKLE_EXIT
TWINKLE_NEXT:ACALL	DISPLAY					
TWINKLE_EXIT:RET
							
DISPLAY:	MOV		P0,#01H
			MOV		A,MINH
			MOVC	A,@A+DPTR
			MOV		R0,A
			ACALL 	SHOW_NUM
			ACALL 	DELAY

			MOV		P0,#02H
			MOV		A,MINL
			MOVC	A,@A+DPTR
			MOV		R0,A
			ACALL	SHOW_NUM
			ACALL 	DELAY

			MOV		P0,#04H
			MOV		A,SECH
			MOVC	A,@A+DPTR
			MOV		R0,A
			ACALL	SHOW_NUM
			ACALL 	DELAY

			MOV		P0,#08H
			MOV		A,SECL
			MOVC	A,@A+DPTR
			MOV		R0,A
			ACALL	SHOW_NUM
			ACALL 	DELAY
			RET			

DECREASE:	DEC		SECL
			MOV		A,#0FFH
			CJNE	A,SECL,DEC_EXIT
			MOV		SECL,#9

			DEC		SECH
			MOV		A,#0FFH
			CJNE	A,SECH,DEC_EXIT
			MOV		SECH,#5

			DEC		MINL
			MOV		A,#0FFH
			CJNE	A,MINL,DEC_EXIT
			MOV		MINL,#9

			DEC		MINH
			MOV		A,#0FFH
			CJNE	A,MINH,DEC_EXIT
			MOV		MINH,#0
			MOV		MINL,#0
			MOV		SECH,#0
			MOV		SECL,#0
			CLR		EX1
			CLR		P1.3
			ACALL	SCAN_DELAY
			SETB	P1.3						
DEC_EXIT:	RET
			

DELAY:  	MOV 	R7, #200  		;约2ms   
DL1:		MOV 	R6, #30
			DJNZ 	R6, $    	
			DJNZ 	R7, DL1
    		RET

SCAN_DELAY: MOV  	COUNT,#40
DL2:		ACALL	DELAY
			ACALL	TWINKLE
			DJNZ	COUNT,DL2
			RET 

SCAN:		MOV		R4,#0FFH
			ACALL	TWINKLE
			MOV		P2,#0FH
			MOV		A,P2
			CJNE	A,#0FH, SCAN_SHAKE
			AJMP	SCAN_EXIT
SCAN_SHAKE:	ACALL	DELAY
			MOV		A,P2
			CJNE	A,#0FH, SCAN_ROW
			AJMP	SCAN_EXIT
SCAN_ROW: 	MOV		R4,P2
			MOV		P2,#0F0H
			MOV		A,P2
			ORL		A,R4
			MOV		R4,#0FFH
			CJNE	A,#11101110B,N1
			MOV		R4,#0
			AJMP	SCAN_EXIT
N1:			CJNE	A,#11011110B,N2
			MOV		R4,#1
			AJMP	SCAN_EXIT
N2:			CJNE	A,#10111110B,N3
			MOV		R4,#2
			AJMP	SCAN_EXIT
N3:			CJNE	A,#01111110B,N4
			MOV		R4,#3
			AJMP	SCAN_EXIT
N4:			CJNE	A,#11101101B,N5
			MOV		R4,#4
			AJMP	SCAN_EXIT
N5:			CJNE	A,#11011101B,N6
			MOV		R4,#5
			AJMP	SCAN_EXIT
N6:			CJNE	A,#10111101B,N7
			MOV		R4,#6
			AJMP	SCAN_EXIT
N7:			CJNE	A,#01111101B,N8
			MOV		R4,#7
			AJMP	SCAN_EXIT
N8:			CJNE	A,#11101011B,N9
			MOV		R4,#8
			AJMP	SCAN_EXIT
N9:			CJNE	A,#11011011B,SCAN_EXIT
			MOV		R4,#9	
SCAN_EXIT:	RET
				
	 ;INPUT PARAMETER:R0
SHOW_NUM:	MOV 	R1, #8H;
			MOV 	A, #00000001B		
		 	MOV 	R2,A		 
SHIFT:		ANL 	A,R0			;pick out one bit,from right to left
		 	JNZ 	SET_DAT
		 	CLR 	DAT
SET_SCK:	SETB 	SCK
		 	CLR 	SCK	 
		 	MOV 	A,R2
		 	RL 		A
		 	MOV 	R2,A
		 	DJNZ 	R1,SHIFT			 
		 	SETB 	RCK
		 	CLR 	RCK
		 	AJMP 	SHOW_EXIT
SET_DAT:	SETB 	DAT	
			AJMP 	SET_SCK
SHOW_EXIT:	RET

TAB:		DB 		0fcH,60H,0daH,0f2H,66H,0b6H,0beH,0e0H,0feH,0f6H		
			
			END