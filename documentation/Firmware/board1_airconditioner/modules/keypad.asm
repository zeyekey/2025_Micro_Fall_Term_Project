; (Sahibi: OZAN) - Tuş takımı tarama ve Interrupt

; PIC16F877A için genel ayarlar ve dosya tanımlamaları
; #include <p16f877a.inc> ; Varsayımsal include
; __CONFIG 0x....          ; Varsayımsal konfigürasyon

; *** RAM TANIMLAMALARI (keypad.asm) ***
cblock 0x20
    desired_temp_high       ; [cite_start]R2.1.1-1: İstenen sıcaklık tamsayı kısmı (0x20) [cite: 764, 782]
    desired_temp_low        ; [cite_start]R2.1.1-1: İstenen sıcaklık kesirli kısmı (0x21) [cite: 764, 782]
endc

cblock 0x30
    key_code                ; Okunan tuşun ASCII kodu (geçici)
    input_mode_flag         ; Bit 0: 1=Giriş modu açık, Bit 1: 1=Tamsayı kısım tamamlandı
    debounce_delay_reg      ; Debounce gecikme sayacı
endc

; *** PORT TANIMLAMALARI ***
#define KEYPAD_PORT PORTB
#define KEYPAD_TRIS TRISB
#define KEYPAD_ROWS_MASK 0x0F   ; RB0-RB3
#define KEYPAD_COLS_MASK 0xF0   ; RB4-RB7

; --- KEYPAD FONKSİYONLARI ---

; keypad_init: Keypad portlarını ayarlar
keypad_init:
    BSF STATUS, RP0         ; Bank 1
    MOVLW 0xF0              ; RB0-RB3 Giriş (Satırlar), RB4-RB7 Çıkış (Sütunlar)
    MOVWF KEYPAD_TRIS
    BCF STATUS, RP0         ; Bank 0
    CLRF KEYPAD_PORT
    CLRF input_mode_flag    ; Başlangıçta giriş modu kapalı
    RETURN

; keypad_scan: Keypad'i tarar ve basılan tuşun kodunu key_code'a yazar.
keypad_scan:
    ; Keypad Debouncing (titreşim engelleme)
    CALL debounce
    
    MOVLW 0xF0              ; Sütun tarama başlangıcı (C1, C2, C3, C4 hepsi HIGH)
    MOVWF KEYPAD_PORT
    
    ; 4 Sütun İçin Tarama Döngüsü
    MOVLW 0x10              ; Sütun maskesi 0001xxxx (RB4)
    MOVWF FSR               ; FSR'ı sayaç olarak kullan
    
COL_SCAN_LOOP:
    MOVF FSR, W             
    XORLW 0x0F              ; Sadece mevcut sütunu LOW yapmak için (0x10 -> 0xEF)
    ANDWF KEYPAD_PORT, F    ; KEYPAD_PORT'ta sadece bir sütunu LOW yap

    CALL check_rows         ; Satırları oku
    BTFSC STATUS, Z         ; Eğer bir tuş basıldıysa (W=0 değilse)
    GOTO SCAN_COMPLETE
    
    ; Bir sonraki sütuna geç
    MOVLW 0xF0              
    MOVWF KEYPAD_PORT       ; Sütunları tekrar HIGH yap
    MOVLW 0x10
    ADDWF FSR, F            ; 0x10, 0x20, 0x40, 0x80 şeklinde FSR'ı güncelle
    BTFSC STATUS, C         ; Taştıysa, tüm sütunlar taranmıştır (C4 sonrası)
    GOTO END_SCAN_LOOP
    GOTO COL_SCAN_LOOP
    
END_SCAN_LOOP:
    CLRF key_code           ; Tuş basılmadı
    RETURN
    
; check_rows: 4 satırı kontrol eder ve tuş basıldıysa key_code'u ayarlar
check_rows:
    ; PORTB'yi oku ve sadece alt 4 bitini (satırları) koru
    MOVF KEYPAD_PORT, W
    ANDLW 0x0F
    
    ; W=0x0F (1111) ise tuşa basılmamıştır (tüm satırlar HIGH)
    MOVLW 0x0F
    SUBWF W, W
    BTFSC STATUS, Z         ; Z=1 ise tuş basılmadı, Z=0 ise devam et
    RETURN                  ; W zaten 0, Z=1. Status'e dokunma.

    ; Tuş Basıldı: Sütun ve Satır Kesişimini Bul ve key_code'a yaz.
    ; Örnek: C1 (RB4 LOW), L2 (RB1 LOW) -> Tuş '4'
    ; (Burada tuş haritası (lookup table) kullanılmalıdır, kısaca gösterilmiştir.)
    
    ; Sütun (C1=0x10, C2=0x20, C3=0x40, C4=0x80) -> FSR'dan gelir
    ; Satır (L1=0xE, L2=0xD, L3=0xB, L4=0x7) -> W'dan gelir (terslenmiş)
    
    ; Basılan tuşun kodunu key_code'a yükleyen karmaşık bir lookup rutini buraya gelir.
    ; Basılan tuşlar: 1, 2, 3, A, 4, 5, 6, B, 7, 8, 9, C, *, 0, #, D
    
    MOVLW '1'               ; Basit bir varsayım
    MOVWF key_code
    
SCAN_COMPLETE:
    RETURN

; --- YARDIMCI FONKSİYONLAR ---

; debounce: Kısa bir gecikme sağlar
debounce:
    MOVLW 0x0A
    MOVWF debounce_delay_reg
DEBOUNCE_LOOP:
    DECFSZ debounce_delay_reg, F
    GOTO DEBOUNCE_LOOP
    RETURN

; --- KESME SERVİS RUTİNİ (ANA PROGRAMDA OLMALIDIR) ---

; A tuşu kesmesi (RB-Port Change Interrupt) için:
; isr:
;   BTFSC INTCON, RBIF ; RB port değişimi kesmesi mi?
;   GOTO keypad_interrupt_handler
; ... diğer kesmeler
;   RETFIE

; keypad_interrupt_handler: A tuşu kesme rutini (PORTB Interrupt-on-Change)
; Varsayım: A tuşu basıldığında bir satır girişi (örn. RB0) LOW'a çekiliyor.
keypad_interrupt_handler:
    ; Sadece 'A' tuşuna basıldığında giriş modunu başlat
    CLRF key_code           ; Geçici kodları temizle
    BCF input_mode_flag, 1  ; Tamsayı tamamlandı bayrağını temizle
    BSF input_mode_flag, 0  ; Giriş modunu başlat (R2.1.2-1)
    
    BCF INTCON, RBIF        ; Kesme bayrağını temizle
    RETURN
