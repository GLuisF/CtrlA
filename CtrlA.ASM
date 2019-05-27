;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                                                                     *
;* Copyright (c) GLuisF Automation & TI. Todos direitos reservados.    *
;*                                                                     *
;* Nome Modulo:    	CtrlA.ASM                                      *
;* Microcontrolador:	AT89S8252-24PC                                 * 
;* Cristal:		12MHz                                          *
;*                                                                     *
;* Descricao:      Firmware do controle de acesso e segurança          *
;*                                                                     *
;*                                                                     *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

$MOD51
        RS      EQU P2.1		;pino 4 display
        RW      EQU P2.2		;pino 5
        EN      EQU P2.3		;pino 6
        D4	EQU P2.4		;pino 12
        D5	EQU P2.5 		;pino 13
        D6	EQU P2.6		;pino 14
        D7	EQU P2.7		;pino 15
                
        LINA    EQU P0.0		;linhas do teclado
        LINB    EQU P0.1
        LINC    EQU P0.2
        LIND    EQU P0.3
        COL1    EQU P0.4		;colunas do teclado
        COL2    EQU P0.5
        COL3    EQU P0.6
        COL4    EQU P0.7
        
        SOLEN	EQU P3.4		;solenóide da porta
        SENSOR 	EQU P3.5		;sensor fim-de-curso
        BUZZER	EQU P3.6
        RX	EQU P3.0
        
        LIN1    EQU 80H			;seleciona linha 1 do display
        LIN2    EQU 0C0H		;seleciona linha 2 do display
        
        N1	EQU 20H			;1º byte da senha digitada
        N2	EQU 21H			;2º byte da senha digitada
        N3	EQU 22H			;3º byte da senha digitada
        N4	EQU 23H			;4º byte da senha digitada
        N5	EQU 24H			;5º byte da senha digitada
        N6      EQU 25H			;6º byte da senha digitada
        
        NUMERO	EQU 1FH			;local onde o Nº digitado é salvo
        POSICAO	EQU R1			;local onde a posição do cursor no display é salvo
        
        ORG     RESET			;endereço após o reset
        JMP     MAIN			;pula para MAIN
	
;mensagens gravadas na memória de código do microcontrolador
MSG0:	DB	'  CONTROLE DE',0
MSG1: 	DB 	'ACESSO',0
MSG2: 	DB 	' DIGITE A SENHA',0
MSG3:	DB	' ACESSO  NEGADO',0
MSG4:	DB	'ACESSO  LIBERADO',0
NS:	DB 	'0123456789'		;caracteres numéricos
SENHA: 	DB 	0,1,7,7,5,8		;senha salva na EEPROM
                
MAIN:   CLR     RW              	;Display no modo de escrita
	CLR	SOLEN			;desliga solenóide
	CLR	BUZZER			;desliga buzzer
        LCALL   LCD_INIT        	;Inicializa display
        
START: 	MOV     A,#01H         		;Limpa display e move cursor para linha 1
     	LCALL 	COMAND
	MOV	A,#MSG0			;Escreve 'CONTROLE DE'
	LCALL	MENSAGEM
	MOV	A,#LIN2+5		;Seleciona a linha 2 posição 5
	LCALL	COMAND
	MOV	A,#MSG1			;Escreve 'DE ACESSO'
	LCALL	MENSAGEM
	MOV	A,#100			;Espera 1s
	LCALL	WAIT_MS
	JNB	RX,$			;espera leitor ler
	MOV	A,#100			;Espera 1s
	LCALL	WAIT_MS
		
PROCES: MOV     A,#01H         		;Limpa display e move cursor para linha 1
     	LCALL 	COMAND
	
	MOV	A,#MSG2			;Escreve  'DIGITE A SENHA'
	LCALL	MENSAGEM
        
	MOV     A,#LIN2+5     		;Seleciona a linha 2 posição 5
        LCALL   COMAND
        
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;Controle matriz de teclado
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
INICIO: CLR     LINA			;seleciona a linha A
        JB      COL1,NEXT0
        MOV	A,#7
        LCALL   TECLA
