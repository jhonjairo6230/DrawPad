# 0025. Pruebas más rápidas: sin ejecuciones repetidas

- **Estado:** Aceptada
- **Fecha:** 2026-11-28
- **Relacionadas:** [ADR 0014](0014-ipa-y-pruebas-en-paralelo.md) (los dos
  trabajos en paralelo) y [ADR 0023](0023-ipa-solo-al-fusionar.md) (cuándo se
  genera el `.ipa`), que siguen igual.

## Contexto

El trabajo **Pruebas** tardaba unos 33 minutos, más la espera por un Mac libre
(hasta 15 minutos). Medido en una ejecución completa:

| Parte | Tiempo |
| ----- | ------ |
| Compilar y arrancar el simulador | ~8 min |
| 262 pruebas unitarias | ~15 s |
| **40 pruebas de interfaz, una tras otra** | **~23 min** |

Dos causas:

1. **Ejecuciones repetidas.** Cada push a una rama `feature/` con PR abierto
   lanzaba dos ejecuciones del mismo commit (una por el push y otra por el
   PR). La cuenta gratuita tiene pocos Mac a la vez, así que se hacía cola.
2. **Las pruebas de interfaz iban en serie**, en un solo simulador. Cada una
   abre la app desde cero y toca la pantalla como una persona (media de 35 s).

## Decisión

1. **Las ramas `feature/` no corren por `push`**, solo por su pull request.
   Siguen corriendo por `push` `develop` y `main` (pruebas y `.ipa` al
   fusionar), `release/`, `hotfix/` y `backport/`; y cualquier rama con
   **Run workflow**.
2. **Las pruebas siguen en serie, en un solo simulador.** Se probó a
   repartirlas en 2 simuladores (`-parallel-testing-enabled YES
   -parallel-testing-worker-count 2`) y **no ahorra tiempo**: el reparto
   funcionó (unos 22 minutos de pruebas en cada simulador), pero el Mac de
   GitHub tiene 3 núcleos y cada prueba fue el doble de lenta
   (`CanvasUITests`: 679 s en vez de ~295 s). En total, 29 minutos frente a
   ~24 en serie.
3. Las pruebas de `CanvasUITests` (32) quedan **separadas por tema** en
   `NotebookUITests`, `PageUITests`, `CanvasUITests`, `TextAndImageUITests` y
   `DiagramUITests`, más `PhoneUITests`, con las utilidades en la clase base
   `DrawPadUITestCase`. No acelera nada por sí solo, pero cada archivo es más
   corto y fácil de leer, y deja listo el reparto si algún día hay Mac más
   potentes.

## Alternativas consideradas

- **Quitar o juntar pruebas de interfaz:** más rápido, pero han cazado fallos
  reales (cierre al tocar con el dedo, el gesto de volver de iOS 26).
- **Pruebas en paralelo (2 o más simuladores):** probado con 2 y no ahorra
  tiempo en el Mac de GitHub (ver la decisión 2). Con más simuladores sería
  peor.
- **Guardar la compilación entre ejecuciones (caché):** ahorra unos minutos,
  pero con proyectos de Xcode a menudo no se reutiliza bien. Se deja para más
  adelante.
- **Repartir las pruebas de interfaz en varios trabajos (varios Mac):** más
  paralelismo, pero ocupa más Mac a la vez y alarga la cola.

## Consecuencias

- Una rama `feature/` sin PR no tiene pruebas automáticas: hay que abrir el PR
  o usar Run workflow.
- La duración de una ejecución no cambia (unos 30 minutos), pero hay la mitad
  de ejecuciones, así que se espera menos en la cola de Mac.
- Una prueba nueva de interfaz va en la clase de su tema.
