.include "M328PDEF.INC" 

.cseg
;Direcciones de los vectores de interrupcion

.ORG 0x0002; Dirección del vector INT0
	JMP inicio

.ORG 0x0020; Dirección del vector TIMER0 OVF
	JMP tim0_ovf;

		

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
	STS 0x69, R25; Registro EICRA
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
	;Se configura Timer/counter0
	LDI R25,0
	ORI R25,((0<<CS00)|(1<<CS01)|(0<<CS02)); Se configura la frecuencia
	OUT TCCR0B,R25
	RET


;*************************************************************************************
; Funcion de prueba, enciende un led y luego de un tiempo los apaga.
;
;Entrada: -				
;Salida: -					
;Registros utilizados: R25
;*************************************************************************************

;Dirección siguiente a la ultima interrupción
.ORG 0x0032

wait: RJMP wait; Espera hasta que el sensor detecte movimiento

inicio:
	;Se activa el Timer/counter0
	LDI R25,0
	ORI R25,(1<<TOIE0)
	STS 0x6e,R25; Registro TIMSK0
	SEI ;Se activa nuevamente el flag I para habilitar las interrupciones
	;Enceder luz de un led
here: RJMP here




;*************************************************************************************
; Handler que se llama cuando el timer 0 sufre un overflow
;
;
;Entrada: 					Ninguna
;Salida: 					Ninguna
;Registros utilizados:		Ninguna
;*************************************************************************************
tim0_ovf:
	;Apagar luz del encendido led
	reti	
