;(Sahibi: SÜLEYMAN NURİ) - ADC, Isıtıcı/Soğutucu mantığı

; ============================================================
; DOSYA: temp_control.asm
; GOREV: Sicaklik kontrolu (Board 1)
; PIC: PIC16F877A
; ============================================================

#include <xc.inc>

; --------- DISARIDAN GELEN DEGISKENLER ---------
global AmbientTemp
global DesiredTemp

; --------- DISARIDAN CAGIRILAN FONKSIYON --------
global CONTROL_TEMP

; --------- PINLER ---------
#define HEATER 0     ; RD0
#define COOLER 1     ; RD1

PSECT code

; ============================================================
; CONTROL_TEMP
; DesiredTemp > AmbientTemp  -> Cooler ON
; DesiredTemp < AmbientTemp  -> Heater ON
; Esitlik                   -> Ikisi OFF
; ============================================================
CONTROL_TEMP:
    MOVF AmbientTemp,W
    SUBWF DesiredTemp,W     ; W = Desired - Ambient

    BTFSC STATUS,Z
    GOTO TEMP_IDLE

    BTFSS STATUS,C          ; C=0 -> Desired < Ambient
    GOTO COOLER_ON

    ; C=1 -> Desired > Ambient
    GOTO HEATER_ON

HEATER_ON:
    BSF PORTD,HEATER
    BCF PORTD,COOLER
    RETURN

COOLER_ON:
    BCF PORTD,HEATER
    BSF PORTD,COOLER
    RETURN

TEMP_IDLE:
    BCF PORTD,HEATER
    BCF PORTD,COOLER
    RETURN

END
