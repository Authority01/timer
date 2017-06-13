;=================================================
;�������
;=================================================
SCK 		BIT 	P0.4
RCK 		BIT 	P0.5
RST 		BIT 	P0.6
DAT 		BIT 	P0.7
MODE		EQU		11H		 ;��ʱ������ģʽMODE1
TIMES		EQU		10		 ;��ʱ��ѭ������
NOT_TWINKLE	BIT		20H.0	 ;����������Ƿ���˸
STOP_1		BIT		20H.1	
STOP_2		BIT		20H.2
STOP_3		BIT		20H.3
STOP_4		BIT		20H.4
MINH		EQU		21H
MINL		EQU		22H
SECH		EQU		23H
SECL		EQU		24H
COUNT		EQU		25H		  ;��ʱ����ѭ��


;=================================================
;�����ж�����
;=================================================
			ORG		0
			AJMP	START
			ORG		03H		 ;�����ж�����INT0
			AJMP	RESET
			ORG		0BH		 ;���ö�ʱ��TIMER0�ж�
			AJMP	TIMER0
			ORG		13H		 ;�����ж�����INT1
			AJMP	START_OR_STOP
			ORG		1BH		 ;���ö�ʱ��TIMER1�ж�
			AJMP	TIMER1
			
			
;=================================================
;��������START
;���ܣ���ʼ���ͱ����������ʾ
;=================================================					
START:		MOV 	P0, #00H 
			MOV		DPTR,#TAB;������׵�ַ��ֵ��DPTR
			MOV		MINH,#0	 ;����ʱ����ʼ��
			MOV		MINL,#0
			MOV		SECH,#0
			MOV		SECL,#0
			SETB 	EA		 ;���ж��ܿ���
			SETB	EX0		 ;���ж�INT0�Ŀ���		
			SETB	ET0		 ;�򿪼�ʱ��TIMER0�жϵĿ���
			SETB	ET1		 ;�򿪼�ʱ��TIMER1�жϵĿ���
			SETB	PT1		 ;��߼�ʱ��TIMER1�жϵ����ȼ���ʹ��������INT0			
			CLR		IT0		 ;INT0���õ͵�ƽ����
			CLR		IT1		 ;INT1���õ͵�ƽ����
			MOV		TMOD,#MODE	;���ö�ʱ��ģʽ
			SETB	NOT_TWINKLE
			MOV		TH0,#3CH	;65535-50000 = 3CAFH������6MHzʱ����ʱ��ÿ�ζ�ʱ0.1s
			MOV		TL0,#0AFH
			MOV		TH1,#0B1H	;65535-20000 = B1DFH������6MHzʱ����ʱ��ÿ�ζ�ʱ0.04s
			MOV		TL1,#0DFH
			MOV		R3,#TIMES	;���ƶ�ʱ��TIMER0ѭ������
			MOV		R5,#TIMES	;���ƶ�ʱ��TIMER1ѭ������
			MOV		SP,#30H		;�ƿ���ջָ������ͻ
MAIN_LOOP:	ACALL	DISPLAY		;�������ʾ			
			AJMP	MAIN_LOOP




;=================================================
;INT0�жϺ�����RESET
;���ܣ����û�ͨ������������õ���ʱʱ��
;	   ������ʱ������Ϊ00��00-59��59
;	   �����ڴ���������������Ч
;	   ����δ���ǰ����ܴ�����˸״̬
;=================================================
RESET:		CLR		EX0			 ;�ر��ж�INT0,��ֹ����ж�
			ACALL	DELAY		 ;��������
			CLR		TR0			 ;�ر�TIMER0������ʱ��ͣ
			SETB	TR1			 ;��TIMER1���������˸
			SETB	EX1		 	 ;���ж�INT1�Ŀ���
			JB		IE0,RESET_EXIT
			MOV		MINH,#0		 ;��ʼ������ʱ��
			MOV		MINL,#0
			MOV		SECH,#0
			MOV		SECL,#0

SCAN1:		MOV		C,NOT_TWINKLE
			MOV		STOP_1,C
			ACALL	SCAN		 ;ɨ���һ�μ�������
			CJNE	R4,#0FFH,NEXT1;���R4! = 0FFH���������룬��ת��һ��
			SJMP	SCAN1		 ;û����������ɨ��
NEXT1:		MOV		A,R4		 ;���ӵ�һλҪС��6
			CLR		C
			SUBB	A,#6
			JNC		SCAN1		 ;����5����ɨ��
			MOV		MINH,R4
			CLR		STOP_1

			ACALL	SCAN_DELAY	 ;����ɨ��֮��Ҫ��ʱ

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

RESET_EXIT:	CLR		TR1			 ;�ر�TIMER1��ֹͣ��˸
			SETB	EX0			 ;��INT0����
			RETI




