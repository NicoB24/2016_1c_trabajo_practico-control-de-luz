.include "M328PDEF.INC" 

.cseg

	JMP config_init

;Direcciones de los vectores de interrupcion
.ORG 0x001A
	JMP TIMER1_OVF
.ORG 0x0002; Dirección del vector INT0
	JMP ext_int0;

config_init:
	.ORG 0x0034
	;Se configura INT0 por flanco ascendente
	LDI R25,0
	ORI R25,((1<<ISC01)|(1<<ISC00))
	STS EICRA, R25; Registro EICRA
	LDI R25,0
	ORI R25,(1<<INT0)
	OUT EIMSK,R25
	LDI R25,0xFF
	OUT DDRB,R25
config_timer:
	LDI R20,0
	ORI R20,((CS12<<1)|(1))
	STS TCCR1B,R20	
	SEI
wait:RJMP wait; Espera hasta que el sensor detecte movimiento

ext_int0:
	SEI
	LDI R20,0
	STS TCNT1H,R20
	STS TCNT1L,R20
	LDI R16,1;
	STS TIMSK1,R16;
	ORI R20,(0<<INT0)
	OUT EIMSK,R20
	SBI PORTB,1
	RETI

TIMER1_OVF:
	IN auxiliar,EIMSK
	ORI auxiliar,(1<<INT0)
	OUT EIMSK,auxiliar
	CBI PORTB,1
	RETI

