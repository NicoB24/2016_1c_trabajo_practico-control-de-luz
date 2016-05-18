.INCLUDE "M328PDEF.INC"
.ORG $00
JMP PROGRAMA // Reset



PROGRAMA:
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16
	LDI R16,LOW(RAMEND)
	OUT SPL,R16
	LDI R16,0xFF ; R16 a unos
	OUT DDRD,R16 ;Configura todo el puerto D como salidas
	OUT DDRB,R16 ;Configura todo el puerto B como salidas
	LDI R16,0 ;
	OUT DDRC,R16 ;Configuro todo el puerto C como entradas
	






;CONFIGURACION_PWM:
	LDI R25,128
	OUT OCR0A,R25
	LDI R25,0
	ORI R25,((1<<WGM01)|(1<<WGM00)|(1<<COM0A1)|(0<<COM0A0))
	OUT TCCR0A,R25
	LDI R25,0
	ORI R25,((0<<CS00)|(1<<CS01)|(0<<CS02))
	OUT TCCR0B,R25
	
	
	;LDI R25,40
	;STS TCNT0,R25
	;LDI R25,0
	;ORI R25,((1<<WGM00)|(1<<COM0A1)|(1<<COM0A0))
	;STS TCCR0A,R25
	;LDI R25,0
	;ORI R25,((0<<CS00)|(0<<CS01)|(0<<CS02))
	;STS TCCR0B,R25
	
	
	

FIN:rjmp FIN;
