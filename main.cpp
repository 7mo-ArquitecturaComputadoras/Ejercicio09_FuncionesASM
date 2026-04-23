// ============================================================
// Autor: Edson Joel Carrera Avila
// main.cpp
// ============================================================

#include <iostream>

using namespace std;

extern "C" double Mi_pow(double x, double y);
extern "C" double Mi_sqrt(double x);
extern "C" double Mi_fact(double x);

int main() {
    double x, y, r;
    int opcion;

    do {
        // Mostrar el menú
        cout << "\n====================================" << endl;
        cout << "       MENU DE FUNCIONES (FPU)        " << endl;
        cout << "======================================" << endl;
        cout << "1. Calcular Potencia" << endl;
        cout << "2. Calcular Raiz Cuadrada" << endl;
        cout << "3. Calcular Factorial" << endl;
        cout << "4. Salir" << endl;
        cout << "--------------------------------------" << endl;
        cout << "Elige una opcion: ";
        cin >> opcion;

        // Procesar la opción elegida
        switch (opcion) {
        case 1:
            cout << "\n--- POTENCIA ---" << endl;
            cout << "Ingresa la base (X): ";
            cin >> x;
            cout << "Ingresa el exponente (Y): ";
            cin >> y;
            r = Mi_pow(x, y);
            cout << "Resultado: pow( " << x << " , " << y << " ) = " << r << endl;
            break;

        case 2:
            cout << "\n--- RAIZ CUADRADA ---" << endl;
            cout << "Ingresa el numero (X): ";
            cin >> x;
            r = Mi_sqrt(x);
            cout << "Resultado: sqrt( " << x << " ) = " << r << endl;
            break;

        case 3:
            cout << "\n--- FACTORIAL ---" << endl;
            cout << "Ingresa el numero (X): ";
            cin >> x;
            r = Mi_fact(x);
            cout << "Resultado: fact( " << x << " ) = " << r << endl;
            break;

        case 4:
            cout << "\nSaliendo del programa. ¡Hasta luego!" << endl;
            break;

        default:
            cout << "\n[!] Opcion no valida. Por favor, intenta de nuevo." << endl;
            break;
        }

    } while (opcion != 4); // El ciclo se repite mientras no se elija la opción 4

    return 0;
}
