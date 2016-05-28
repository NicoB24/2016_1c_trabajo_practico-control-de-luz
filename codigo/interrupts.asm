.include "M328PDEF.INC" 

.cseg

	JMP config_init

;Direcciones de los vectores de interrupcion

.ORG 0x0002; Dirección del vector INT0
	JMP ext_int0;

.ORG 0x0012; Dirección del vector TIMER2 OVF
	JMP tim2_ovf;

		
config_init:
;*************************************************************************************
; Se configuran las interrupciones externas del microcontrolador
;
;Entrada: -				
;Salida: -					
;Registros utilizados: R25
;*************************************************************************************

configure_ext_int:
	;Se configura INT0 por flanco ascendente
	LDI R25,0
	ORI R25,((1<<ISC01)|(1<<ISC00))
	STS 0X69, R25; Registro EICRA
	LDI R25,0
	ORI R25,(1<<INT0)
	OUT EIMSK,R25
	

;*************************************************************************************
; Se configuran los timers del microcontrolador
;
;Entrada: -				
;Salida: -					
;Registros utilizados: R25
;*************************************************************************************

configure_timers:
	;Se configura Timer/counter2
	LDI R25,0
	ORI R25,((1<<CS22)|(1<<CS21)|(1<<CS20)); Se configura la frecuencia
	STS 0xb1,R25; Registro TCCR2B



;Dirección siguiente a la ultima interrupción
.ORG 0x0033
	
	SEI
	LDI R25,0xFF
	OUT DDRC,R25
	CBI PORTC,5

wait: RJMP wait; Espera hasta que el sensor detecte movimiento





;*************************************************************************************
; Iterrupcion externa 0, enciende un led y luego de un tiempo lo apaga.
;
;Entrada: -				
;Salida: -					
;Registros utilizados: R25
;*************************************************************************************

ext_int0:
	;Se activa el Timer/counter2
	SEI
	LDI R25,0
	ORI R25,(1<<TOIE2)
	OUT TOIE2,R25; Registro TIMSK2
	SBI PORTC,5;
	RETI




;*************************************************************************************
; Handler que se llama cuando el timer 2 sufre un overflow
;
;
;Entrada: 					Ninguna
;Salida: 					Ninguna
;Registros utilizados:				Ninguna
;*************************************************************************************
tim2_ovf:
	;Apagar luz del encendido led
	CBI PORTC,5
	RETI
