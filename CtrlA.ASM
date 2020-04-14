; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *									*
; * Copyright (c) GLuisF Automation & TI. Todos direitos reservados.	*
; * 									*
; * Nome Modulo: 	CtrlA.ASM					*
; * Microcontrolador:	AT89S8252-24PC					*
; * Cristal:		11.0592MHz					*
; * 									*
; * Descricao: 	Firmware do controle de acesso e seguranca		*
; * 									*
; * Proteus 7.8 SP2 	Tab = 8						*
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;$NOMOD51
;$INCLUDE (89S8252.MCU)			;Inclue definicões do uC

DEBUG	MACRO				;Macro para debugar sem delays
;RET
ENDM

;DPL	DATA	DP0L
WMCON	DATA	096H			; watchdog and memory control register
EEMEN	EQU	00001000B		; EEPROM access enable bit
EEMWE	EQU	00010000B		; EEPROM write enable bit
;WDTRST	EQU 	00000010B 		; EEPROM RDY/BSY bit
ADDRESS	EQU	0B
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

RS	EQU	P2.1			;pino 4 display
RW	EQU	P2.2			;pino 5
EN	EQU	P2.3			;pino 6
D4	EQU	P2.4			;pino 12
D5	EQU	P2.5			;pino 13
D6	EQU	P2.6			;pino 14
D7	EQU	P2.7			;pino 15

LINA	EQU	P0.0			;linhas do teclado
LINB	EQU	P0.1
LINC	EQU	P0.2
LIND	EQU	P0.3
COL1	EQU	P0.4			;colunas do teclado
COL2	EQU	P0.5
COL3	EQU	P0.6
COL4	EQU	P0.7

SOLEN	EQU	P3.4			;solenoide da porta
SENSOR	EQU	P3.5			;sensor fim-de-curso
BUZZER	EQU	P3.6
RX	EQU	P3.0
TX	EQU	P3.1

LIN1	EQU	080H			;seleciona linha 1 do display
LIN2	EQU	0C0H			;seleciona linha 2 do display

N1	DATA	20H			;byte 1 da senha digitada
N2	DATA	21H			;byte 2 da senha digitada
N3	DATA	22H			;byte 3 da senha digitada
N4	DATA	23H			;byte 4 da senha digitada
N5	DATA	24H			;byte 5 da senha digitada
N6	DATA	25H			;byte 6 da senha digitada

NUMERO	DATA	26H			;local onde o numero digitado é salvo
POSICAO	DATA	27H			;local onde a posicao do cursor no display é salvo
TRY	DATA	28H			;local onde o numero de tentativas é salvo

	ORG	RESET			;endereco apos o reset
	JMP	MAIN			;pula para MAIN

	;ORG	SINT
	;RETI

;mensagens gravadas na memoria de codigo do microcontrolador
MSGB:	DB	'ACESSO BLOQUEADO'
MSG0:	DB	'    PASSE O', 0
MSG1:	DB	'CARTAO', 0
MSG2:	DB	' DIGITE A SENHA', 0
MSG3:	DB	' ACESSO NEGADO', 0
MSG4:	DB	'ACESSO LIBERADO', 0
NS:	DB	'0123456789'		;caracteres numéricos
SENHA:	DB	0, 1, 7, 7, 5, 8	;senha salva na EEPROM

MAIN:	CLR	RW			;Display no modo de escrita
	CLR	SOLEN			;desliga solenoide
	CLR	BUZZER			;desliga buzzer	
	LCALL	LCD_INIT		;Inicializa display 
	LCALL	SOM
	MOV	TRY, #3			;Adiciona 3 tentativas de erro	
START:	MOV	R7, TRY
	CJNE	R7, #0, OKS		;Compara tentativa com 0 se for maior continua
	MOV	A, #01H			;Limpa display e move cursor para linha 1
	LCALL	COMAND
	MOV	DPTR, #MSGB		;Escreve 'ACESSO BLOQUEADO'
	LCALL	MSG
	SJMP	$			;Bloqueia acesso para sempre		
