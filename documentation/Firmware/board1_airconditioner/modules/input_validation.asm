; (Sahibi: OZAN) - 10-50 derece sınır kontrolü

; PIC16F877A için genel ayarlar ve dosya tanımlamaları
; #include <p16f877a.inc> ; Varsayımsal include

; *** RAM TANIMLAMALARI ***
cblock 0x33
    keypad_temp_int         ; Geçici tamsayı toplama (0-99)
    keypad_temp_frac        ; Geçici kesirli kısım (0-9)
    temp_digit_count        ; Tamsayı basamak sayacı (maks. 2)
endc

; --- INPUT VALIDATION FONKSİYONLARI ---

; input_validator_init: Değerleri temizler.
input_validator_init:
    CLRF keypad_temp_int
    CLRF keypad_temp_frac
    CLRF temp_digit_count
    RETURN

; process_key: keypad.asm'den gelen tuş kodunu işler.
process_key:
    MOVF key_code, W
    SUBLW '#'               ; Tuş '#' mi?
    BTFSC STATUS, Z
    GOTO finish_input       ; '#' ise girişi sonlandır ve doğrula

    MOVF key_code, W
    SUBLW '*'               ; Tuş '.' mi? (Yıldız tuşu ondalık nokta) [cite_start][cite: 778]
    BTFSC STATUS, Z
    GOTO separator_key      ; '*' ise kesirli kısma geç

    MOVF key_code, W
    SUBLW '0'               ; Tuş 0-9 arasında mı? (ASCII kontrolü)
    BTFSC STATUS, C
    GOTO numeric_key        ; 0-9 arası ise sayısal işlemi yap

    GOTO process_key_exit   ; Diğer tuşları (A, B, C, D) yoksay

separator_key:
    BSF input_mode_flag, 1  ; Tamsayı kısım tamamlandı bayrağını ayarla
    GOTO process_key_exit

numeric_key:
    ; Tuşun sayısal değerini al (ASCII'den tam sayıya)
    MOVF key_code, W
    SUBLW '0'               ; '0' ASCII'si çıkarılarak sayısal değer elde edilir (0-9)

    BTFSC input_mode_flag, 1 ; Tamsayı kısım tamamlandı mı?
    GOTO fractional_part_process

    ; --- TAMSAYI KISIM (INTEGRAL) ---
    INCF temp_digit_count, F
    MOVLW 0x03
    SUBWF temp_digit_count, W
    BTFSS STATUS, Z         ; 2 basamaktan fazla mı?
    GOTO PROCESS_KEY_EXIT

    ; keypad_temp_int = keypad_temp_int * 10 + yeni_basamak
    MOVF keypad_temp_int, W
    CALL multiply_by_ten    ; W = W * 10 (Özel alt program gerekli)
    ADDWF W, W              ; W = W * 10 + yeni_basamak
    MOVWF keypad_temp_int
    GOTO process_key_exit

fractional_part_process:
    ; --- KESİRLİ KISIM (FRACTIONAL) ---
    ; [cite_start]Maksimum 1 basamak al (R2.1.2-2) [cite: 776]
    BTFSS keypad_temp_frac, 0 ; keypad_temp_frac = 0 (henüz basılmadı) mı?
    GOTO process_key_exit
    
    MOVWF keypad_temp_frac  ; İlk kesirli basamağı kaydet
    GOTO process_key_exit

process_key_exit:
    RETURN

; --- GİRİŞİ SONLANDIRMA VE DOĞRULAMA ('#' TUŞU) ---
finish_input:
    CALL validate_input     ; 10.0-50.0 kontrolü
    BTFSC STATUS, C         ; C=1 ise kabul edildi
    GOTO save_to_memory
    
    ; [cite_start]Giriş Reddedildi (R2.1.2-3) [cite: 780]
    CALL reject_input
    GOTO finish_exit

; Sınır kontrolünü yapar. Eğer kabul edilirse C=1, reddedilirse C=0 ayarlar.
validate_input:
    ; 1. [cite_start]Alt Sınır Kontrolü (T < 10.0) [cite: 780]
    MOVLW 10
    SUBWF keypad_temp_int, W ; W = T_int - 10
    BTFSS STATUS, C          ; T_int >= 10 ise atla
    GOTO validation_reject   ; T_int < 10 ise reddet

    ; 2. [cite_start]Üst Sınır Kontrolü (T > 50.0) [cite: 780]
    MOVLW 50
    SUBWF keypad_temp_int, W ; W = T_int - 50
    BTFSC STATUS, C          ; T_int > 50 ise devam et
    GOTO validation_accept   ; T_int < 50 ise kabul et

    ; W = 0 (T_int = 50) ise kesirli kısma bak
    BTFSC STATUS, Z
    GOTO check_frac_for_50

    GOTO validation_reject  ; T_int > 50 ise reddet

check_frac_for_50:
    CLRF W
    SUBWF keypad_temp_frac, W ; W = T_frac - 0
    BTFSC STATUS, Z           ; T_frac = 0 ise kabul et (yani tam 50.0)
    GOTO validation_accept

    GOTO validation_reject    ; T_frac > 0 ise reddet (yani 50.x)

validation_accept:
    BSF STATUS, C             ; Kabul edildi (C=1)
    RETURN

validation_reject:
    BCF STATUS, C             ; Reddedildi (C=0)
    RETURN

; Geçerli değeri kaydeder.
save_to_memory:
    ; Tamsayı kısım kaydı
    MOVF keypad_temp_int, W
    MOVWF desired_temp_high ; [cite_start]R2.1.1-1 adresine yaz [cite: 782]

    ; Kesirli kısım ölçeklendirme (0-9 -> 0-255)
    MOVF keypad_temp_frac, W
    CALL scale_fractional_part ; W'daki 0-9 değerini 0-255'e ölçekle
    MOVWF desired_temp_low ; [cite_start]R2.1.1-1 adresine yaz [cite: 782]

    GOTO finish_exit

reject_input:
    ; Giriş değerini temizle ve hata mesajı göster (örn: 7-Segment'te "Err")
    CALL input_validator_init
    ; ... Hata gösterim kodu (3. kişi modülü ile etkileşim)
    GOTO finish_exit

finish_exit:
    BCF input_mode_flag, 0  ; Giriş modunu kapat
    CALL input_validator_init ; Geçici tamponları temizle
    RETURN
    
; --- YARDIMCI MATEMATİK FONKSİYONLARI ---

; multiply_by_ten: W'daki değeri 10 ile çarpar (Gereklidir)
multiply_by_ten:
    ; Çarpma işlemi döngü veya toplama ile yapılmalıdır
    ; W = W * 10
    RETURN

; scale_fractional_part: W'daki 0-9 değerini 0-255 aralığına ölçekler (Gereklidir)
; Amaç: W = W * 256 / 10
scale_fractional_part:
    ; 0.5 (W=5) -> 5 * 256 / 10 = 128
    ; 0.1 (W=1) -> 1 * 256 / 10 = 25
    ; Çok baytlı çarpma/bölme rutini gereklidir.
    RETURN
