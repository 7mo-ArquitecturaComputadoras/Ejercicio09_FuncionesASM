# Ejercicio 9 — Funciones Matemáticas en Ensamblador x86 (FPU)

## Descripción

Programa en C++ que delega el cálculo de tres operaciones matemáticas a funciones implementadas en ensamblador x86, haciendo uso de la **Unidad de Punto Flotante (FPU)** mediante instrucciones del coprocesador matemático 80387.

Las tres operaciones disponibles son:

- `x ^ y` — potencia de base x con exponente y
- `sqrt(x)` — raíz cuadrada de x
- `x!` — factorial de x

---

## Estructura del Proyecto

```
Ejercicio9_FuncionesASM/
├── Funcion.cpp              # Programa principal: menú, entrada/salida, llamadas a ASM
├── MisFunciones.asm         # Implementación de las tres funciones en ensamblador x86
├── Ejercicio9_FuncionesASM.vcxproj
└── Ejercicio9_FuncionesASM.slnx
```

---

## Interfaz entre C++ y Ensamblador

Cada función se declara en C++ con `extern "C"` para que MASM pueda enlazarla sin decoración de nombres:

```cpp
extern "C" double Mi_pow(double x, double y);
extern "C" double Mi_sqrt(double x);
extern "C" double Mi_fact(double x);
```

### Convención de llamada (`model flat, c`)

Todos los parámetros `double` (64 bits) se pasan por la pila en orden izquierda → derecha. El valor de retorno se deja en `ST(0)`, que es el mecanismo estándar para devolver `double` en x86 de 32 bits.

| Función   | Parámetro | Ubicación en pila |
|-----------|-----------|-------------------|
| `Mi_pow`  | `x` (base) | `[EBP + 8]`      |
| `Mi_pow`  | `y` (exponente) | `[EBP + 16]` |
| `Mi_sqrt` | `x`        | `[EBP + 8]`      |
| `Mi_fact` | `x`        | `[EBP + 8]`      |

---

## Funcionamiento de cada función

### `Mi_pow` — Potencia x^y

La FPU no tiene una instrucción directa para potencias arbitrarias. Se resuelve usando la identidad:

```
x^y = 2^( y * log2(x) )
```

La instrucción `F2XM1` solo opera correctamente en el intervalo `[-1, 1]`, por lo que el resultado de `y * log2(x)` se descompone en parte entera y parte fraccionaria antes de aplicarla:

| Paso | Instrucción(es) | Resultado en ST(0) |
|------|-----------------|-------------------|
| 1 | `FLD y`, `FLD x` | ST(0)=x, ST(1)=y |
| 2 | `FYL2X` | y·log2(x) |
| 3 | `FLD ST(0)`, `FRNDINT` | parte entera |
| 4 | `FSUB ST(1), ST(0)` | parte fraccionaria en ST(1) |
| 5 | `F2XM1`, `FLD1`, `FADDP` | 2^fraccion |
| 6 | `FSCALE` | x^y (resultado final) |

---

### `Mi_sqrt` — Raíz cuadrada

La FPU sí dispone de una instrucción directa para esta operación:

```
FSQRT   ; ST(0) = sqrt(ST(0))
```

La función carga `x`, aplica `FSQRT` y retorna el resultado en `ST(0)`.

---

### `Mi_fact` — Factorial x!

Se implementa con un bucle descendente en la FPU. La pila flotante mantiene dos registros durante toda la ejecución: `ST(0)` como contador (x) y `ST(1)` como acumulador del producto.

```
Mientras x > 1:
    acumulador *= x
    x -= 1.0
Retornar acumulador
```

Los casos base `x = 0` y `x = 1` están cubiertos: el bucle no se ejecuta y se retorna `1.0`.

---

## Instrucciones FPU Utilizadas