OKS:	MOV	A, #01H			;Limpa display e move cursor para linha 1
	LCALL	COMAND
	MOV	DPTR, #MSG0		;Escreve '    PASSE O'
	LCALL	MSG
	MOV	A, #LIN2+5		;Seleciona a linha 2 posicao 5
	LCALL	COMAND
	MOV	DPTR, #MSG1		;Escreve 'CARTAO'
	LCALL	MSG
	MOV	A, #100			;Espera 100ms
	LCALL	WAITMS
	JNB	RX, $			;espera leitor ler
	LCALL	SOM
	MOV	A, #100			;Espera 100ms
	LCALL	WAITMS
	LCALL	WAITMS

PROCES:	MOV	A, #01H			;Limpa display e move cursor para linha 1
	LCALL	COMAND

	MOV	DPTR, #MSG2		;Escreve 'DIGITE A SENHA'
	LCALL	MSG

	MOV	A, #LIN2+5		;Seleciona a linha 2 posicao 5
	LCALL	COMAND

	MOV	P0, #0FFH		;Reseta P0
	MOV	POSICAO, #0		;Limpa posicao do Numero no display
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;Controle matriz de teclado
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
INICIO:	CLR	LINA			;seleciona a linha A
	JB	COL1, NEXT0
	MOV	A, #7
	LCALL	TECLA
NEXT0:	JB	COL2, NEXT1
	MOV	A, #8
	LCALL	TECLA
NEXT1:	JB	COL3, NEXT2
	MOV	A, #9
	LCALL	TECLA
NEXT2:	JB	COL4, NEXT3
	;LCALL	TECLAF3
NEXT3:	SETB	LINA
	CLR	LINB			;seleciona a linha B
	JB	COL1, NEXT4
	MOV	A, #4
	LCALL	TECLA
NEXT4:	JB	COL2, NEXT5
	MOV	A, #5
	LCALL	TECLA
NEXT5:	JB	COL3, NEXT6
	MOV	A, #6
	LCALL	TECLA
NEXT6:	JB	COL4, NEXT7
	LCALL	TECLAF2
NEXT7:	SETB	LINB
	CLR	LINC			;seleciona a linha C
	JB	COL1, NEXT8
	MOV	A, #1
	LCALL	TECLA
NEXT8:	JB	COL2, NEXT9
	MOV	A, #2
	LCALL	TECLA
NEXT9:	JB	COL3, NEXT10
	MOV	A, #3
	LCALL	TECLA
NEXT10:	JB	COL4, NEXT11
	LCALL	TECLAF1
NEXT11:	SETB	LINC
	CLR	LIND			;seleciona a linha D
	JB	COL1, NEXT12
	MOV	A, #0
	LCALL	TECLA
NEXT12:	JB	COL2, NEXT13
	;LCALL	TECLAP
NEXT13:	JB	COL3, NEXT14
	MOV	A, #0FFH
	LCALL	TECLAC
NEXT14:	JB	COL4, NEXT15
	LCALL	TECLAE
NEXT15:	SETB	LIND

;	INC	R7
;	CJNE	R7,#250,PINICIO
;	INC	R6
;	CJNE	R6,#250,PINICIO
;		LCALL	SOM
;	MOV	A,#200
;	LCALL	WAITMS
;		LCALL	SOM		
;	JMP	START

PINICIO:	JMP	INICIO

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;Fim controle teclado
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 

TECLA:	MOV	R1,POSICAO
	CJNE	R1, #6, $+4		;Compara a POSICAO com 6. Se igual, nao escreve nada
	RET
	MOV	NUMERO, A		;Salva numero digitado
	CALL	DEBOUN			;debouncing de 10ms para evitar rebatimento

	MOV	A, NUMERO		;Move p/ACC o numero digitado anteriormente
	MOV	DPTR, #NS		;Move para o DataPointer o endereco do caracter ASCII em NS
	MOVC	A, @A+DPTR		;Move p/ACC o caracter ASCII relativo ao numero digitado
	LCALL	WRITE			;Escreve caracter numérico no display

	MOV	A, POSICAO		;Move p/ACC a posicao do numero no display
	ADD	A, #N1			;Soma com 20 para enderecar a posicao das senhas
	MOV	R0, A			;Move p/R0 o valor de ACC para endereco indireto @
	MOV	@R0, NUMERO		;Salva numero digitado nas posicões N

	INC	POSICAO			;incrementa numero da posicao do cursor no display

VOLTA:	MOV	A, P0			;Espera liberar qualquer tecla
	ANL	A, #11110000B		;Faz uma mascara entre A e 11110000B
	CJNE	A, #0F0H, VOLTA
