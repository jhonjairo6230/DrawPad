# 0011. Suavizar trazos con un algoritmo propio

- **Estado:** Aceptada
- **Fecha:** 2026-11-15

## Contexto

Se pidió "embellecer la letra": que lo escrito a mano quede más limpio. En
iPadOS, la app Notas tiene **Smart Script**, que refina la escritura imitando
la letra del usuario. Esa función **no está disponible para apps de
terceros**: la API pública de PencilKit ofrece el lienzo, los trazos y el
reconocimiento de texto, pero no el refinado.

Lo que sí ofrece PencilKit es acceso a cada trazo: su tinta y los puntos de
control de su recorrido, que se pueden leer y volver a crear.

## Decisión

Añadir una acción **"Suavizar trazos"** (menú "Más" del lienzo) con un
algoritmo propio:

1. Para cada trazo se toman las posiciones de sus puntos de control y se les
   aplica una **media móvil con pesos 1-2-1**, dos pasadas por pulsación
   (`StrokeSmoother`). El primer y el último punto no se mueven.
2. El trazo se reconstruye con la **misma tinta, grosor, presión y máscara**;
   solo cambia el recorrido.
3. Se aplica a **todos los trazos de la hoja**. Pulsar otra vez suaviza más.
4. El cambio **se puede deshacer**: el adaptador registra el dibujo anterior
   en el `UndoManager` del lienzo. "Borrar todo" pasa a usar el mismo
   mecanismo.
5. El algoritmo vive fuera de PencilKit (solo `CGPoint`) para poder probarlo
   con números.

## Alternativas consideradas

- **Smart Script de Apple:** no hay API pública.
- **Suavizar mientras se dibuja** (estabilizador): PencilKit no deja
  intervenir en el trazo en curso.
- **Suavizar solo los trazos seleccionados con el lazo:** más preciso, pero
  PencilKit no expone qué trazos están seleccionados.
- **Curvas de mejor ajuste** (por ejemplo, Bézier por mínimos cuadrados) o
  **reconocer formas** (rectas, círculos): resultados más "perfectos", con
  bastante más código y el riesgo de cambiar la intención del dibujo.
- **Simplificar puntos** (Ramer-Douglas-Peucker): quita puntos en lugar de
  moverlos, y con ellos se pierden los datos de presión y grosor.
- **Ajuste de intensidad** (un deslizador): más control, más interfaz. Se
  consigue algo parecido pulsando varias veces.

## Consecuencias

- Reduce el temblor de líneas y letras; **no** endereza la escritura, no
  iguala el tamaño de las letras ni imita un estilo. No es Smart Script.
- Las curvas cerradas y las esquinas se redondean un poco en cada pasada; si
  se abusa, las letras pequeñas pierden detalle. Para eso está deshacer.
- Los trazos muy cortos (uno o dos puntos de control) no cambian.
- Afecta a toda la hoja: no se puede suavizar solo una parte.
- La reconstrucción de trazos con PencilKit no tiene pruebas unitarias; la
  cubre una prueba de interfaz (suavizar, repetir, deshacer, rehacer, reabrir
  la hoja). **El resultado visual solo se puede juzgar en el iPad**, y los
  parámetros (pesos y pasadas) pueden necesitar ajuste.
