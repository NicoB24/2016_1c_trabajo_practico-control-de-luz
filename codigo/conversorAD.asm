.INCLUDE "M328PDEF.INC"
.ORG $00
JMP PROGRAMA // Reset

PROGRAMA:
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16
	LDI R16,LOW(RAMEND)
	OUT SPL,R16
	CBI DDRC,5;Configuro el pin PC5 (ADC5/SCL/PCINT13) como entrada
	
	;Configuracion del ADC
	LDS R16,ADMUX;
	ORI R16,((1<<REFS0)|(1<<MUX2)|(1<<MUX0));
	STS ADMUX, R16; Se configura AVcc como la referencia 	
	LDS R16,ADCSRA;
	ORI R16,((1<<ADEN)|(1<<ADPS1)|(1<<ADPS0)); Seteo el valor de division del clk 1M/8
	STS ADCSRA, R16; Habilito el adc
	
FIN:RJMP FIN