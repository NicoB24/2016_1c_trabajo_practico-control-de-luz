.include "M328PDEF.INC" 

.cseg
;Direcciones de los vectores de interrupcion

.ORG 0x0002; Dirección del vector INT0
	JMP inicio

.ORG 0x0012; Dirección del vector TIMER2 OVF
	JMP tim2_ovf;

		

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
	;Se configura Timer/counter2
	LDI R25,0
	ORI R25,((0<<CS22)|(1<<CS21)|(0<<CS20)); Se configura la frecuencia
	STS 0xb1,R25; Registro TCCR2B



;Dirección siguiente a la ultima interrupción
.ORG 0x0033

wait: RJMP wait; Espera hasta que el sensor detecte movimiento

;*************************************************************************************
; Funcion de prueba, enciende un led y luego de un tiempo los apaga.
;
;Entrada: -				
;Salida: -					
;Registros utilizados: R25
;*************************************************************************************

inicio:
	;Se activa el Timer/counter2
	LDI R25,0
	ORI R25,(1<<TOIE2)
	OUT TOIE2,R25; Registro TIMSK2
	SEI ;Se activa nuevamente el flag I para habilitar las interrupciones
	;Enceder luz de un led
	LDI R25,0xFF
	OUT PORTC,R25
	SBI PORTC,5;

here: RJMP here




;*************************************************************************************
; Handler que se llama cuando el timer 2 sufre un overflow
;
;
;Entrada: 					Ninguna
;Salida: 					Ninguna
;Registros utilizados:				Ninguna
;*************************************************************************************
tim2_ovf:
	;Apagar luz del led encendido
	CBI PORTC,5
	reti	