NEXT0:  JB      COL2,NEXT1
        MOV	A,#8
        LCALL   TECLA
NEXT1:  JB      COL3,NEXT2
        MOV	A,#9
        LCALL   TECLA
NEXT2:  JB      COL4,NEXT3
        ;LCALL   TECLAF3
NEXT3:  SETB    LINA

        CLR     LINB			;seleciona a linha B
        JB     COL1,NEXT4
        MOV	A,#4
        LCALL   TECLA
NEXT4:  JB     COL2,NEXT5
        MOV	A,#5
        LCALL   TECLA
NEXT5:  JB     COL3,NEXT6
        MOV	A,#6
        LCALL   TECLA
NEXT6:  JB     COL4,NEXT7
        ;LCALL   TECLAF2
NEXT7:  SETB    LINB
        
        CLR     LINC			;seleciona a linha C
        JB      COL1,NEXT8
        MOV	A,#1
        LCALL   TECLA
NEXT8:  JB      COL2,NEXT9
        MOV	A,#2
        LCALL   TECLA
NEXT9:  JB      COL3,NEXT10
        MOV	A,#3
        LCALL   TECLA
NEXT10: JB      COL4,NEXT11
        ;LCALL   TECLAF1
NEXT11: SETB    LINC

        CLR     LIND			;seleciona a linha D
        JB      COL1,NEXT12
        MOV	A,#0
        LCALL   TECLA
NEXT12: JB      COL2,NEXT13
        ;LCALL   TECLAP
NEXT13: JB      COL3,NEXT14
	MOV	A,#0FFH		;
        LCALL   TECLAC
NEXT14: JB      COL4,NEXT15
        LCALL   TECLAE
NEXT15: SETB    LIND

	INC	R7
	CJNE	R7,#250,PINICIO
	INC	R6
	CJNE	R6,#250,PINICIO
	JMP	START
PINICIO:JMP    	INICIO 

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;Fim controle teclado
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 

TECLA:	CJNE	POSICAO,#6,$+4		;Compara a POSICAO com 6. Se iguau, não escreve nada
	RET
	MOV	NUMERO,A		;Salva numero digitado
	
	MOV	R7,#250			;debouncing de 10ms para evitar rebatimento
VERIF2:	MOV	R6,#20			;
VERIF:	MOV	A,P0			;
	ANL	A,#11110000B		;
	CJNE	A,#0F0H,VAI2		;
	RET				;
VAI2:	DJNZ	R6,VERIF		;
	DJNZ	R7,VERIF2		;

	MOV	A,NUMERO		;Move p/ACC o número digitado anteriormente
	MOV	DPTR,#NS		;Move para o DataPointer o endereço da 1º caracter ASCII em NS
	MOVC	A,@A+DPTR		;Move p/ACC o caracter ASCII relativo ao número digitado
	LCALL	WRITE			;Escreve caracter numérico no display
	
	MOV  	A,POSICAO		;Move p/ACC a posição do número no display
	ADD	A,#N1			;Soma com 20 para endereçar a posição das senhas
	MOV	R0,A			;Move p/R0 o valor de ACC para endereço indireto @
	MOV	@R0,NUMERO		;Recupera numero digitado nas posições N
	
	INC	POSICAO			;incrementa Nº da posição do cursor no display
	
VOLTA:	MOV	A,P0			;Espera liberar qualquer tecla
	ANL	A,#11110000B		;Faz uma máscara entre A e 11110000B
	CJNE	A,#0F0H,VOLTA
	RET
	
TECLAF3:				;TECLA F3
        RET
        
TECLAF2:				;TECLA F2
        RET
        
TECLAF1:				;TECLA F1
        RET
        
TECLAP:					;TECLA PONTO
        RET
        
;Sub-rotina da tecla C para apagar um caracter do display        
TECLAC: CJNE	POSICAO,#0,CONT		;se a posição do numero ja for zero não apaga nada
	RET
