; ============================================================
; Autor: Edson Joel Carrera Avila
; MisFunciones.asm
; ============================================================

.586
.model flat, c

.code

; ------------------------------------------------------------
; Mi_pow: Calcula x^y usando la identidad x^y = 2^(y*log2(x))
; Parámetros: [EBP+8]=x  [EBP+16]=y
; ------------------------------------------------------------
Mi_pow PROC
    PUSH    EBP
    MOV     EBP, ESP

    FLD     QWORD PTR [EBP+16]      ; Cargar y
    FLD     QWORD PTR [EBP+8]       ; Cargar x → ST(0)=x, ST(1)=y

    FYL2X                           ; ST(0) = y * log2(x)

    ; F2XM1 solo funciona bien en [-1,1], así que separamos la parte
    ; entera y la fraccionaria para aplicarla solo a la fracción
    FLD     ST(0)                   ; Duplicar y*log2(x)
    FRNDINT                         ; ST(0) = parte entera
    FSUB    ST(1), ST(0)            ; ST(1) = parte fraccionaria

    FXCH    ST(1)                   ; Intercambiar: ST(0)=fracción, ST(1)=entero
    F2XM1                           ; ST(0) = 2^fracción - 1
    FLD1
    FADDP   ST(1), ST(0)            ; ST(0) = 2^fracción

    FSCALE                          ; ST(0) = 2^fracción * 2^entero = x^y
    FSTP    ST(1)                   ; Descartar el entero, ST(0) = resultado

    MOV     ESP, EBP
    POP     EBP
    RET
Mi_pow ENDP


; ------------------------------------------------------------
; Mi_sqrt: Calcula sqrt(x) usando la instrucción FSQRT
; Parámetro: [EBP+8]=x
; ------------------------------------------------------------
Mi_sqrt PROC
    PUSH    EBP
    MOV     EBP, ESP

    FLD     QWORD PTR [EBP+8]       ; Cargar x
    FSQRT                           ; ST(0) = sqrt(x)

    MOV     ESP, EBP
    POP     EBP
    RET
Mi_sqrt ENDP


; ------------------------------------------------------------
; Mi_fact: Calcula x! mediante un bucle descendente
; Parámetro: [EBP+8]=x
; ------------------------------------------------------------
Mi_fact PROC
    PUSH    EBP
    MOV     EBP, ESP

    FLD1                            ; Acumulador = 1.0
    FLD     QWORD PTR [EBP+8]       ; Cargar x → ST(0)=x, ST(1)=acumulador

bucle:
    FLD1
    FCOMIP  ST(0), ST(1)            ; Comparar 1.0 con x
    JAE     fin                     ; Si x <= 1.0 → terminar

    FMUL    ST(1), ST(0)            ; acumulador *= x
    FLD1
    FSUBP   ST(1), ST(0)            ; x -= 1.0
    JMP     bucle

fin:
    FSTP    ST(0)                   ; Descartar x, ST(0) = resultado (x!)
    POP     EBP
    RET
Mi_fact ENDP

END
