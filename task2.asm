;=================================================
;定义变量
;=================================================
SCK 		BIT 	P0.4
RCK 		BIT 	P0.5
RST 		BIT 	P0.6
DAT 		BIT 	P0.7
MODE		EQU		11H		 ;计时器工作模式MODE1
TIMES		EQU		10		 ;计时器循环次数
NOT_TWINKLE	BIT		20H.0	 ;控制数码管是否闪烁
STOP_1		BIT		20H.1	
STOP_2		BIT		20H.2
STOP_3		BIT		20H.3
STOP_4		BIT		20H.4
MINH		EQU		21H
MINL		EQU		22H
SECH		EQU		23H
SECL		EQU		24H
COUNT		EQU		25H		  ;延时函数循环


;=================================================
;设置中断向量
;=================================================
			ORG		0
			AJMP	START
			ORG		03H		 ;设置中断向量INT0
			AJMP	RESET
			ORG		0BH		 ;设置定时器TIMER0中断
			AJMP	TIMER0
			ORG		13H		 ;设置中断向量INT1
			AJMP	START_OR_STOP
			ORG		1BH		 ;设置定时器TIMER1中断
			AJMP	TIMER1
			
			
;=================================================
;主函数：START
;功能：初始化和保持数码管显示
;=================================================					
START:		MOV 	P0, #00H 
			MOV		DPTR,#TAB;将表的首地址赋值给DPTR
			MOV		MINH,#0	 ;倒计时器初始化
			MOV		MINL,#0
			MOV		SECH,#0
			MOV		SECL,#0
			SETB 	EA		 ;打开中断总开关
			SETB	EX0		 ;打开中断INT0的开关		
			SETB	ET0		 ;打开计时器TIMER0中断的开关
			SETB	ET1		 ;打开计时器TIMER1中断的开关
			SETB	PT1		 ;提高计时器TIMER1中断的优先级，使其优先于INT0			
			CLR		IT0		 ;INT0采用低电平触发
			CLR		IT1		 ;INT1采用低电平触发
			MOV		TMOD,#MODE	;设置定时器模式
			SETB	NOT_TWINKLE
			MOV		TH0,#3CH	;65535-50000 = 3CAFH，晶振6MHz时，定时器每次定时0.1s
			MOV		TL0,#0AFH
			MOV		TH1,#0B1H	;65535-20000 = B1DFH，晶振6MHz时，定时器每次定时0.04s
			MOV		TL1,#0DFH
			MOV		R3,#TIMES	;控制定时器TIMER0循环次数
			MOV		R5,#TIMES	;控制定时器TIMER1循环次数
			MOV		SP,#30H		;移开堆栈指针避免冲突
MAIN_LOOP:	ACALL	DISPLAY		;数码管显示			
			AJMP	MAIN_LOOP




;=================================================
;INT0中断函数：RESET
;功能：由用户通过矩阵键盘设置倒计时时长
;	   可设置时长区间为00；00-59：59
;	   若不在此区间内则输入无效
;	   设置未完成前数码管处于闪烁状态
;=================================================
RESET:		CLR		EX0			 ;关闭中断INT0,防止多次中断
			ACALL	DELAY		 ;按键消抖
			CLR		TR0			 ;关闭TIMER0，倒计时暂停
			SETB	TR1			 ;打开TIMER1，数码管闪烁
			SETB	EX1		 	 ;打开中断INT1的开关
			JB		IE0,RESET_EXIT
			MOV		MINH,#0		 ;初始化倒计时器
			MOV		MINL,#0
			MOV		SECH,#0
			MOV		SECL,#0

SCAN1:		MOV		C,NOT_TWINKLE
			MOV		STOP_1,C
			ACALL	SCAN		 ;扫描第一次键盘输入
			CJNE	R4,#0FFH,NEXT1;如果R4! = 0FFH，则有输入，跳转下一步
			SJMP	SCAN1		 ;没有输入重新扫描
NEXT1:		MOV		A,R4		 ;分钟第一位要小于6
			CLR		C
			SUBB	A,#6
			JNC		SCAN1		 ;超过5重新扫描
			MOV		MINH,R4
			CLR		STOP_1

			ACALL	SCAN_DELAY	 ;两次扫描之间要延时

