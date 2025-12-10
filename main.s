RCC_APB1ENR EQU 0x40021000+0x1C ;RCC_APB1ENR endereco do registrador

;Mascaras de configuracao
hab_gpioc_gpiob_gpioa_afio EQU 0x1D       ;afion_0+iopaen_2+iopben_3=0x0D
;Registros ADC
ADC1_BASE 	EQU 0x40012400
ADC1_SR 	EQU ADC1_BASE+0x0000
ADC1_DR		EQU ADC1_BASE+0x004C
ADC1_CR2	EQU ADC1_BASE+0x0008
ADC1_SMPR2 	EQU ADC1_BASE+0x0010
ADC1_SQR3 	EQU ADC1_BASE+0x0034
;Registros de configuracao da GPIOA
RCC_APB2ENR EQU 0x40021018  
GPIOA_CRL 	EQU 0x40010800 
GPIOA_CRH 	EQU 0x40010804 
GPIOA_IDR 	EQU 0x40010808 
GPIOA_ODR 	EQU 0x4001080C 
GPIOA_BSRR  EQU 0x40010810
GPIOA_BRR   EQU 0x40010814
AFIO_MAPR 	EQU 0x40010004
GPIOA_HAB   EQU 0x04 

;Registros da GPIOB (0x40010C00 - 0x40010FFF)
GPIOB_CRL   EQU 0x40010C00
GPIOB_CRH   EQU GPIOB_CRL+0x04
GPIOB_IDR   EQU GPIOB_CRL+0x08
GPIOB_ODR   EQU GPIOB_CRL+0x0C
GPIOB_BSRR  EQU GPIOB_CRL+0x10
GPIOB_BRR   EQU GPIOB_CRL+0x14

;Registros da GPIOC (0x40011000 - 0x400113FF)
GPIOC_CRH   EQU 0x40011000+0x04
GPIOC_IDR   EQU 0x40011000+0x08

;Registros do timer 3
TIM3_BASE   EQU 0x40000400
TIM3_PSC    EQU TIM3_BASE+0x28
TIM3_CCR3   EQU TIM3_BASE+0x3C
TIM3_CCER   EQU TIM3_BASE+0x20
TIM3_CCMR2  EQU TIM3_BASE+0x1C
TIM3_ARR    EQU TIM3_BASE+0x2C
TIM3_CR1    EQU TIM3_BASE+0x00

;Mascaras de leds
LED1		EQU 0x0001
LED2		EQU 0x0002
LED3		EQU 0x0004
LED4		EQU 0x8000
LED5		EQU 0x0100
LED6		EQU 0x0040
LED7		EQU 0x0020
LED8		EQU 0x0800
APAGA   	EQU 0x0000

;outros
AFIO_HAB    EQU 0x01
JTAG_GPIO   EQU 0x02000000
GPIO_SAIDA  EQU 0x33333333

;Controlde do LCD
LCD_EN      EQU 0x1000     
LCD_RS      EQU 0x8000     

VALOR_ARR 	EQU 999

			AREA l , CODE, READONLY
leds   		DCD LED8, LED7, LED6, LED5, LED4, LED3, LED2, LED1

			AREA t_p_n, DATA, READONLY
teclas 		DCD  5, 13, 6, 14, 7, 8, 15, 9, 16, 10, 17, 11, 12,0

; Tabela de lookup para o PSC com ARR de 99 para frequencias C, C#, D, D#, E, F, F#, G, G#, A, A#, B
			AREA O_1, DATA, READONLY
notas_1 	DCD 0, 274 ,259 ,244 ,230 ,217 ,205 ,194 ,183 ,172 ,163 ,153 ,145 ,0	
	
			AREA O_2, DATA, READONLY
notas_2 	DCD 0, 137 ,129 ,122 ,115 ,108 ,102 ,96 ,91 ,86 ,81 ,76 ,72 ,0	
	
			AREA melodia, DATA, READONLY
