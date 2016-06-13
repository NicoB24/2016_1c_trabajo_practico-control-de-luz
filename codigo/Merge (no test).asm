.include "M328PDEF.INC" 
.listmac

.def auxiliar =r22
.def auxiliar_2 =r23
.def auxiliar_adc_1 =r16
.def auxiliar_adc_2 =r17
.cseg
	JMP config_init

;Direcciones de los vectores de interrupcion
.ORG 0x001A
	JMP TIMER1_OVF
.ORG 0x0002; Dirección del vector INT0
	JMP EXT_INT0;

.ORG 0x0033; Dirección posterior al ultimo vector de interrupción 
config_init:
	;Inicilización del stack
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16
	LDI R16,LOW(RAMEND)
	OUT SPL,R16

;***************************************************************************************************
;Configuracion de la interrupción externa
;El pin INT0 se configura de manera de activar la interrupcion por flanco ascendente
;***************************************************************************************************
CONFIGURACION_SENSOR:	
	LDI auxiliar,0
	ORI auxiliar,((1<<ISC01)|(1<<ISC00))
	STS EICRA, auxiliar; Registro EICRA
	LDI auxiliar,0
	ORI auxiliar,(1<<INT0)
	OUT EIMSK,auxiliar

;***************************************************************************************************
;Configuracion del timer de la interrupcion
;El timer se configura para overflow de manera de habilitar la interrupcion del sensor de movimiento
;***************************************************************************************************
CONFIGURACION_TIMER:
	LDI auxiliar,0
	ORI auxiliar,((CS12<<1)|(1))
	STS TCCR1B,auxiliar	

;**************************************************************
;Configuracion del pwm en fast mode 8 bits
;**************************************************************
CONFIGURACION_PWM:
	LDI auxiliar,128
	OUT OCR0A,auxiliar
	LDI auxiliar,0
	ORI auxiliar,((1<<WGM01)|(1<<WGM00)|(1<<COM0A1)|(0<<COM0A0))
	OUT TCCR0A,auxiliar
	LDI auxiliar,0
	ORI auxiliar,((0<<CS00)|(1<<CS01)|(0<<CS02))
	OUT TCCR0B,auxiliar
	

;**************************************************************
;Configuracion del ADC	
;**************************************************************
CONFIGURACION_ADC:
	LDS auxiliar,ADMUX;
	ORI auxiliar,((1<<REFS0)|(1<<MUX2)|(1<<MUX0));
	STS ADMUX, auxiliar; Se configura AVcc como la referencia 	
	LDS auxiliar,ADCSRA;
	ORI auxiliar,((1<<ADEN)|(1<<ADPS1)|(1<<ADPS0)); Seteo el valor de division del clk 1M/8
	STS ADCSRA, auxiliar; Habilito el adc
	
;************************************************************
;Configuracion de los pines del ADC y PWM
;************************************************************
CONFIGURACION_PINES:
	SBI DDRD,6 ;El pin del PWM es (PCINT22/OC0A/AIN0) PD6, como salida
	CBI DDRC,5;Configuro el pin PC5 (ADC5/SCL/PCINT13) como entrada	
	



;**********************	
;Programa principal	
;**********************
	LDI R16,0xFF ; R16 a unos
	OUT DDRB,R16 ;Configura todo el puerto B como salidas
	SEI;Habilito las interrupciones

HERE:RJMP HERE; Espera hasta que el sensor detecte movimiento



;**************************************************************
;Interrupcion del sensor de movimiento
;**************************************************************
EXT_INT0:
	;Se desactiva la interrupción del sensor y se activa por overflow
	ORI auxiliar_2,(0<<INT0)
	OUT EIMSK,auxiliar_2
	SEI
	LDI auxiliar_2,0
	STS TCNT1H,auxiliar_2
	STS TCNT1L,auxiliar_2
	LDI auxiliar_2,1;
	STS TIMSK1,auxiliar_2;

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
	LSR R19;%Por relacion llevo el espacios de 1023ptos a 255ptos dividiendo en 4
	ROR R18;
	LSR R19
	ROR R18;
	CALL PWM;
	CALL RETARDO_PWM;
	CP R18,R16;%Comparo con la maxima intensidad para la que esta todo apagado.
	BRLO ENCIENDO
	SBI PORTB,0 ;Hay poca oscuridad pero prendo 1 Y apago 2
	CBI PORTB,1
	CBI PORTB,2
	LPM R16,Z+;
	CP R18,R16
	BRLO ENCIENDO
	SBI PORTB,0
	SBI PORTB,1 ;Enciendo dos y apago 1
	CBI PORTB,2
	LPM R16,Z;
	CP R18,R16
	BRLO ENCIENDO
	SBI PORTB,0 ;Enciendo 3 
	SBI PORTB,1
	SBI PORTB,2
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
	


;**************************************************************
;Interrupcion del timer overflow
;**************************************************************
TIMER1_OVF:
	;Se apagan los LEDS
	CBI PORTB,0
	CBI PORTB,1
	CBI PORTB,2
	;Habilito la interrupción del sensor nuevamente
	SEI
	LDI auxiliar_2,0
	ORI auxiliar_2,(1<<INT0)
	OUT EIMSK,auxiliar_2
	JMP HERE
	
	
	
VECTOR_LUZ:			.db 64, 128 , 192























