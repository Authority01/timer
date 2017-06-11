SCK 		BIT 	P0.4;
RCK 		BIT 	P0.5;
RST 		BIT 	P0.6;
DAT 		BIT 	P0.7;
MODE		EQU		01H
TIMES		EQU		40
MINH		EQU		21H
MINL		EQU		22H
SECH		EQU		23H
SECL		EQU		24H

			ORG		0
			AJMP	START
			ORG		03H
			AJMP	RESET
			ORG		0BH
			AJMP	TIMER0
			ORG		13H		 ;设置中断向量INT1
			AJMP	START_OR_STOP		
START:		MOV 	P0, #00H
			MOV		DPTR,#TAB
			MOV		MINH,#0
			MOV		MINL,#0
			MOV		SECH,#0
			MOV		SECL,#0
			SETB 	EA		 ;打开中断总开关
			SETB	EX0		 ;打开中断INT0的开关
			SETB	EX1		 ;打开中断INT1的开关
			SETB	ET0		 ;打开计时器TIMER1中断的开关			
			SETB	IT0		 ;INT0采用下降沿触发
			SETB	IT1		 ;INT1采用下降沿触发
			MOV		TMOD,#MODE	;设置定时器模式
			SETB	TR0
			MOV		TH0,#0C3H	;65536-50000 = C350H
			MOV		TL0,#50H
			MOV		R3,#TIMES
			MOV		SP,#30H		;移开堆栈指针避免冲突
MAINLOOP:	
			ACALL	DISPLAY					
			AJMP	MAINLOOP

START_OR_STOP:		
			CPL		TR0
			RETI

RESET:		MOV		MINH,#0
			MOV		MINL,#0
			MOV		SECH,#0
			MOV		SECL,#0
			CLR		TR0
			RETI

TIMER0:		DJNZ	R3,AGAIN
			ACALL	INCREASE
			MOV		R3,#TIMES
AGAIN:		MOV		TH0,#0C3H
			MOV		TL0,#50H
			SETB	TR0
			RETI

							
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

INCREASE:	INC		SECL
			MOV		A,#10
			CJNE	A,SECL,INC_EXIT
			MOV		SECL,#0

			INC		SECH
			MOV		A,#6
			CJNE	A,SECH,INC_EXIT
			MOV		SECH,#0

			INC		MINL
			MOV		A,#10
			CJNE	A,MINL,INC_EXIT
			MOV		MINL,#0

			INC		MINH
			MOV		A,#6
			CJNE	A,MINH,INC_EXIT
			MOV		MINH,#0			
INC_EXIT:	RET
			

DELAY:  	MOV 	R7, #200  		;约2ms   
DL1:		MOV 	R6, #10
			DJNZ 	R6, $    	
			DJNZ 	R7, DL1
    		RET

				
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