| Instrucción | Operación |
|-------------|-----------|
| `FLD`       | Carga un `double` desde memoria a la pila FPU |
| `FLDZ`      | Carga la constante 0.0 |
| `FLD1`      | Carga la constante 1.0 |
| `FYL2X`     | Calcula `ST(1) * log2(ST(0))` → ST(0) |
| `FRNDINT`   | Redondea ST(0) al entero más cercano |
| `FSUB`      | Resta entre registros de la pila FPU |
| `FXCH`      | Intercambia ST(0) y ST(n) |
| `F2XM1`     | Calcula `2^ST(0) - 1` (para ST(0) ∈ [-1, 1]) |
| `FADDP`     | Suma ST(0) + ST(1), saca ST(0) |
| `FSCALE`    | `ST(0) = ST(0) * 2^ST(1)` |
| `FSQRT`     | `ST(0) = sqrt(ST(0))` |
| `FMUL`      | Multiplica dos registros de la pila |
| `FSUBP`     | Resta ST(1) - ST(0), saca ST(0) |
| `FCOMIP`    | Compara ST(0) con ST(n) y actualiza flags de CPU; saca ST(0) |
| `FSTP`      | Guarda ST(0) en destino y lo saca de la pila |

---

## Ejemplo de Ejecución

```
====================================
       MENU DE FUNCIONES (FPU)
======================================
1. Calcular Potencia
2. Calcular Raiz Cuadrada
3. Calcular Factorial
4. Salir
--------------------------------------
Elige una opcion: 1

--- POTENCIA ---
Ingresa la base (X): 2
Ingresa el exponente (Y): 10
Resultado: pow( 2 , 10 ) = 1024

Elige una opcion: 2

--- RAIZ CUADRADA ---
Ingresa el numero (X): 25
Resultado: sqrt( 25 ) = 5

Elige una opcion: 3

--- FACTORIAL ---
Ingresa el numero (X): 6
Resultado: fact( 6 ) = 720
```

---

## Limitaciones y Mejoras Pendientes

Las funciones no realizan validación de entradas. La siguiente tabla resume los casos problemáticos actuales y la severidad de cada uno:

| Función | Entrada inválida | Comportamiento actual | Severidad |
|---------|-----------------|----------------------|-----------|
| `Mi_pow` | `x <= 0` | `FYL2X` produce `NaN` o `-Inf`; resultado incorrecto | Alta |
| `Mi_pow` | `x < 0` con `y` entero | Matemáticamente válido (ej. `(-2)^3 = -8`), pero el algoritmo falla por `log2` de negativo | Media — requiere ruta de código alternativa |
| `Mi_sqrt` | `x < 0` | `FSQRT` retorna `NaN` sin señal visible al usuario | Alta |
| `Mi_fact` | `x < 0` | El bucle nunca termina (loop infinito) | Crítica |
| `Mi_fact` | `x` con parte fraccionaria (ej. `3.7`) | El contador nunca cae exactamente en `1.0`; loop infinito | Crítica |
| `Mi_fact` | `x > 170` | Desbordamiento del tipo `double`; retorna `+Inf` | Media |

### Mejoras posibles

- Agregar guardas con `FCOMIP` antes de las operaciones críticas (`FYL2X`, `FSQRT`, el bucle de factorial) para detectar entradas fuera de rango y retornar un valor de error definido (por ejemplo `NaN` vía `0.0/0.0`).
- En `Mi_fact`, validar que `x` sea entero comparando `x` contra `FRNDINT(x)` antes de entrar al bucle.
- En `Mi_fact`, agregar una cota superior fija (`x > 170`) usando `FILD` para cargar el límite desde un registro entero.
- Propagar el error al lado C++ detectando `NaN` con `isnan()` y mostrando un mensaje descriptivo al usuario.

---

## Requisitos

- **Compilador:** MSVC (Visual Studio) con soporte para ensamblado MASM
- **Arquitectura:** x86 (32 bits), modo protegido plano (`flat`)
- **Estándar C++:** C++11 o superior