# 0025. Pruebas más rápidas: sin ejecuciones repetidas y en paralelo

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
2. **Pruebas en paralelo en 2 simuladores**
   (`-parallel-testing-enabled YES -parallel-testing-worker-count 2`).
3. `xcodebuild` reparte **clases** de prueba entre los simuladores, no pruebas
   sueltas. Por eso las 32 pruebas de `CanvasUITests` se separan **por tema**
   en clases de tamaño parecido (unos 4 minutos cada una):
   `NotebookUITests`, `PageUITests`, `CanvasUITests`, `TextAndImageUITests` y
   `DiagramUITests`, más `PhoneUITests`. Las utilidades comunes van en la clase
   base `DrawPadUITestCase`. Las pruebas en sí no cambian.

## Alternativas consideradas

- **Quitar o juntar pruebas de interfaz:** más rápido, pero han cazado fallos
  reales (cierre al tocar con el dedo, el gesto de volver de iOS 26).
- **3 o más simuladores:** el Mac de GitHub es modesto (3 núcleos); con más
  simuladores a la vez es más probable que alguna prueba falle por lentitud.
  Se empieza con 2; si van estables, se puede subir a 3 cambiando un número.
- **Guardar la compilación entre ejecuciones (caché):** ahorra unos minutos,
  pero con proyectos de Xcode a menudo no se reutiliza bien. Se deja para más
  adelante.
- **Repartir las pruebas de interfaz en varios trabajos (varios Mac):** más
  paralelismo, pero ocupa más Mac a la vez y alarga la cola.

## Consecuencias

- Una rama `feature/` sin PR no tiene pruebas automáticas: hay que abrir el PR
  o usar Run workflow.
- Las pruebas de interfaz deberían tardar la mitad (unos 12 minutos en vez de
  23), más un poco por preparar las copias del simulador.
- Una prueba nueva de interfaz va en la clase de su tema; si una clase crece
  mucho más que las otras, conviene partirla para que el reparto siga parejo.
