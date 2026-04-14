# Ejercicio 9 — Funciones en Lenguaje Ensamblador (FPU)

## Descripción General

Programa en C++ que delega el cálculo de `x^y` a una función implementada en ensamblador x86 (`MiPow`), haciendo uso de la **Unidad de Punto Flotante (FPU)** del procesador mediante instrucciones del co-procesador matemático 80387.

---

## Análisis del Problema

### Definición

Calcular la potencia de un número real:

```
resultado = x ^ y
```

donde `x` es la base e `y` es el exponente, ambos valores de tipo `double` (64 bits, doble precisión).

### Restricción del Hardware

La FPU no dispone de una instrucción directa para calcular potencias arbitrarias. Sin embargo, cuenta con las instrucciones `FYL2X` y `F2XM1`, que permiten descomponer el problema usando la identidad matemática:

```
x^y = 2^( y * log2(x) )
```

Adicionalmente, la instrucción `F2XM1` sólo opera correctamente cuando su argumento pertenece al intervalo `[-1, 1]`, por lo que es necesario **separar el resultado de `y * log2(x)` en su parte entera y su parte fraccionaria** antes de aplicarla.

### Estrategia de Solución

La función `MiPow` implementa el cálculo en los siguientes pasos:

| Paso | Operación | Descripción |
|------|-----------|-------------|
| 1 | `FLD y`, `FLD x` | Carga base y exponente a la pila FPU |
| 2 | `FYL2X` | Calcula `y * log2(x)` → resultado en ST(0) |
| 3 | `FLD ST(0)` + `FRNDINT` | Obtiene la parte entera redondeada |
| 4 | `FSUB ST(1), ST(0)` | Obtiene la parte fraccionaria |
| 5 | `F2XM1` + `FLD1` + `FADDP` | Calcula `2^fracción` |
| 6 | `FSCALE` | Escala por `2^parte_entera` → resultado final |

---

## Estructura del Proyecto

```
Ejercicio9_FuncionesASM/
├── Funcion.cpp          # Programa principal (C++): entrada/salida y llamada a MiPow
├── MisFunciones.asm     # Implementación de MiPow en ensamblador x86 (FPU)
├── Ejercicio9_FuncionesASM.vcxproj
└── Ejercicio9_FuncionesASM.slnx
```

---

## Interfaz de la Función ASM

```cpp
// Declaración en C++
extern "C" double MiPow(double x, double y);
```

### Convención de Llamada (`model flat, c`)

| Parámetro | Tipo     | Ubicación en pila (respecto a EBP) |
|-----------|----------|------------------------------------|
| `x`       | `double` | `[EBP + 8]`  (8 bytes)             |
| `y`       | `double` | `[EBP + 16]` (8 bytes)             |
| Retorno   | `double` | Registro ST(0) de la FPU           |

Los parámetros de 64 bits (`double`) se pasan por la pila en orden izquierda→derecha bajo la convención C, y el valor de retorno se deja en el tope de la pila flotante `ST(0)`, que es el mecanismo estándar para devolver `double` en x86 de 32 bits.

---

## Instrucciones FPU Utilizadas

| Instrucción | Función |
|-------------|---------|
| `FLD`       | Carga un valor `double` desde memoria o pila FPU |
| `FYL2X`     | Calcula `ST(1) * log2(ST(0))` y deja el resultado en ST(0) |
| `FRNDINT`   | Redondea ST(0) al entero más cercano |
| `FSUB`      | Resta entre registros de la pila FPU |
| `FXCH`      | Intercambia ST(0) y ST(n) |
| `F2XM1`     | Calcula `2^ST(0) - 1` (para ST(0) ∈ [-1, 1]) |
| `FADDP`     | Suma y saca el operando de la pila |
| `FSCALE`    | Escala: `ST(0) = ST(0) * 2^ST(1)` |
| `FSTP`      | Guarda ST(0) en destino y lo saca de la pila |

---

## Ejemplo de Ejecución

```
Programa que realiza la funcion pow(x,y)
----- CON EL USO DE LA FPU -----
Ingresa X: 2
Ingresa Y: 10

El resultado de 2 elevado a 10 es: 1024
```

---

## Limitaciones Conocidas

| # | Caso | Comportamiento actual | Causa raíz |
|---|------|-----------------------|------------|
| 1 | **Base negativa (`x < 0`)** | Resultado incorrecto o `NaN` | La instrucción `FYL2X` calcula `log2(x)`, y el logaritmo de un número negativo no está definido en los reales. La FPU genera un valor indefinido (`QNaN`) que se propaga por el resto del cálculo. |
| 2 | **Base cero (`x = 0`)** | Resultado incorrecto o `-∞` | `log2(0)` tiende a `-∞`, lo que produce resultados no confiables según el valor de `y`. |

> ⚠️ **Pendiente de corrección:** La función `MiPow` no valida los argumentos de entrada antes de operar. Una solución futura debería manejar los casos `x < 0` y `x = 0` antes de llamar a `FYL2X`, ya sea retornando un valor de error definido o implementando la lógica alternativa correspondiente (por ejemplo, para bases negativas con exponente entero el resultado sí está definido matemáticamente).

---

## Requisitos

- **Compilador:** MSVC (Visual Studio) con soporte para ensamblado MASM
- **Arquitectura:** x86 (32 bits), modo protegido plano (`flat`)
- **Estándar C++:** C++11 o superior