CONT:	DEC	POSICAO			;decrementa posição
	MOV     A,#10H			;comando p/mover o cursor para esquerda
        LCALL   COMAND
        MOV     A,#' '			;escreve ' ' para apagar numero digitado
        LCALL   WRITE
        MOV     A,#10H			;comando p/mover o cursor para esquerda
        LCALL   COMAND
        JNB     COL3,$			;espera tecla C ser liberada
	RET
        
TECLAE: CJNE	POSICAO,#6,RETOR	;se a posição do número ja for 6 retorna
	MOV	R3,#0			;move para R3 o valor 0
	MOV	DPTR,#SENHA		;move para o DataPointer o endereço da senha gravada na memória de código
NEXTN:	MOV	A,R3			;move p/ACC o valor de R3
	MOVC	A,@A+DPTR		;Move p/ACC o dado endereçado indiretamente por A + DPTR
	MOV	R4,A			;salva em R4 o valor do digito salvo encontrado
	
	MOV  	A,R3			;Move p/A a posição do Número em N
	ADD	A,#N1			;Soma com 20 para endereçar a posição das senhas
	MOV	R0,A			;Move para R0 a posiçâo da senha			
	MOV	NUMERO,@R0		;Pega numero digitado nas posições N
	MOV 	A,R4			;move p/ACC o valor do digito
	CJNE	A,NUMERO,ERRADA		;compara o numero da senha digitada com a gravada
        CJNE	R3,#5,INCREM		;próximo numero
        
        MOV     A,#01H          	;senha correta
        LCALL   COMAND			;comando para apagar display
        MOV	A,#MSG4			;escreve 'ACESSO  LIBERADO'
	LCALL	MENSAGEM 
        SETB	SOLEN			;liga solenóide
        JNB	SENSOR,$		;espera porta abrir

	;MOV	A,#1			;espera 1s
        ;LCALL 	WAIT_S

        JB	SENSOR,$		;espera porta fechar
        ;MOV	A,#1			;espera 1s
        ;LCALL 	WAIT_S
        ;JB	SENSOR,$-5		;se porta estiver aberta ainda verifica novamente
        CLR	SOLEN			;desliga solenoide
        DEC	SP			;decrementa 2X o StackPointer pois não será utilizada a instrução RET
        DEC	SP
        JMP	START			;retorna ao inicio do processo
        
INCREM:	INC	R3			;Incrementa a posição do número em N
	JMP	NEXTN			;verifica próximo numero
	
ERRADA:	MOV     A,#01H          	;senha errada
        LCALL    COMAND			;comando para apagar display
	MOV	A,#MSG3			;escreve 'ACESSO NEGADO'
	LCALL	MENSAGEM
	MOV	A,#1			;espera 1s
        LCALL 	WAIT_S
        
        DEC	SP			;decrementa 2X o StackPointer pois não será utilizada a instrução RET
	DEC	SP
	JMP	PROCES			;volta ao processo para redigitar a senha
        
RETOR:  RET
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;Sub-rotina de Inicialização do display LCD
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

