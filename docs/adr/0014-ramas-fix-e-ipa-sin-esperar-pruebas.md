# 0014. Ramas `fix/` e `.ipa` sin esperar a las pruebas

- **Estado:** Aceptada
- **Fecha:** 2026-11-16

## Contexto

El workflow hacía todo en serie: pruebas (unitarias y de interfaz) y, solo
si pasaban, el `.ipa`. Con las pruebas de interfaz, cada ejecución llegó a
unos 15 minutos, de los que compilar la app son unos 3.

Eso frena el ciclo real de este proyecto: la comprobación que más vale es
**instalar la app en el iPad y usarla**, porque muchas cosas (el Pencil, los
gestos, el aspecto) no se pueden verificar en el simulador. Esperar 15
minutos por cada rama antes de poder instalar nada, y otra vez tras cada
fusión, alarga mucho cada vuelta.

Además, el [ADR 0002](0002-git-flow.md) solo preveía `feature/` para todo el
trabajo sobre `develop`, incluidos los arreglos.

## Decisión

1. **El workflow tiene dos trabajos en paralelo:** `IPA` (compila y publica
   el `.ipa`) y `Pruebas`. El `.ipa` ya no depende de las pruebas.
2. **Se puede fusionar a `develop` con `IPA` en verde**, sin esperar a
   `Pruebas`. Se prueba en el iPad a partir de `develop`.
3. **Los fallos se corrigen en ramas `fix/<nombre>`** (desde `develop`, PR a
   `develop`). `feature/` queda para funcionalidad nueva y documentación.
4. **`Pruebas` sigue siendo obligatorio mirarlo:** si falla, se arregla en
   una rama `fix/`. No se desactivan ni se saltan pruebas para ganar tiempo.
5. **Para `main` no cambia nada:** una `release/` solo se fusiona con los
   dos trabajos en verde.

Esta decisión amplía el ADR 0002 (nuevo prefijo `fix/`) y cambia el punto
del [ADR 0004](0004-compilar-sin-mac.md) que decía que el workflow ejecuta
las pruebas antes de generar el `.ipa`.

## Alternativas consideradas

- **Dejarlo en serie:** `develop` solo recibiría código con las pruebas en
  verde, a costa de 15 minutos por vuelta.
- **Quitar o reducir las pruebas de interfaz:** son lentas, pero han cazado
  fallos reales (la app se cerraba al tocar el lienzo con el dedo).
- **Pruebas de interfaz solo en `develop` y `main`:** ahorra minutos en las
  ramas, pero los fallos se descubrirían más tarde.
- **Fusionar sin esperar ni a que compile:** si no compila no hay `.ipa` y
  `develop` queda roto; esperar 3 minutos lo evita.
- **Seguir usando `feature/` para los arreglos:** funciona, pero el nombre de
  la rama no distingue una función nueva de una corrección.

## Consecuencias

- Hay `.ipa` en unos 3 minutos, y probar en el iPad no espera a las pruebas.
- **`develop` puede tener pruebas en rojo durante un rato.** Es un riesgo
  asumido: `develop` es integración, no producción. `main` sigue protegido
  por la regla de las releases.
- Que exista un `.ipa` ya no significa que las pruebas hayan pasado: solo
  que la app compila.
- Cada ejecución usa dos Mac a la vez (más minutos de Actions en total,
  gratuitos al ser el repo público).
- El proyecto se compila dos veces por ejecución (una en cada trabajo).