notasM 		DCD 0, 274, 0, 274, 0, 183, 0, 183, 0, 163, 0, 163, 0, 183, 183, 0, 0, 205, 0, 205, 0, 217, 0, 217, 0, 244, 0, 244, 0, 274, 274, 0, 0, 183, 0, 183, 0, 205, 0, 205, 0, 217, 0, 217, 0, 244, 244, 0, 0, 183, 0, 183, 0, 205, 0, 205, 0, 217, 0, 217, 0, 217, 217, 244, 244

	EXPORT __main
	AREA projeto, CODE, READONLY
__main
	
		BL sub_habilita_GPIO
		BL sub_jtag2gpio
		BL sub_gpioa_saida_pp
		BL configura_timer3
		
		MOV R4, #0x01   ;apaga o LCD
		BL lcd_command  ;manda o comando para o LCD
		BL lcd_init
		MOV R10, #1
		MOV R11, #0
		BL printa_lcd
		
main_loop		
		BL tecla_id
		
		CMP R8, R7
		MOV R7, R8
		BEQ main_loop
		
		
        CMP R8, #1     ; Testa se SW1 foi pressionado
        BEQ.W seleciona_oitava1
        CMP R8, #2     ; Testa se SW2 foi pressionado
        BEQ.W seleciona_oitava2
		CMP R8, #3  ; Testa se o SW3 foi pressionado
		BEQ.W aumenta_timbre
		CMP R8, #4  ; Testa se o SW4 foi pressionado
		BEQ.W diminui_timbre
		CMP R8, #12  ; Testa se o SW4 foi pressionado
		BEQ call_melody
		
		
		BL printa_duty
		
		MOV R4, R8
		BL toca_nota
		
		B main_loop


finish	B finish   
; Subrotinas para cada nota
; Subrotinas
printa_lcd
		PUSH {LR}
		PUSH {R0}
		PUSH {R1}

		MOV R4, #0x01   ;apaga o LCD
		BL lcd_command  ;manda o comando para o LCD
		
		MOV R4, #'8'   ;apaga o LCD
		BL lcd_data  ;manda o comando para o LCD
		MOV R4, #'v'   ;apaga o LCD
		BL lcd_data  ;manda o comando para o LCD
		MOV R4, #97   ;apaga o LCD
		BL lcd_data  ;manda o comando para o LCD
		MOV R4, #':'   ;apaga o LCD
		BL lcd_data  ;manda o comando para o LCD
		MOV R4, R10
		ADD R4, #'0'
		BL lcd_data  ;manda o comando para o LCD
		
		MOV R4, #' '   ;apaga o LCD
		BL lcd_data  ;manda o comando para o LCD
		
		MOV R4, #'T'   ;apaga o LCD
		BL lcd_data  ;manda o comando para o LCD
		MOV R4, #'i'   ;apaga o LCD
		BL lcd_data  ;manda o comando para o LCD
		MOV R4, #'m'   ;apaga o LCD
		BL lcd_data  ;manda o comando para o LCD
		MOV R4, #'b'   ;apaga o LCD
		BL lcd_data  ;manda o comando para o LCD
		MOV R4, #'r'   ;apaga o LCD
		BL lcd_data  ;manda o comando para o LCD
		MOV R4, #'e'   ;apaga o LCD
		BL lcd_data  ;manda o comando para o LCD
		MOV R4, #':'   ;apaga o LCD
		BL lcd_data  ;manda o comando para o LCD
		
        BL print_double_digit ; Chama a sub-rotina para exibir dois dígitos
		MOV R4, #'%'   ;apaga o LCD
		BL lcd_data  ;manda o comando para o LCD
		
		POP {R1}
		POP {R0}
		POP {LR}
        BX LR

		;BL print_timbre