FIM:	RET

TECLAF3:				;TECLA F3
	RET

TECLAF2:				;TECLA F2
	MOV	DPTR, #ADDRESS		; address to write
	MOV	A, #'J'			; data to write
	LCALL	WRITEX			;Escreve na EEPROM
	RET

TECLAF1:				;TECLA F1
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	MOV	A, #LIN2+5		;Seleciona a linha 2 posicao 5
	LCALL	COMAND
	MOV	DPTR, #ADDRESS		;Move para DPTR o valor do endereco da memoria eeprom
	LCALL	MSGEXT			; escreve no display o valor lido na memoria eeprom
	LCALL	SOM
	RET
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *	
TECLAP:					;TECLA PONTO
	RET

;Sub-rotina da tecla C para apagar um caracter do display		
TECLAC:	MOV	R1,POSICAO
	CJNE	R1, #0, CONT		;se a posicao do numero ja for zero nao apaga nada
	RET
CONT:	DEC	POSICAO			;decrementa posicao

	MOV	A, POSICAO		;Move p/ACC a posicao do numero no display
	ADD	A, #N1			;Soma com 20 para enderecar a posicao das senhas
	MOV	R0, A			;Move p/R0 o valor de ACC para endereco indireto @
	MOV	@R0, #0			;Apaga numero digitado nas posicões N
	
	MOV	A, #10H			;comando p/mover o cursor para esquerda
	LCALL	COMAND
	MOV	A, #' '			;escreve ' ' para apagar numero digitado
	LCALL	WRITE
	MOV	A, #10H			;comando p/mover o cursor para esquerda
	LCALL	COMAND
	JNB	COL3, $			;espera tecla C ser liberada
	RET

TECLAE:	MOV	R1,POSICAO
	CJNE	R1, #6, RETOR		;se a posicao do numero ja for 6 retorna
	MOV	R3, #0			;move para R3 o valor 0
	MOV	DPTR, #SENHA		;move para o DataPointer o endereco da senha gravada na memoria de codigo
NEXTN:	MOV	A, R3			;move p/ACC o valor de R3
	MOVC	A, @A+DPTR		;Move p/ACC o dado enderecado indiretamente por A + DPTR
	MOV	R4, A			;salva em R4 o valor do digito salvo encontrado

	MOV	A, R3			;Move p/A a posicao do Numero em N
	ADD	A, #N1			;Soma com 20 para enderecar a posicao das senhas
	MOV	R0, A			;Move para R0 a posicâo da senha			
	MOV	NUMERO, @R0		;Pega numero digitado nas posicões N
	MOV	A, R4			;move p/ACC o valor do digito
	CJNE	A, NUMERO, ERRADA	;compara o numero da senha digitada com a gravada
	CJNE	R3, #5, INCREM		;proximo numero

	MOV	A, #01H			;senha correta
	LCALL	COMAND			;comando para apagar display
	MOV	DPTR, #MSG4		;escreve 'ACESSO	LIBERADO'
	LCALL	MSG
	LCALL	SOM
	MOV	TRY, #3			;Adiciona 3 tentativas de erro			

	ACALL	ENVIA

	SETB	SOLEN			;liga solenoide
	JNB	SENSOR, $		;espera porta abrir
	MOV	A, #1
	ACALL	WAIT_S
	CLR	SOLEN			;desliga solenoide

	MOV	A, #125
	LCALL	WAITMS
	LCALL	WAITMS			;espera 250ms

	JB	SENSOR, $		;espera porta fechar
	MOV	A, #125			;espera 125ms
	LCALL	WAITMS
	JB	SENSOR, $-5		;se porta estiver aberta ainda verifica novamente

	LCALL	SOM

	;CLR	SOLEN			;desliga solenoide
	DEC	SP			;decrementa 2X o StackPointer pois nao sera utilizada a instrucao RET
	DEC	SP
	JMP	START			;retorna ao inicio do processo

INCREM:	INC	R3			;Incrementa a posicao do numero em N
	JMP	NEXTN			;verifica proximo numero