SCAN2:		MOV		C,NOT_TWINKLE
			MOV		STOP_2,C
			ACALL	SCAN
			CJNE	R4,#0FFH,NEXT2
			SJMP	SCAN2
NEXT2:		MOV		MINL,R4
			CLR		STOP_2

			ACALL	SCAN_DELAY

SCAN3:		MOV		C,NOT_TWINKLE
			MOV		STOP_3,C
			ACALL	SCAN
			CJNE	R4,#0FFH,NEXT3
			SJMP	SCAN3
NEXT3:		MOV		A,R4
			CLR		C
			SUBB	A,#6
			JNC		SCAN3
			MOV		SECH,R4
			CLR		STOP_3

			ACALL	SCAN_DELAY

SCAN4:		MOV		C,NOT_TWINKLE
			MOV		STOP_4,C
			ACALL	SCAN
			CJNE	R4,#0FFH,NEXT4
			SJMP	SCAN4
NEXT4:		MOV		SECL,R4
			CLR		STOP_4

RESET_EXIT:	CLR		TR1			 ;关闭TIMER1，停止闪烁
			SETB	EX0			 ;打开INT0开关
			RETI




;=================================================
;INT1中断函数START_OR_STOP
;功能：暂停和继续倒计时，也可用来关闭蜂鸣器
;=================================================
START_OR_STOP:
			CLR		EX1
			ACALL	DELAY
			JB		IE1,STOP_EXIT
			CPL		TR0		;通过开启/关闭TIMER0,实现暂停和继续倒计时
STOP_EXIT:	SETB	EX1
			RETI



;=================================================
;TIMER0中断函数TIMER0
;功能：每10次定时器溢出（1秒），倒计时减少一秒
;=================================================
TIMER0:		DJNZ	R3,TIMER0_AGAIN
			ACALL	DECREASE
			MOV		R3,#TIMES
TIMER0_AGAIN:MOV	TH0,#3CH
			MOV		TL0,#0AFH
			SETB	TR0
			RETI



;=================================================
;TIMER1中断函数TIMER1
;功能：每10次定时器溢出（0.4秒），改变是否闪烁标志1次
;=================================================
TIMER1:		DJNZ	R5,TIMER1_AGAIN
			CPL		NOT_TWINKLE
			MOV		R5,#TIMES
TIMER1_AGAIN:MOV	TH1,#0B1H
			MOV		TL1,#0DFH
			SETB	TR1
			RETI


;=================================================
;DISPLAY
;功能：数码管显示
;=================================================							
DISPLAY:	JB		STOP_1,DISP_NEXT1;若该数码管显示开关被关闭，则跳过
			MOV		P0,#01H		 ;开启第一个数码管
			MOV		A,MINH
			MOVC	A,@A+DPTR	 ;查表获得所要显示数字的编码
			MOV		R0,A
			ACALL 	SHOW_NUM	 ;显示数字
			ACALL 	DELAY		 ;延时一段时间，视觉暂留

DISP_NEXT1:	JB		STOP_2,DISP_NEXT2
			MOV		P0,#02H
			MOV		A,MINL
			MOVC	A,@A+DPTR
			MOV		R0,A
			ACALL	SHOW_NUM
			ACALL 	DELAY

DISP_NEXT2:	JB		STOP_3,DISP_NEXT3
			MOV		P0,#04H
			MOV		A,SECH
			MOVC	A,@A+DPTR
			MOV		R0,A
			ACALL	SHOW_NUM
			ACALL 	DELAY

DISP_NEXT3:	JB		STOP_4,DISP_EXIT
			MOV		P0,#08H
			MOV		A,SECL
			MOVC	A,@A+DPTR
			MOV		R0,A
			ACALL	SHOW_NUM
			ACALL 	DELAY
DISP_EXIT:	RET	
								
;=================================================
;DECREASE
;功能：倒计时减少1秒
;	   如果倒计时完成保持00：00,蜂鸣器发声,可通过INT1关闭	 
;=================================================
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

			;此时倒计时完成，保持00：00，蜂鸣器发声
			MOV		MINH,#0
			MOV		MINL,#0
			MOV		SECH,#0
			MOV		SECL,#0
			CLR		P1.3	   ;蜂鸣器发声			
			ACALL	SCAN_DELAY	  
			SETB	P1.3	   ;蜂鸣器关闭
									