print_double_digit
        PUSH {LR}           ; Salva o registrador de link
        PUSH {R1}           ; Salva o registrador de link
        PUSH {R2}           ; Salva o registrador de link
		LDR R0,=TIM3_CCR3   ; Carrega o endereco do registrador CCR3
		LDR R1,[R0]         ; Carrega o valor do CCR3
		MOV R2, #10
		UDIV R1, R1, R2
		UDIV R4, R1, R2
		MOV R3, R4
		ADD R4, #'0'  ; converte para ASCII
		BL lcd_data ; manda para o LCD
		MOV R4, R1
		MLS R4, R3, R2, R1
		ADD R4, #'0'  ; converte para ASCII
		BL lcd_data ; manda para o LCD

		POP {R2}
		POP {R1}
		POP {LR}
        BX LR               ; Retorna da sub-rotina
		
call_melody
		PUSH {LR}
		PUSH {R0}
		PUSH {R1}
		PUSH {R2}
		PUSH {R3}
		PUSH {R5}
		PUSH {R6}
		PUSH {R7}

        LDR R1, =notasM  ; Seleciona tabela completa de notas
        LDR R0, =TIM3_PSC ; Carrega o endereço do registrador PSC
        MOV R3, #1        ; Inicializa o índice para percorrer a tabela