ERRADA:	MOV	A, #01H			;senha errada
	LCALL	COMAND			;comando para apagar display
	MOV	DPTR, #MSG3		;escreve 'ACESSO NEGADO'
	LCALL	MSG
	LCALL	SOM
	MOV	A, #125
	LCALL	WAITMS			;espera 125ms
	LCALL	SOM
	MOV	A, #125			;127ms é o maximo possível			
	LCALL	WAITMS
	LCALL	WAITMS
	LCALL	WAITMS
	LCALL	WAITMS			;espera 500ms
	DEC	TRY			;decrementa tentativa	
	DEC	SP			;decrementa 2X o StackPointer pois nao sera utilizada a instrucao RET
	DEC	SP
	JMP	START			;volta ao processo para redigitar a senha

RETOR:	RET

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;Sub-rotina de Inicializacao do display LCD
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

LCD_INIT:
	DEBUG
	MOV	A, #20
	LCALL	WAITMS			;Wait 20ms for LCD to power up
	CLR	RS			;with RS = 0
	MOV	P2, #30H		;Write D7-4 = 3 hex
	SETB	EN			;
	CLR	EN			;Send enable
	MOV	A, #5
	LCALL	WAITMS			;Wait 5ms
	SETB	EN			;
	CLR	EN			;Send enable
	LCALL	WAIT200			;Wait 200us
	SETB	EN			;
	CLR	EN			;Send enable
	LCALL	WAIT200			;Wait 200us
	MOV	P2, #20H		;Write D7-4 = 3 hex
	SETB	EN			;enable four-bit mode
	CLR	EN			;Send enable
	MOV	A, #5
	LCALL	WAITMS			;Wait 5ms

	MOV	A, #28H			;comand 28 hex (4-Bits, 2-lines)
	LCALL	COMAND
	MOV	A, #08H			;comand 08 hex (dont shift display, hide cursor)
	LCALL	COMAND
	MOV	A, #01H			;comand 01 hex (clear and home display)
	LCALL	COMAND
	MOV	A, #06H			;comand 06 hex (move cursor right)
	LCALL	COMAND
	MOV	A, #0CH			;comand 0C hex (turn on display)
	LCALL	COMAND
	RET				;Display is ready to accept data.

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;Fim inicializacao display LCD
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *		

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;Sub-rotina de escrita de comando no display
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *		
COMAND:	DEBUG
	CLR	EN
	CLR	RS
	MOV	C, 0E7H
	MOV	D7, C
	MOV	C, 0E6H
	MOV	D6, C
	MOV	C, 0E5H
	MOV	D5, C
	MOV	C, 0E4H
	MOV	D4, C
	SETB	EN
	CLR	EN
	PUSH	ACC			;Salva ACC
	MOV	A, #5
	LCALL	WAITMS			;Espera 5ms
	POP	ACC			;Recupera ACC
	MOV	C, 0E3H
	MOV	D7, C
	MOV	C, 0E2H
	MOV	D6, C
	MOV	C, 0E1H
	MOV	D5, C
	MOV	C, 0E0H
	MOV	D4, C
	SETB	EN
	CLR	EN
	MOV	A, #5
	LCALL	WAITMS
	RET				;Fim da sub-rotina

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;Sub-rotina de escrita de caracter no display
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
WRITE:	DEBUG
	CLR	EN
	SETB	RS
	MOV	C, 0E7H
	MOV	D7, C
	MOV	C, 0E6H
	MOV	D6, C
	MOV	C, 0E5H
	MOV	D5, C
	MOV	C, 0E4H
	MOV	D4, C
	SETB	EN
	CLR	EN
	LCALL	WAIT200			;Wait 200us
	MOV	C, 0E3H
	MOV	D7, C
	MOV	C, 0E2H
	MOV	D6, C
	MOV	C, 0E1H
	MOV	D5, C
	MOV	C, 0E0H
	MOV	D4, C
	SETB	EN
	CLR	EN
	LCALL	WAIT200			;Wait 200us 	
	RET				;Fim da sub-rotina

MSG:	DEBUG
	MOV	R5, #0			;Sub-rotina p/escrever a mensagem selecionada
LOOP:	MOV	A, R5
	MOVC	A, @A+DPTR
	CJNE	A, #0, NEXT
	SJMP	EXIT
NEXT:	LCALL	WRITE
	INC	R5
	JMP	LOOP
EXIT:	RET

SOM:	DEBUG				;sub-rotina de espera de 200us
	MOV	R5, #200
