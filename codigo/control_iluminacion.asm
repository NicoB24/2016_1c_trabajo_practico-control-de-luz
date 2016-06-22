.include "M328PDEF.INC" 
.listmac

.def auxiliar =r22
.def auxiliar_2 =r23
.def auxiliar_adc_1 =r16
.def auxiliar_adc_2 =r17
.def auxiliar_sreg=r18
.def estado_sensor=r19
.def auxiliar_vector=r20
.def auxiliar_comparacion=r21
.cseg
JMP config_init
;Direcciones de los vectores de interrupcion
.ORG 0x001A
	JMP TIMER1_OVF
.ORG 0x0002; Dirección del vector INT0
	JMP ext_int0;

.ORG 0x0039
config_init:
	;Inicializacion del stack
	LDI auxiliar,LOW(RAMEND)
	OUT SPL,auxiliar
	LDI auxiliar,HIGH(RAMEND)
	OUT SPH,auxiliar	

;****************************************************
;Configuracion interrupcion del sensor de movimiento
;Se configura INT0 por flanco ascendente
;****************************************************	
	LDS auxiliar,EICRA
	ORI auxiliar,((1<<ISC01)|(1<<ISC00))
	STS EICRA, auxiliar; Registro EICRA
	LDS auxiliar,EIMSK
	ORI auxiliar,(1<<INT0)
	OUT EIMSK,auxiliar

;***************************************************************************************************
;Configuracion del timer de la interrupcion
;El timer se configura para overflow de manera de habilitar la interrupcion del sensor de movimiento
;***************************************************************************************************
config_timer:
	LDS auxiliar,TCCR1B
	ANDI auxiliar,~((0<<ICNC1)|(0<<ICES1)|(0<<WGM13)|(0<<WGM12)|(1<<CS12)|(1<<CS11)|(1<<CS10))
	STS TCCR1B,auxiliar	
	LDI auxiliar_2,0
	STS TCNT1H,auxiliar_2
	STS TCNT1L,auxiliar_2
	
;**************************************************************
;Configuracion del pwm en fast mode 8 bits
;**************************************************************
CONFIGURACION_PWM:
	LDI auxiliar,0
	OUT OCR0A,auxiliar
	LDS auxiliar,TCCR0A
	ORI auxiliar,((1<<WGM01)|(1<<WGM00)|(1<<COM0A1)|(0<<COM0A0))
	OUT TCCR0A,auxiliar
	LDS auxiliar,TCCR0B
	ORI auxiliar,((1<<CS00)|(1<<CS01)|(0<<CS02))
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
	SBI DDRD,6 ;El pin del pwm es (PCINT22/OC0A/AIN0) PD6
	CBI DDRC,5;Configuro el pin PC5 (ADC5/SCL/PCINT13) como entrada	
	SBI DDRB,1;Configuro el led verde para debugear
	SBI DDRB,2;Configuro el led amarillo para debugear
	SBI DDRC,4;Configuro el pin c4 como salida
	SBI DDRC,3;*****************c3************
	SBI DDRC,2;*****************c2************
	SBI DDRC,1;*****************c1************
	SBI DDRC,0;*****************c0************
;**********************	
;Programa principal	
;PRUEBA DEL ADC CON EL PWM E INTERRUPCIONES
;**********************
	LDI estado_sensor,0;Inicilizo el estado del sensor
	SBI PORTB,1
	RCALL RETARDO_INICIAL
	CBI PORTB,1
	RCALL RETARDO_INICIAL
	SEI;Habilito las interrupciones
	
HERE:
	SBI PORTB,1
	CBI PORTB,2
	RCALL RETARDO
	CBI PORTB,1
	RCALL RETARDO
	LDS r27,SMCR
	ORI r27,((0<<SM1)|(1<<SE))
	OUT SMCR,r27
	sleep
HERE_IT:	
	SBRS estado_sensor,0
	RJMP HERE;va here_it
	RCALL DESACTIVAR_SENSOR
	CBI PORTB,1;
