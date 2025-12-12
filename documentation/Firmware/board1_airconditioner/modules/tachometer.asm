; (Sahibi: SÜLEYMAN NURİ) - Fan hızı (Timer1) ölçümü
; ============================================================
; DOSYA: tachometer.asm
; GOREV: Fan hiz (tach) olcumu
; PIC: PIC16F877A
; ============================================================

#include <xc.inc>

; --------- DISARIDAN ERISILECEK DEGISKENLER ---------
global FanSpeedL
global FanSpeedH

; --------- DISARIDAN CAGIRILAN FONKSIYON ---------
global TACH_INIT
global READ_TACH

PSECT udata_bank0
FanSpeedL: DS 1
FanSpeedH: DS 1

PSECT code

; ============================================================
; TACH_INIT
; Timer1 external clock (RC0 / T1CKI)
; ============================================================
TACH_INIT:
    BANKSEL TRISC
    BSF TRISC,0         ; RC0 input (T1CKI)

    BANKSEL T1CON
    MOVLW b'00000111'   ; TMR1ON=1, T1CKI external, prescaler 1:1
    MOVWF T1CON

    BANKSEL TMR1H
    CLRF TMR1H
    CLRF TMR1L
    RETURN

; ============================================================
; READ_TACH
; Timer1 sayacini oku
; ============================================================
READ_TACH:
    BANKSEL TMR1L
    MOVF TMR1L,W
    MOVWF FanSpeedL

    MOVF TMR1H,W
    MOVWF FanSpeedH

    ; sayaci sifirla
    CLRF TMR1H
    CLRF TMR1L
    RETURN

END
