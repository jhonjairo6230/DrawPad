# 0005. PencilKit como motor de dibujo

- **Estado:** Aceptada
- **Fecha:** 2026-11-14

## Contexto

La app necesita un lienzo que responda bien al Apple Pencil: baja latencia,
presión, inclinación, borrador, colores y deshacer. Se quiere una app de
dibujo **básica**, y el foco del proyecto es la arquitectura y la compilación
sin Mac, no programar un motor gráfico.

## Decisión

Usar **PencilKit**, el framework de Apple:

- `PKCanvasView` como lienzo.
- `PKToolPicker` como paleta de herramientas (lápiz, rotulador, lápiz de
  color, borrador, lazo, regla, colores y grosor).
- `PKDrawing` como formato de los trazos, guardado con `dataRepresentation()`.

PencilKit queda **aislado detrás del protocolo `DrawingCanvas`**: solo
`PencilKitCanvas` y `PencilCanvasView` lo importan. El dominio guarda los
trazos como `Data` opaco.

El lienzo se fuerza a **modo claro** (fondo blanco) para que la imagen
exportada sea igual a lo que se ve.

## Alternativas consideradas

- **`Canvas` de SwiftUI + gestos:** más didáctico sobre gráficos, pero habría
  que programar suavizado, presión, borrador y deshacer, con peor latencia.
- **Core Graphics o Metal a medida:** control total, y semanas de trabajo que
  no aportan al objetivo.
- **Barra de herramientas propia en lugar de `PKToolPicker`:** más control
  sobre el diseño, pero sería rehacer lo que Apple ya ofrece.

## Consecuencias

- Experiencia de dibujo de calidad con muy poco código.
- El formato de `PKDrawing` es de Apple: los dibujos no se pueden abrir fuera
  de PencilKit (por eso existe "Guardar en Fotos", que exporta un PNG).
- Poco control sobre el aspecto de la paleta.
- En el simulador del CI no se puede dibujar: el adaptador de PencilKit no
  tiene pruebas automáticas y se verifica a mano en el iPad.
- Si algún día se cambia de motor, solo cambia `PencilKitCanvas`.