LCD_INIT:
	MOV	A,#20
        LCALL	WAIT_MS			;Wait 20ms for LCD to power up
        CLR     RS      	        ;with RS = 0
        MOV     P2,#30H         	;Write D7-4 = 3 hex
        SETB    EN              	;
        CLR     EN              	;Send enable
        MOV	A,#5
        LCALL   WAIT_MS			;Wait 5ms
        SETB    EN			;
        CLR     EN			;Send enable
	LCALL	WAIT_200US		;Wait 200us
        SETB    EN			;
        CLR     EN			;Send enable
	LCALL	WAIT_200US		;Wait 200us
        MOV     P2,#20H			;Write D7-4 = 3 hex
        SETB    EN			;enable four-bit mode
        CLR     EN			;Send enable
        MOV	A,#5
        LCALL   WAIT_MS			;Wait 5ms
        
        MOV     A,#28H			;comand 28 hex (4-Bits, 2-lines)
        LCALL    COMAND
        MOV     A,#08H			;comand 08 hex (don't shift display, hide cursor)
        LCALL    COMAND
        MOV     A,#01H			;comand 01 hex (clear and home display)
        LCALL    COMAND
        MOV     A,#06H			;comand 06 hex (move cursor right)
        LCALL    COMAND
        MOV     A,#0CH			;comand 0C hex (turn on display)
        LCALL    COMAND
        RET				;Display is ready to accept data.

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;Fim inicialização display LCD
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *        

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;Sub-rotina de escrita de comando no display
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *        
COMAND: CLR     EN
        CLR     RS
        MOV	C,0E7H
        MOV	D7,C
        MOV	C,0E6H
        MOV	D6,C
        MOV	C,0E5H
        MOV	D5,C
        MOV	C,0E4H
        MOV	D4,C
        SETB    EN
        CLR     EN
        PUSH	ACC			;Salva ACC
        MOV	A,#5
        LCALL   WAIT_MS
        POP	ACC			;Recupera ACC
        MOV	C,0E3H
        MOV	D7,C
        MOV	C,0E2H
        MOV	D6,C
        MOV	C,0E1H
        MOV	D5,C
        MOV	C,0E0H
        MOV	D4,C
        SETB    EN
        CLR     EN
        MOV	A,#5
        LCALL   WAIT_MS       
        RET				;Fim da sub-rotina
        
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;Sub-rotina de escrita de caracter no display
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
WRITE:  CLR     EN
        SETB    RS
        MOV	C,0E7H
        MOV	D7,C
        MOV	C,0E6H
        MOV	D6,C
        MOV	C,0E5H
        MOV	D5,C
        MOV	C,0E4H
        MOV	D4,C
        SETB    EN
        CLR     EN
	LCALL	WAIT_200US    		;Wait 200us
        MOV	C,0E3H
        MOV	D7,C
        MOV	C,0E2H
        MOV	D6,C
        MOV	C,0E1H
        MOV	D5,C
        MOV	C,0E0H
        MOV	D4,C
        SETB    EN
        CLR     EN
	LCALL	WAIT_200US    		;Wait 200us      
        RET				;Fim da sub-rotina

MENSAGEM:				;Sub-rotina p/escrever a mensagem selecionada
	MOV     R5,#0
     	MOV     DPL,A
LOOP: 	MOV     A,R5
     	MOVC 	A,@A+DPTR
     	CJNE 	A,#0,NEXT
     	SJMP 	EXIT
NEXT: 	LCALL   WRITE
	MOV	POSICAO,#0		;Limpa posição do Número no display
     	INC     R5
        JMP     LOOP
EXIT:	RET

WAIT_200US:				;sub-rotina de espera de 200us
	MOV	R7,#100			;move o valor 100 para R7
	DJNZ	R7,$			;decrementa até R7 = 0, obs.: DJNZ demora 2 ciclos, por o valor 100 e não 200
	RET
	
;Sub-rotina de espera na unidade de milisegundo
WAIT_MS:PUSH	ACC			;Salva ACC
	RL	A			;Multiplica por 2
	MOV     R7,A			;Move o valor 10 para R7
	MOV     R6,#250			;Move 250 para R6
        DJNZ    R6,$			;Decrementa até R6 = 0
        DJNZ    R7,$-4			;Decrementa R7 e recarrega R6 se diferente de zero
        POP	ACC			;Recupera ACC
        RET
        
;Sub-rotina de espera na unidade de segundo        
WAIT_S:	MOV	R7,A			;move p/R7 o valor de A
	MOV	R6,#8			;move p/R6 o valor 8
	MOV	R5,#250			;move p/R5 o valor 250
	MOV	R4,#250			;move p/R4 o valor 250
	DJNZ    R4,$			;Decrementa até R6 = 0
        DJNZ    R5,$-4        		;Decrementa R5 e recarrega R4 se diferente de zero
        DJNZ	R6,$-6			;Decrementa R6 e recarrega R5 se diferente de zero
        DJNZ	R7,$-8			;Decrementa R7 e recarrega R6 se diferente de zero
        RET		
        
        END