.include "M328PDEF.INC" 

.cseg

	JMP config_init

;Direcciones de los vectores de interrupcion

;Direccion del vector de interrupcion timer/counter1
.ORG 0x001A
	JMP TIMER1_OVF

		
config_init:
;*************************************************************************************
; Se configura el timer/counter1 de 16 bits
;
;Entrada: -				
;Salida: -					
;Registros utilizados: R16
;*************************************************************************************

configure_timer:
		LDI R16,0
		ORI R16,((CS12<<1)|(CS11<<1)|(CS10<<1)); Se elige la frecuencia
		STS TCCR1B, R16;




;Dirección siguiente a la ultima interrupción
.ORG 0x0033

	LDI R25,0xFF
	OUT DDRC,R25
	CBI PORTC,5
	;Habilito las interrupciones
	SEI
	LDI R16,1;
	;ORI R16,(TOIE1<<1); Habilito la interrupcion del timer/counter1
	STS TIMSK1,R16; REGISTRO TIMSK1

wait: RJMP wait; Espera hasta que el sensor detecte movimiento

TIMER1_OVF:
	RETI




