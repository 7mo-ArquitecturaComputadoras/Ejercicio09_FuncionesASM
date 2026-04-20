; ============================================================
; MisFunciones.asm
; ============================================================

.586
.model flat, c

.code

; ------------------------------------------------------------
; Mi_pow: Calcula x^y usando la identidad x^y = 2^(y*log2(x))
; ------------------------------------------------------------
Mi_pow PROC
    PUSH    EBP                     ; Preserva EBP del llamador
    MOV     EBP, ESP                ; EBP apunta a la base del marco actual

    FLD     QWORD PTR [EBP+16]      ; ST(0) = y
    FLD     QWORD PTR [EBP+8]       ; ST(0) = x,  ST(1) = y

    ; FYL2X calcula ST(1)*log2(ST(0)) y deja el resultado en ST(0)
    FYL2X                           ; ST(0) = y*log2(x)

    ; F2XM1 solo es precisa en [-1, 1], por eso se separa parte entera y fraccionaria
    FLD     ST(0)                   ; ST(0) = y*log2(x),  ST(1) = y*log2(x)
    FRNDINT                         ; ST(0) = entero(y*log2(x)),  ST(1) = y*log2(x)
    FSUB    ST(1), ST(0)            ; ST(1) = fraccion(y*log2(x)), ST(0) = entero

    FXCH    ST(1)                   ; ST(0) = fraccion,  ST(1) = entero
    F2XM1                           ; ST(0) = 2^fraccion - 1
    FLD1                            ; ST(0) = 1.0,  ST(1) = 2^fraccion - 1,  ST(2) = entero
    FADDP   ST(1), ST(0)            ; ST(0) = 2^fraccion,  ST(1) = entero  (saca ST(0) viejo)

    ; FSCALE multiplica ST(0) por 2^ST(1), combinando fraccion y entero
    FSCALE                          ; ST(0) = x^y (resultado final)

    FSTP    ST(1)                   ; Descarta el entero que quedo en ST(1); ST(0) = resultado

    MOV     ESP, EBP                ; Libera espacio local (simetria con la entrada)
    POP     EBP                     ; Restaura EBP del llamador
    RET

Mi_pow ENDP


; ------------------------------------------------------------
; Mi_sqrt: Calcula sqrt(x) usando la instruccion FSQRT
; ------------------------------------------------------------
Mi_sqrt PROC
    PUSH    EBP                     ; Preserva EBP del llamador
    MOV     EBP, ESP                ; EBP apunta a la base del marco actual

    FLD     QWORD PTR [EBP+8]       ; ST(0) = x
    FSQRT                           ; ST(0) = sqrt(x)

    MOV     ESP, EBP                ; Libera espacio local (simetria con la entrada)
    POP     EBP                     ; Restaura EBP del llamador
    RET

Mi_sqrt ENDP

; ------------------------------------------------------------
; Mi_fact: Calcula x! mediante un bucle descendente
; ------------------------------------------------------------
Mi_fact PROC
    PUSH    EBP                     ; Preserva EBP del llamador
    MOV     EBP, ESP                ; EBP apunta a la base del marco actual

    FLD1                            ; ST(0) = 1.0  (acumulador, empieza en 1)
    FLD     QWORD PTR [EBP+8]       ; ST(0) = x,  ST(1) = acumulador

bucle:
    ; Comparar 1.0 con x: si 1.0 >= x (es decir x <= 1), el factorial termina
    FLD1                            ; ST(0) = 1.0,  ST(1) = x,  ST(2) = acumulador
    FCOMIP  ST(0), ST(1)            ; Compara y actualiza flags; saca el 1.0 de la pila
    JAE     fin                     ; Salta si 1.0 >= x  =>  x <= 1 (caso base o n=0/1)

    ; acumulador *= x  (ST(0)=x, ST(1)=acumulador tras el FCOMIP que saco el 1.0)
    FMUL    ST(1), ST(0)            ; ST(1) = acumulador * x,  ST(0) = x (sin cambio)

    ; x -= 1.0  para avanzar al siguiente termino
    FLD1                            ; ST(0) = 1.0,  ST(1) = x,  ST(2) = acumulador
    FSUBP   ST(1), ST(0)            ; ST(0) = x - 1.0  (saca el 1.0);  ST(1) = acumulador
    JMP     bucle

fin:
    ; ST(0) = x (<= 1, ya no es util), ST(1) = resultado final
    FSTP    ST(0)                   ; Descarta x; ahora ST(0) = acumulador con x!
    POP     EBP
    RET

Mi_fact ENDP

END
