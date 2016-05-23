.INCLUDE "M328PDEF.INC"
	
	.cseg
	.ORG $00
	JMP PROGRAMA // Reset
	
	;.org INT0addr Si ocurre una interrupcion en el pin que tiene INT0, salta a la rutina INT_EXT_0, hay que armar la rutina
	;rjmp INT_EXT_0 Rutina de interrupcion

	.org INT_VECTORS_SIZE ; Saltea  los vectores de interrupcion
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
	;Configuracion del ADC
	LDS R16,ADMUX;
	ORI R16,((1<<REFS0)|(1<<MUX2)|(1<<MUX0));
	STS ADMUX, R16; Se configura AVcc como la referencia 	
	LDS R16,ADCSRA;
	ORI R16,((1<<ADEN)|(1<<ADPS1)|(1<<ADPS0)); Seteo el valor de division del clk 1M/8
	STS ADCSRA, R16; Habilito el adc
	
CONFIGURACION_PWM:
	LDI R25,40
	OUT OCR0A,R25
	LDI R25,0
	ORI R25,((1<<WGM01)|(1<<WGM00)|(1<<COM0A1)|(0<<COM0A0))
	OUT TCCR0A,R25
	LDI R25,0
	ORI R25,((0<<CS00)|(1<<CS01)|(0<<CS02))
	OUT TCCR0B,R25
ENCIENDO:
	CALL RETARDO;
	LDS R16,ADCSRA;
	ORI R16,(1<<ADSC)
	STS ADCSRA,R16 ;
CONVERSION:
	LDS R24,ADCSRA ;
	SBRC R24,4;
	RJMP CONVERSION;
	LDS R24,ADCSRA;
	ORI R24, (1<<ADIF)
	STS ADCSRA,R24
	LDI ZL,LOW(VECTOR_LUZ<<1)
	LDI ZH,HIGH(VECTOR_LUZ<<1)
	LPM R16,Z+;
	LDS R18,ADCL;
	LDS R19,ADCH;
	LDI R23,0 ;
	OUT PORTB,R23
	OUT PORTD,R23
	LSR R19;%Por relacion llevo el espacios de 1023ptos a 255ptos dividiendo en 4
	ROR R18;
	LSR R19
	ROR R18;
	CALL PWM;
	CALL RETARDO_PWM;
	CP R18,R16;%Comparo con la maxima intensidad para la que esta todo apagado.
	BRLO ENCIENDO
	SBI PORTB,0 ;Hay poca oscuridad pero prendo 1 Y apago 2
	CBI PORTD,6
	CBI PORTD,7
	LPM R16,Z+;
	CP R18,R16
	BRLO ENCIENDO
	SBI PORTB,0
	SBI PORTD,7 ;Enciendo dos y apago 1
	CBI PORTD,6
	LPM R16,Z;
	CP R18,R16
	BRLO ENCIENDO
	SBI PORTD,6 ;%Enciendo 3 
	SBI PORTD,7
	SBI PORTB,0
	
	RJMP ENCIENDO



RETARDO:
	LDI R20,250
	LDI R21,250
	LDI R22,200

LOOP:
	DEC R20
	BRNE LOOP
	DEC R21
	BRNE LOOP
	DEC R22
	BRNE LOOP
	RET

RETARDO_PWM:
	LDI R20,255
LOOP_PWM:
	DEC R20
	BRNE LOOP_PWM
	NOP
	RET

PWM:
	OUT OCR0A,R18;
	RET

FIN:JMP FIN

VECTOR_LUZ:			.db 64, 128 , 192
