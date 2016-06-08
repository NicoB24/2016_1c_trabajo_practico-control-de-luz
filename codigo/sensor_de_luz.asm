.include "M328PDEF.INC" 
.include "avr_macros.inc"
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
	JMP ext_int0;
;****************************************************
;Configuracion interrupcion del sensor de movimiento

;****************************************************
config_init:
	.ORG 0x0034
	;Se configura INT0 por flanco ascendente
	LDI auxiliar,0
	ORI auxiliar,((1<<ISC01)|(1<<ISC00))
	STS EICRA, auxiliar; Registro EICRA
	LDI auxiliar,0
	ORI auxiliar,(1<<INT0)
	OUT EIMSK,auxiliar
	LDI auxiliar,0xFF
	OUT DDRB,auxiliar
;***************************************************************************************************
;Configuracion del timer de la interrupcion
;El timer se configura para overflow de manera de habilitar la interrupcion del sensor de movimiento
;***************************************************************************************************
config_timer:
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
	SBI DDRD,6 ;El pin del pwm es (PCINT22/OC0A/AIN0) PD6
	CBI DDRC,5;Configuro el pin PC5 (ADC5/SCL/PCINT13) como entrada	
	
	
;**********************	
;Programa principal	
;**********************
	SEI;Habilito las interrupciones
;******************************************************************
;PRUEBA DEL ADC CON EL PWM	
HERE:
	LDS auxiliar_adc_1,ADCSRA;
	ORI auxiliar_adc_1,(1<<ADSC)
	STS ADCSRA,R16 ;
CONVERSION:
	LDS auxiliar_adc_1,ADCSRA ;
	SBRC auxiliar_adc_1,4;
	RJMP CONVERSION;
	LDS auxiliar_adc_1,ADCSRA;
	ORI R24, (1<<ADIF)
	STS ADCSRA,auxiliar_adc_1
	LDS auxiliar_adc_1,ADCL;
	LDS auxiliar_adc_2,ADCH;
	LSR auxiliar_adc_2;%Por relacion llevo el espacios de 1023ptos a 255ptos dividiendo en 4
	ROR auxiliar_adc_1;
	LSR auxiliar_adc_2
	ROR auxiliar_adc_1;
	OUT OCR0A,auxiliar_adc_1;
	
;****************************************************	
wait:RJMP HERE; Espera hasta que el sensor detecte movimiento


;**************************************************************
;Interrupcion del sensor de movimiento
;**************************************************************
ext_int0:
	SEI
	LDI auxiliar_2,0
	STS TCNT1H,auxiliar_2
	STS TCNT1L,auxiliar_2
	LDI auxiliar_2,1;
	STS TIMSK1,auxiliar_2;
	ORI auxiliar_2,(0<<INT0)
	OUT EIMSK,auxiliar_2
	SBI PORTB,1
	RETI
;**************************************************************
;Interrupcion del timer overflow
;**************************************************************
TIMER1_OVF:
	IN auxiliar_2,EIMSK
	ORI auxiliar_2,(1<<INT0)
	OUT EIMSK,auxiliar_2
	CBI PORTB,1
	RETI


	