;=================================================
;INT1�жϺ���START_OR_STOP
;���ܣ���ͣ�ͼ�������ʱ��Ҳ�������رշ�����
;=================================================
START_OR_STOP:
			CLR		EX1
			ACALL	DELAY
			JB		IE1,STOP_EXIT
			CPL		TR0		;ͨ������/�ر�TIMER0,ʵ����ͣ�ͼ�������ʱ
STOP_EXIT:	SETB	EX1
			RETI



;=================================================
;TIMER0�жϺ���TIMER0
;���ܣ�ÿ10�ζ�ʱ�������1�룩������ʱ����һ��
;=================================================
TIMER0:		DJNZ	R3,TIMER0_AGAIN
			ACALL	DECREASE
			MOV		R3,#TIMES
TIMER0_AGAIN:MOV	TH0,#3CH
			MOV		TL0,#0AFH
			SETB	TR0
			RETI



;=================================================
;TIMER1�жϺ���TIMER1
;���ܣ�ÿ10�ζ�ʱ�������0.4�룩���ı��Ƿ���˸��־1��
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
;���ܣ��������ʾ
;=================================================							
DISPLAY:	JB		STOP_1,DISP_NEXT1;�����������ʾ���ر��رգ�������
			MOV		P0,#01H		 ;������һ�������
			MOV		A,MINH
			MOVC	A,@A+DPTR	 ;�������Ҫ��ʾ���ֵı���
			MOV		R0,A
			ACALL 	SHOW_NUM	 ;��ʾ����
			ACALL 	DELAY		 ;��ʱһ��ʱ�䣬�Ӿ�����

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
;���ܣ�����ʱ����1��
;	   �������ʱ��ɱ���00��00,����������,��ͨ��INT1�ر�	 
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

			;��ʱ����ʱ��ɣ�����00��00������������
			MOV		MINH,#0
			MOV		MINL,#0
			MOV		SECH,#0
			MOV		SECL,#0
			CLR		P1.3	   ;����������			
			ACALL	SCAN_DELAY	  
			SETB	P1.3	   ;�������ر�
									
DEC_EXIT:	RET

			
;=================================================
;DELAY
;���ܣ���ʱ12ms
;=================================================
DELAY:  	MOV 	R7, #200  		;Լ12ms   
DL1:		MOV 	R6, #30
			DJNZ 	R6, $    	
			DJNZ 	R7, DL1
    		RET


;=================================================
;SCAN_DELAY
;���ܣ���ʱ0.25s���ұ����������ʾ
;=================================================
SCAN_DELAY: MOV  	COUNT,#20		;Լ0.25s
DL2:		ACALL	DELAY
			ACALL	DISPLAY
			DJNZ	COUNT,DL2
			RET 

;=================================================
;SCAN
;���ܣ�����ɨ�裬ɨ����������R4��
;û�а������£�����������ΪA-F��R4Ϊ0FFH
;��������Ϊ0-9��R4Ϊ0-9
;=================================================
SCAN:		MOV		R4,#0FFH
			ACALL	DISPLAY				 ;ɨ����̱�����˸
			MOV		P2,#0FH				 ;�Ƚ�����ɨ��
			MOV		A,P2
			CJNE	A,#0FH, SCAN_SHAKE	 ;���P2!=0FH,���а��������£���ת��������
			AJMP	SCAN_EXIT			 ;û�а������£��˳�����ɨ��
SCAN_SHAKE:	ACALL	DELAY
			MOV		A,P2
			CJNE	A,#0FH, SCAN_ROW	 ;����ȷ���а������£�������ɨ��
			AJMP	SCAN_EXIT
SCAN_ROW: 	MOV		R4,P2
			MOV		P2,#0F0H
			MOV		A,P2
			ORL		A,R4				 ;������ɨ���������߼���������
			MOV		R4,#0FFH
			CJNE	A,#11100111B,N1		 ;���ݽ���ж����ĸ���������
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
;���ܣ��������ʾһ������
;�������R0ΪҪ��ʾ���ֵ�����ܱ���
;=================================================				
SHOW_NUM:	MOV 	R1, #8H;
			MOV 	A, #00000001B		
		 	MOV 	R2,A		 
SHIFT:		ANL 	A,R0			;��������λ����DAT��
		 	JNZ 	SET_DAT
		 	CLR 	DAT
			AJMP 	SET_SCK
SET_DAT:	SETB 	DAT	
SET_SCK:	SETB 	SCK				;SCK����һ�����أ���DAT�ϵ���������74HC595��λ�Ĵ����У����͵�λ�����͸�λ
		 	CLR 	SCK	 
		 	MOV 	A,R2
		 	RL 		A
		 	MOV 	R2,A
		 	DJNZ 	R1,SHIFT			 
		 	SETB 	RCK				;����DAT�����������ݼĴ����е��������뵽���������,ʵ�ֲ������
		 	CLR 	RCK
SHOW_EXIT:	RET


;=================================================
;����ܱ����
;=================================================
TAB:		DB 		0fcH,60H,0daH,0f2H,66H,0b6H,0beH,0e0H,0feH,0f6H		
			
			END