DEC_EXIT:	RET

			
;=================================================
;DELAY
;功能：延时12ms
;=================================================
DELAY:  	MOV 	R7, #200  		;约12ms   
DL1:		MOV 	R6, #30
			DJNZ 	R6, $    	
			DJNZ 	R7, DL1
    		RET


;=================================================
;SCAN_DELAY
;功能：延时0.25s，且保持数码管显示
;=================================================
SCAN_DELAY: MOV  	COUNT,#20		;约0.25s
DL2:		ACALL	DELAY
			ACALL	DISPLAY
			DJNZ	COUNT,DL2
			RET 

;=================================================
;SCAN
;功能：键盘扫描，扫描结果储存在R4中
;没有按键按下，或所按按键为A-F，R4为0FFH
;所按按键为0-9，R4为0-9
;=================================================
SCAN:		MOV		R4,#0FFH
			ACALL	DISPLAY				 ;扫描过程保持闪烁
			MOV		P2,#0FH				 ;先进行列扫描
			MOV		A,P2
			CJNE	A,#0FH, SCAN_SHAKE	 ;如果P2!=0FH,则有按键被按下，跳转进行消抖
			AJMP	SCAN_EXIT			 ;没有按键按下，退出重新扫描
SCAN_SHAKE:	ACALL	DELAY
			MOV		A,P2
			CJNE	A,#0FH, SCAN_ROW	 ;消抖确认有按键按下，进行行扫描
			AJMP	SCAN_EXIT
SCAN_ROW: 	MOV		R4,P2
			MOV		P2,#0F0H
			MOV		A,P2
			ORL		A,R4				 ;将行列扫描结果进行逻辑“或”运算
			MOV		R4,#0FFH
			CJNE	A,#11100111B,N1		 ;根据结果判断是哪个按键按下
			MOV		R4,#0
			AJMP	SCAN_EXIT
N1:			CJNE	A,#11101011B,N2
			MOV		R4,#1
			AJMP	SCAN_EXIT
N2:			CJNE	A,#11101101B,N3
			MOV		R4,#2
			AJMP	SCAN_EXIT
N3:			CJNE	A,#11101110B,N4
			MOV		R4,#3
			AJMP	SCAN_EXIT
N4:			CJNE	A,#11010111B,N5
			MOV		R4,#4
			AJMP	SCAN_EXIT
N5:			CJNE	A,#11011011B,N6
			MOV		R4,#5
			AJMP	SCAN_EXIT
N6:			CJNE	A,#11011101B,N7
			MOV		R4,#6
			AJMP	SCAN_EXIT
N7:			CJNE	A,#11011110B,N8
			MOV		R4,#7
			AJMP	SCAN_EXIT
N8:			CJNE	A,#10110111B,N9
			MOV		R4,#8
			AJMP	SCAN_EXIT
N9:			CJNE	A,#10111011B,SCAN_EXIT
			MOV		R4,#9	
SCAN_EXIT:	RET


;=================================================
;SHOW_NUM
;功能：数码管显示一个数字
;输入参数R0为要显示数字的数码管编码
;=================================================				
SHOW_NUM:	MOV 	R1, #8H;
			MOV 	A, #00000001B		
		 	MOV 	R2,A		 
SHIFT:		ANL 	A,R0			;将数据逐位传至DAT脚
		 	JNZ 	SET_DAT
		 	CLR 	DAT
			AJMP 	SET_SCK
SET_DAT:	SETB 	DAT	
SET_SCK:	SETB 	SCK				;SCK产生一上升沿，将DAT上的数据移入74HC595移位寄存器中，先送低位，后送高位
		 	CLR 	SCK	 
		 	MOV 	A,R2
		 	RL 		A
		 	MOV 	R2,A
		 	DJNZ 	R1,SHIFT			 
		 	SETB 	RCK				;将由DAT上已移入数据寄存器中的数据送入到输出锁存器,实现并行输出
		 	CLR 	RCK
SHOW_EXIT:	RET


;=================================================
;数码管编码表
;=================================================
TAB:		DB 		0fcH,60H,0daH,0f2H,66H,0b6H,0beH,0e0H,0feH,0f6H		
			
			END