SOM2:	CPL	BUZZER
	MOV	A, #1
	LCALL	WAITMS
	DJNZ	R5, SOM2
	RET

WAIT200:				;sub-rotina de espera de 200us
	DEBUG
	MOV	R7, #100		;move o valor 100 para R7
	DJNZ	R7, $			;decrementa até R7 = 0, obs.: DJNZ demora 2 ciclos, por o valor 100 e nao 200
	RET

;Sub-rotina de espera na unidade de milisegundo de 0 a 127ms
WAITMS:	DEBUG			
	;PUSH	ACC			;Salva ACC
	RL	A			;Multiplica por 2
	MOV	R7, A			;Move o valor de A para R7
	MOV	R6, #250		;Move 250 para R6
	DJNZ	R6, $			;Decrementa até R6 = 0
	DJNZ	R7, $-4			;Decrementa R7 e recarrega R6 se diferente de zero
	;POP	ACC			;Recupera ACC
	RET

;Sub-rotina de espera na unidade de segundo		
WAIT_S:	DEBUG
	MOV	R7, A			;move p/R7 o valor de A
	MOV	R6, #8			;move p/R6 o valor 8
	MOV	R5, #250		;move p/R5 o valor 250
	MOV	R4, #250		;move p/R4 o valor 250
	DJNZ	R4, $			;Decrementa até R6 = 0
	DJNZ	R5, $-4			;Decrementa R5 e recarrega R4 se diferente de zero
	DJNZ	R6, $-8			;Decrementa R6 e recarrega R5 se diferente de zero
	DJNZ	R7, $-12		;Decrementa R7 e recarrega R6 se diferente de zero
	RET

DEBOUN: DEBUG
	MOV	R7, #250		;debouncing de 10ms para evitar rebatimento
VERIF2:	MOV	R6, #20			;
VERIF:	MOV	A, P0			;
	ANL	A, #11110000B		;
	CJNE	A, #0F0H, VAI2		;
	JMP	FIM			;
VAI2:	DJNZ	R6, VERIF		;
	DJNZ	R7, VERIF2		;
	RET

ENVIA:	MOV	TMOD, #00100000B	;Timer 1 no modo 2 (8 bits com recarga automatica)
	MOV	PCON, #00000000B	;Sem dobrar a frequencia
	MOV	TH1, #0FDH	;	Recarga do TIMER 1 para 9600 bauds
	SETB	TR1			;Liga TIMER 1
	MOV	SCON, #01000000B	;Serial no modo 1 (Assincrona, 8 bits, Timer1
	MOV	A, #127
	ACALL	WAITMS
	MOV	A, #'A'
	MOV	SBUF, A			;Envia para serial o valor de A
	JNB	TI, $			;espera transmissao completar
	CLR	TI
	CLR	TR1
	CLR	TR1
	RET

WRITEX:	ORL	WMCON, #EEMEN		;enable EEPROM accesses
	ORL	WMCON, #EEMWE		;enable EEPROM writes
	MOVX	@DPTR, A		;write EEPROM
	MOV	A, #10
	LCALL	WAITMS			; espera 10ms
	;movx 	a, @DPTR 		;read EEPROM
	;cjne 	a, #DATA, ERROR		;jump if data compare fails
	XRL	WMCON, #EEMWE		;disable EEPROM writes
	XRL	WMCON, #EEMEN		;disable EEPROM accesses
	RET

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
MSGEXT:					;Sub-rotina p/escrever a mensagem selecionada localizada na memoria eeprom
	ORL	WMCON, #EEMEN		;enable EEPROM accesses 
LOOPX:	MOVX	A, @DPTR		;Move para A o valor que o DPTR aponta na memoria eeprom
	CJNE	A, #0, NEXTX		;Compara A com 0 e pula para NEXTX se nao for igual
	SJMP	EXITX			;Pula para EXITX
NEXTX:	LCALL	WRITE			;Escreve no display o caracter em ACC
	MOV	POSICAO, #0		;Limpa posicao do Numero no display
	INC	DPTR			;Incrementa a parte baixa do DPTR (=INC DPL)
	JMP	LOOPX			;Pula para LOOPX
EXITX:	XRL	WMCON, #EEMEN		;disable EEPROM accesses
	RET

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
	END