HERE_TIMER:
	RCALL HABILITAR_TIMER
	ldi estado_sensor,1
	
SENSAR:
	SBI PORTB,2
	SENSAR_IT: 
			  RCALL SENSAR_LUZ	
			  RCALL MODULACION_LED
			  RCALL CONTROL_LUZ
			  SBRC estado_sensor,0
			  RJMP SENSAR_IT
			  RCALL DESACTIVAR_TIMER
			  SBIC PIND,2
			  RJMP HERE_TIMER
	RCALL APAGAR_LED_CONTROL
	RCALL HABILITAR_SENSOR
	RCALL APAGAR_LUZ
	SLEEP
	RJMP HERE
	
;******************************************************************

SENSAR_LUZ:
	LDS auxiliar_adc_1,ADCSRA;
	ORI auxiliar_adc_1,(1<<ADSC)
	STS ADCSRA,auxiliar_adc_1;
CONVERSION: 
	LDS auxiliar_adc_1,ADCSRA ;
	SBRS auxiliar_adc_1,ADIF;
	RJMP CONVERSION;
	RET 

MODULACION_LED:
	LDS auxiliar_adc_1,ADCSRA;
	ORI auxiliar_adc_1, (1<<ADIF)
	STS ADCSRA,auxiliar_adc_1
	LDS auxiliar_adc_1,ADCL;
	LDS auxiliar_adc_2,ADCH;
	LSR auxiliar_adc_2;%Por relacion llevo el espacios de 1023ptos a 255ptos dividiendo en 4
	ROR auxiliar_adc_1;
	LSR auxiliar_adc_2
	ROR auxiliar_adc_1;
	OUT OCR0A,auxiliar_adc_1;
	RET

CONTROL_LUZ:
	push r30
	push r31
	push auxiliar_vector
	mov auxiliar_comparacion,auxiliar_adc_1
	LDI ZL,LOW(VECTOR_LUZ<<1)
	LDI ZH,HIGH(VECTOR_LUZ<<1)
	LPM auxiliar_vector,Z+
	CP auxiliar_comparacion,auxiliar_vector;%Comparo con la maxima intensidad para la que esta todo apagado.
	BRLO ESTADO1;
	LPM auxiliar_vector,Z+
	CP auxiliar_comparacion,auxiliar_vector
	BRLO ESTADO2;
	LPM auxiliar_vector,Z+
	CP auxiliar_comparacion,auxiliar_vector
	BRLO ESTADO3;
	LPM auxiliar_vector,Z+
	CP auxiliar_comparacion,auxiliar_vector
	BRLO ESTADO4;
	LPM auxiliar_vector,Z+
	CP auxiliar_comparacion,auxiliar_vector
	BRLO ESTADO5;
	LPM auxiliar_vector,Z+
	CP auxiliar_comparacion,auxiliar_vector
	BRLO ESTADO6;
	

ESTADO1:
		CBI PORTC,0
		CBI PORTC,1
		CBI PORTC,2
		CBI PORTC,3
		CBI PORTC,4
		RJMP FIN
ESTADO2:
		SBI PORTC,0
		CBI PORTC,1
		CBI PORTC,2
		CBI PORTC,3
		CBI PORTC,4
		RJMP FIN		
ESTADO3:
		SBI PORTC,0
		SBI PORTC,1
		CBI PORTC,2
		CBI PORTC,3
		CBI PORTC,4
		RJMP FIN	
ESTADO4:
		SBI PORTC,0
		SBI PORTC,1
		SBI PORTC,2
		CBI PORTC,3
		CBI PORTC,4
		RJMP FIN
ESTADO5:
		SBI PORTC,0
		SBI PORTC,1
		SBI PORTC,2
		SBI PORTC,3
		CBI PORTC,4
		RJMP FIN
ESTADO6:
		SBI PORTC,0
		SBI PORTC,1
		SBI PORTC,2
		SBI PORTC,3
		SBI PORTC,4
		RJMP FIN
FIN:
	pop auxiliar_vector
	pop r31
	pop r30
	RET
	