loopM
        CMP R3, #64       ; Verifica se percorreu todas as posições (0 a 13)
        BGE fim_melody    ; Sai do loop se todas as notas foram tocadas

        LDR R6, [R1, R3, LSL #2] ; Carrega o valor da nota na posição atual
        STR R6, [R0]             ; Configura o PSC com o valor correspondente
        
        BL delay_melody                 ; Chama a rotina de atraso (para audibilidade)
        
        ADD R3, R3, #1           ; Incrementa o índice para a próxima posição
        B loopM                  ; Volta para processar a próxima nota

fim_melody
		POP {R7}
		POP {R6}
		POP {R5}
		POP {R3}
		POP {R2}
		POP {R1}
		POP {R0}
		POP {LR}
        BX LR

; aumenta o ciclo de trabalho do PWM em 5%
aumenta_timbre
		PUSH {LR}
		PUSH {R0}
		PUSH {R1}
		LDR R0,=TIM3_CCR3   ; Carrega o endereco do registrador CCR3
		LDR R1,[R0]         ; Carrega o valor do CCR3
		CMP R1, #940         ; Compara o valor do ciclo de trabalho com 95
		ADDLE R1, R1, #50    ; Se o ciclo de trabalho for menor que 95, aumenta o ciclo de trabalho em 5%
		STR R1,[R0]         ; Configura o CCR3
		
		BL printa_lcd
		POP {R1}
		POP {R0}
		POP {LR}    ; restaurando os registradores
		BX LR

; diminui o ciclo de trabalho do PWM em 5%
diminui_timbre
		PUSH {LR}
		PUSH {R0}
		PUSH {R1}
		LDR R0,=TIM3_CCR3   ; Carrega o endereco do registrador CCR3
		LDR R1,[R0]         ; Carrega o valor do CCR3
		CMP R1, #90          ; Compara o valor do ciclo de trabalho com 5
		SUBGE R1, R1, #50    ; Se o ciclo de trabalho for maior que 5, diminui o ciclo de trabalho em 5%
		STR R1,[R0]         ; Configura o CCR3
		
		BL printa_lcd
		POP {R1}
		POP {R0}
		POP {LR}    ; restaurando os registradores
		BX LR

; printa nos leds o valor do ciclo de trabalho
printa_duty
		PUSH {LR}
		PUSH {R0}
		PUSH {R1}
		PUSH {R2}
		PUSH {R3}
		PUSH {R5}
		PUSH {R6}
		PUSH {R7}
		
		LDR R0,=GPIOA_ODR   ; Carrega o endereco do registrador ODR
		LDR R1,=TIM3_CCR3   ; Carrega o endereco do registrador CCR3 do ciclo de trabalho
		LDR R2,[R1]         ; Carrega o valor do CCR3
		LDR R5,=leds        ; Carrega o endereco da tabela de leds
		MOV R3, #0          ; Inicializa o contador
		MOV R7, #0          ; Inicializa o valor dos leds
loop	CMP R2, R3          ; Compara o valor do ciclo de trabalho com o contador
		ADDGT R3, R3, #130   ; Se o contador for menor, soma 100/8 ao contador
		LDR R6, [R5]        ; Carrega o valor do led correspondente
		ADD R5, R5, #4      ; Pula para o proximo led
		ORRGT R7, R7, R6    ; Se o contador for menor, soma o valor do led ao valor total
		BGT loop            ; Se o contador for menor, pula para a proxima

		STR R7, [R0]        ; Configura o ODR
		
		POP {R7}
		POP {R6}
		POP {R5}
		POP {R3}
		POP {R2}
		POP {R1}
		POP {R0}
		POP {LR}
		BX LR
		
seleciona_oitava1
		MOV R10, #1    ; Define oitava como 1
		BL printa_lcd
		B main_loop

seleciona_oitava2
		MOV R10, #2    ; Define oitava como 2
		BL printa_lcd
		B main_loop

toca_nota
		PUSH {LR}
		PUSH {R0}
		PUSH {R1}
		PUSH {R2}
		PUSH {R3}
		PUSH {R5}
		PUSH {R6}
		
		CMP R10, #2    ; Verifica a oitava selecionada
		BEQ usa_notas2
		LDR R1,=notas_1+4  ; Seleciona tabela da segunda oitava
		B seleciona_nota
		
usa_notas2
		LDR R1,=notas_2+4  ; Seleciona tabela da primeira oitava
    
seleciona_nota
		LDR R0,=TIM3_PSC  ; Carrega o endereço do registrador PSC
		LDR R2,=teclas    ; Carrega o endereço da tabela de teclas
		MOV R3, #0        ; Inicializa contador
		MOV R5, #0        ; Inicializa valor da tecla
		
loop_tecla
		LDR R5, [R2, R3, LSL #2] ; Carrega a tecla correspondente
		CMP R5, R4               ; Compara a tecla com a nota
		ADDNE R3, R3, #1         ; Se não for a tecla, soma 1 ao contador
		BNE loop_tecla           ; Continua procurando
		
		LDR R6, [R1, R3, LSL #2] ; Carrega o valor do PSC correspondente
		STR R6, [R0]             ; Configura o PSC
		
		POP {R6}
		POP {R5}
		POP {R3}
		POP {R2}
		POP {R1}
		POP {R0}
		POP {LR}
		BX LR

configura_timer3
		
		PUSH {LR}
		PUSH {R0}
		PUSH {R1}       ; salvando os registradores
		LDR R0,=RCC_APB1ENR
		LDR R1,[R0]
		ORR R1,R1,#0x03
		STR R1,[R0]         ; Habilita o timer 3

		LDR R0,=TIM3_ARR    ; Carrega o endereco do registrador ARR
		LDR R1,=VALOR_ARR   ; Carrega o valor de ARR
		STR R1,[R0]         ; Configura o ARR

		LDR R0,=TIM3_CCMR2  ; Carrega o endereco do registrador CCMR2
		LDR R1,=0x0068      ; PWM mode 1
		STR R1,[R0]         ; Configura o CCMR2

		LDR R0,=TIM3_CCER   ; Carrega o endereco do registrador CCER
		LDR R1,=0x0100      ; Habilita buffer de saida
		STR R1,[R0]         ; Configura o CCER

		LDR R0,=TIM3_CCR3   ; Carrega o endereco do registrador CCR3
		MOV R1,#50			; Duty cycle de 50%
		STR R1,[R0]         ; Configura o CCR3

		LDR R0,=TIM3_CR1    ; Carrega o endereco do registrador CR1
		MOV R1,#0x01        ; Habilita o timer 3
		STR R1,[R0]         ; Configura o CR1

		POP {R1}
		POP {R0}
		POP {LR}	        ; restaurando os registradores
		BX LR

; le a tecla e salva em R8
tecla_id
		LDR R0,=GPIOA_IDR
		LDR R1,=GPIOB_IDR
		LDR R2,=GPIOC_IDR
		LDR R3,[R0]
		LDR R4,[R1]
		LDR R5,[R2]
		MOV R8, #0

		LSL R3, #16
		LSL R4, #16
		LSL R5, #16
		
		;Teste para SW4, bit 15 de GPIOB
		LSLS R4, #1
		ORRCC R8, R8, #4
		BXCC LR

		;Teste para SW3, bit 14 de GPIOB
		LSLS R4, #1
		ORRCC R8, R8, #3
		BXCC LR

		;Teste para SW2, bit 13 de GPIOB
		LSLS R4, #1
		ORRCC R8, R8, #2
		BXCC LR

		;Teste para SW1, bit 12 de GPIOB
		LSLS R4, #1
		ORRCC R8, R8, #1
		BXCC LR

		;Teste para SW12, bit 11 de GPIOB
		LSLS R4, #1
		ORRCC R8, R8, #12
		BXCC LR

		;Teste para SW13, bit 10 de GPIOB
		LSLS R4, #1
		ORRCC R8, R8, #13
		BXCC LR

		;Teste para SW11, bit 9 de GPIOB
		LSLS R4, #1
		ORRCC R8, R8, #11
		BXCC LR

		;Teste para SW10, bit 8 de GPIOB
		LSLS R4, #1
		ORRCC R8, R8, #10
		BXCC LR

		;Teste para SW5, bit 5 de GPIOB
		LSLS R4, #3
		ORRCC R8, R8, #5
		BXCC LR

		;Teste para SW6, bit 4 de GPIOB
		LSLS R4, #1
		ORRCC R8, R8, #6
		BXCC LR

		;Teste para SW7, bit 3 de GPIOB
		LSLS R4, #1
		ORRCC R8, R8, #7
		BXCC LR

		;Teste para SW14, bit 7 de GPIOA
		LSLS R3, #9
		ORRCC R8, R8, #14
		BXCC LR

		;Teste para SW9, bit 4 de GPIOA
		LSLS R3, #3
		ORRCC R8, R8, #9
		BXCC LR

		;Teste para SW8, bit 3 de GPIOA
		LSLS R3, #1
		ORRCC R8, R8, #8
		BXCC LR

		;Teste para SW15, bit 15 de GPIOC
		LSLS R5, #1
		ORRCC R8, R8, #15
		BXCC LR

		;Teste para SW16, bit 14 de GPIOC
		LSLS R5, #1
		ORRCC R8, R8, #16
		BXCC LR

		;Teste para SW17, bit 13 de GPIOC
		LSLS R5, #1
		ORRCC R8, R8, #17
		BXCC LR


;subrotina para habilitar a GPIO
sub_habilita_GPIO     
		
		PUSH {LR}
		PUSH {R0}
		PUSH {R1}		      	; salvando os registradores
		
		LDR R1,=RCC_APB2ENR     ;R1 contem o endereco de APB2ENR.
		ORR R0,R0,#hab_gpioc_gpiob_gpioa_afio    ;R0 contem o valor para habilitar GPIOA, GPIOB e GPIOC.
		STR R0,[R1]             ;Salva o conteudo de R0 em APB2ENR,
								;habilitando a GPIOA.
		
		POP {R1}
		POP {R0}
		POP {LR}        ; restaurando os registradores
		BX LR

;subrotinas com salvamento e restauracao de registradores

;subrotina para habilitar o remapeamento da JTAG
sub_jtag2gpio
		PUSH {LR}
		PUSH {R0}
		PUSH {R1}
		
		LDR R1,=AFIO_MAPR       ;R1 recebe o endereco de AFIO_MAPR.
		LDR R0,=JTAG_GPIO       ;R0 recebe o valor de configuracao.
		STR R0,[R1]             ;Salva o conteudo de R0 em AFIO_MAPR,
		
		POP {R1}
		POP {R0}
		POP {LR}
		BX LR

;subrotina para configurar a GPIOA como saida push-pull
sub_gpioa_saida_pp
		PUSH {LR}
		PUSH {R0}
		PUSH {R1}
		PUSH {R2}
		
		;Configurando GPIOA como saida
		LDR R1,=GPIOA_CRL
		LDR R0,=0x43344333              ;pinos 7:0 como saida push-pull
		STR R0,[R1]
		LDR R1,=GPIOA_CRH
		LDR R0,=0x34433443              ;pinos 13 e 14 como entradas e demais como saida
		STR R0,[R1]

;Configurando a GPIOB como entrada
		LDR R1,=GPIOB_CRL
		LDR R0,=0x4444444B              ;pinos 7:0 como entradas em alta impedencia
		STR R0,[R1]
		LDR R1,=GPIOB_CRH
		LDR R0,=0x44444444              ;pinos 15:8 como entradas em alta impedencia
		STR R0,[R1]


;Configuranado GPIOC
		LDR R1,=GPIOC_CRH
		LDR R0, [R1]
		LDR R2, =0x44400000
		ORR R0, R0, R2
		STR R0, [R1]
		
		POP {R2}
		POP {R1}
		POP {R0}
		POP {LR}
		BX LR
		LTORG
		
lcd_command
		PUSH {LR}
		PUSH {R4}
		PUSH {R5}
		PUSH {R7}
		PUSH {R8}
		PUSH {R10}
		PUSH {R11}
		
		;nibble mais significativo
		AND R5,R4,#0xF0            ;elimina o nible menos significativo
		LSR R5,R5,#4
		AND R7,R5,#0x08            ;separando o bit 7
		LSL R10,R7,#8
		AND R7,R5,#0x04            ;separando o bit 6
		LSL R7,R7,#3
		ORR R10,R10,R7
		AND R7,R5,#0x02            ;separando o bit 5
		LSL R7,R7,#5
		ORR R10,R10,R7
		AND R7,R5,#0x01            ;separando o bit 4
		LSL R7,R7,#8
		ORR R10,R10,R7

		LDR R11,=LCD_RS
		BIC  R10,R10,R11
		BIC R10, R10, #LCD_EN
		LDR R8,=GPIOA_ODR
		STR R10,[R8]                ;EN=0, RS=0
		BL  delay                  ;minimo 40ns
		ORR R10,R10, #LCD_EN         ;EN=1, RS=0, RW=0
		STR R10,[R8]
		BL delay                   ;minimo 230ns
		BIC R10,R10,#LCD_EN
		STR R10,[R8]                ;EN=0, RS=0, RW=0
		BL delay                   ;minimo 10ns

		;nible menos significativos
		AND R5,R4,#0x0F
		AND R7,R5,#0x08            ;separando o bit 7
		LSL R10,R7,#8
		AND R7,R5,#0x04            ;separando o bit 6
		LSL R7,R7,#3
		ORR R10,R10,R7
		AND R7,R5,#0x02            ;separando o bit 5
		LSL R7,R7,#5
		ORR R10,R10,R7
		AND R7,R5,#0x01            ;separando o bit 4
		LSL R7,R7,#8
		ORR R10,R10,R7

		LDR R11,=LCD_RS
		BIC R6,R6,R11
		BIC R10, R10, #LCD_EN
		LDR R9,=GPIOA_ODR
		STR R10,[R8]                ;EN=0, RS=1, RW=1
		BL  delay                  ;minimo 40ns
		BIC  R10, R10, R11
		STR R10,[R8]
		BL  delay                  ;minimo 40ns
		ORR R10,R10, #LCD_EN         ;EN=1, RS=0, RW=0
		STR R10,[R8]
		BL delay                   ;minimo 230ns
		BIC R10,R10,#LCD_EN
		STR R10,[R8]
		BL delay                   ;minimo 10ns

		POP {R11}
		POP {R10}
		POP {R8}
		POP {R7}
		POP {R5}
		POP {R4}
		POP {LR}
		BX  LR

lcd_data
		PUSH {LR}
		PUSH {R4}
		PUSH {R5}
		PUSH {R7}
		PUSH {R8}
		PUSH {R10}
		PUSH {R11}
		
		AND R5,R4,#0xF0            ;elimina o nible menos significativo
		LSR R5,R5,#4
		AND R7,R5,#0x08            ;separando o bit 7
		LSL R10,R7,#8
		AND R7,R5,#0x04            ;separando o bit 6
		LSL R7,R7,#3
		ORR R10,R10,R7
		AND R7,R5,#0x02            ;separando o bit 5
		LSL R7,R7,#5
		ORR R10,R10,R7
		AND R7,R5,#0x01            ;separando o bit 4
		LSL R7,R7,#8
		ORR R10,R10,R7

		LDR R11,=LCD_RS
		ORR R10, R10, R11
		BIC R10, R10, #LCD_EN
		LDR R8,=GPIOA_ODR
		STR R10,[R8]                ;EN=0, RS=1, RW=1
		BL  delay                  ;minimo 40ns
		ORR R10,R10, #LCD_EN         ;EN=1, RS=0, RW=0
		STR R10,[R8]
		BL delay                   ;minimo 230ns
		BIC R10,R10,#LCD_EN
		STR R10,[R8]
		BL delay                   ;minimo 10ns

		AND R5,R4,#0x0F
		AND R7,R5,#0x08            ;separando o bit 7
		LSL R10,R7,#8
		AND R7,R5,#0x04            ;separando o bit 6
		LSL R7,R7,#3
		ORR R10,R10,R7
		AND R7,R5,#0x02            ;separando o bit 5
		LSL R7,R7,#5
		ORR R10,R10,R7
		AND R7,R5,#0x01            ;separando o bit 4
		LSL R7,R7,#8
		ORR R10,R10,R7

		ORR R10, R10, R11
		BIC R6, R6, #LCD_EN
		LDR R8,=GPIOA_ODR
		STR R10,[R8]                ;EN=0, RS=1, RW=1
		BL  delay                  ;minimo 40ns
		ORR R10,R10, #LCD_EN         ;EN=1, RS=0, RW=0
		STR R10,[R8]
		BL delay                   ;minimo 230ns
		BIC R10,R10,#LCD_EN
		STR R10,[R8]
		BL delay                   ;minimo 10ns
		
		POP {R11}
		POP {R10}
		POP {R8}
		POP {R7}
		POP {R5}
		POP {R4}
		POP {LR}
		BX  LR

lcd_init
		PUSH {LR}
		PUSH {R4}
		MOV R4,#0x33
		BL   lcd_command
		MOV R4,#0x32
		BL   lcd_command
		MOV R4,#0x20
		BL   lcd_command
		MOV R4,#0x0E
		BL   lcd_command
		MOV R4,#0x01
		BL   lcd_command
		BL   delay
		MOV R4,#0x06
		BL   lcd_command
		POP {R4}
		POP {LR}
		BX   LR   

delay_melody
        PUSH {LR}
		PUSH {R0}
		PUSH {R1}		      	; salvando os registradores
		
		LDR R0,= 12         ; R0 = 48, modify for different delays
d_L1_m	LDR R1,= 100000	; R1 = 250, 000 (inner loop count)
d_L2_m	SUBS R1,R1,#1		
		BNE	d_L2_m			
		SUBS R0,R0,#1
		BNE d_L1_m
		
		POP {R1}
		POP {R0}
		POP {LR}
		BX	LR

delay
		PUSH {LR,R0,R1}
		LDR R0,= 1         ; R0 = 48, modify for different delays
d_L1	LDR R1,= 10000	; R1 = 250, 000 (inner loop count)
d_L2	SUBS R1,R1,#1		
		BNE	d_L2			
		SUBS R0,R0,#1
		BNE d_L1
		POP {R1,R0,LR}
		BX	LR