APAGAR_LUZ:
	CBI PORTC,0
	CBI PORTC,1
	CBI PORTC,2
	CBI PORTC,3
	CBI PORTC,4
	RET
	
APAGAR_LED_CONTROL:
	LDI auxiliar_adc_1,0
	OUT OCR0A,auxiliar_adc_1;
	RET

DESACTIVAR_SENSOR:
	CLI
	LDS auxiliar_2,EIMSK
	ANDI auxiliar_2,~(1<<INT0)
	OUT EIMSK,auxiliar_2
	SEI
	RET

HABILITAR_SENSOR:
	CLI
	IN auxiliar_2,EIMSK
	ORI auxiliar_2,(1<<INT0)
	OUT EIMSK,auxiliar_2
	SEI
	RET

REACTIVAR_CONTADOR:
	LDS auxiliar_2,TCCR1B
	ORI auxiliar_2,((1<<CS12)|(0<<CS11)|(1<<CS10))
	ANDI auxiliar_2,~((0<<CS12)|(1<<CS11)|(0<<CS10))
	RET
	
DETENER_CONTADOR:
	LDS auxiliar_2,TCCR1B
	ANDI auxiliar_2,~((0<<ICNC1)|(0<<ICES1)|(0<<WGM13)|(0<<WGM12)|(1<<CS12)|(1<<CS11)|(1<<CS10))
	RET
	
DESACTIVAR_TIMER:
	CLI
	LDS auxiliar_2,TCCR1B
	ANDI auxiliar_2,~((0<<ICNC1)|(0<<ICES1)|(0<<WGM13)|(0<<WGM12)|(1<<CS12)|(1<<CS11)|(1<<CS10))
	STS TCCR1B,auxiliar_2
	LDI auxiliar_2,0;Desactivo la interrupcion del timer overflow
	STS TIMSK1,auxiliar_2;
	SEI
	RET

HABILITAR_TIMER:
	LDI auxiliar_2,0
	STS TCNT1H,auxiliar_2
	STS TCNT1L,auxiliar_2
	LDS auxiliar_2,TCCR1B
	ORI auxiliar_2,((1<<CS12)|(0<<CS11)|(1<<CS10))
	ANDI auxiliar_2,~((0<<ICNC1)|(0<<ICES1)|(0<<WGM13)|(0<<WGM12)|(0<<CS12)|(1<<CS11)|(0<<CS10))
	STS TCCR1B,auxiliar_2
	LDI auxiliar_2,1;
	STS TIMSK1,auxiliar_2;
	RET
	
RETARDO:
	LDI R24,33
L1:	
	LDI R25,200
L2:
	LDI R26,250
L3:
	DEC R26
	BRNE L3
	DEC R25
	BRNE L2
	DEC R24
	BRNE L1
	RET	
	
RETARDO_INICIAL:
	LDI R24,250
L1_INICIO:	
	LDI R25,250
L2_INICIO:
	LDI R26,250
L3_INICIO:
	DEC R26
	BRNE L3_INICIO
	DEC R25
	BRNE L2_INICIO
	DEC R24
	BRNE L1_INICIO
	RET	
	
;**************************************************************
;Interrupcion del sensor de movimiento
;**************************************************************
ext_int0:
	IN auxiliar_sreg,SREG
	PUSH auxiliar_sreg
	lds auxiliar_2,SMCR
	andi auxiliar_2,~(1<<SE)
	out SMCR,auxiliar_2
	LDI estado_sensor,1 ;se activo el sensor
	POP auxiliar_sreg
	OUT SREG,auxiliar_sreg
	RETI
;**************************************************************
;Interrupcion del timer overflow
;**************************************************************
TIMER1_OVF:
	IN auxiliar_sreg,SREG
	PUSH auxiliar_sreg
	LDI estado_sensor,0;Dejo de sensar
	POP auxiliar_sreg
	OUT SREG,auxiliar_sreg
	RETI

VECTOR_LUZ:			.db 16,20,32,45,100,255
	
