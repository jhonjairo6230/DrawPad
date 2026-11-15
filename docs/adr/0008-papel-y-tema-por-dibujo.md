# 0008. Papel de fondo y tema claro/oscuro por dibujo

- **Estado:** Aceptada
- **Fecha:** 2026-11-15

## Contexto

Se quiere elegir el papel sobre el que se dibuja (blanco, cuadrícula, líneas
o puntos) y poder dibujar sobre **papel oscuro**.

El [ADR 0005](0005-pencilkit.md) forzaba el lienzo a modo claro, porque
PencilKit cambia el color de la tinta según el aspecto de la interfaz: en
modo oscuro, un trazo negro se muestra blanco. Con el modo del sistema
mandando, un dibujo se vería distinto según la hora del día y la imagen
exportada podía no coincidir con la pantalla.

## Decisión

1. El papel es **un ajuste de cada dibujo**, con dos partes independientes
   que se guardan en la base de datos: el patrón (`CanvasBackground`) y el
   tema (`CanvasTheme`: claro u oscuro).
2. El papel **no forma parte de los trazos**. Se pinta en una vista situada
   debajo de un `PKCanvasView` transparente, como un color con patrón
   repetido (`CanvasBackgroundPattern`).
3. **El aspecto del lienzo lo fija el tema del dibujo**, no el sistema:
   `overrideUserInterfaceStyle` en el lienzo y `colorUserInterfaceStyle` en
   la paleta. Al exportar se usa ese mismo aspecto.
4. El resto de la app (galería, barras, alertas) **sigue el modo del
   sistema**: se quita el modo claro forzado.
5. Las columnas nuevas de `DrawingRecord` son **opcionales**, para que
   SwiftData migre sola las bases de datos ya instaladas
   ([ADR 0007](0007-swiftdata.md)).

Esta decisión reemplaza solo el punto "el lienzo se fuerza a modo claro" del
ADR 0005; el resto de ese ADR sigue vigente.

## Alternativas consideradas

- **Lienzo oscuro cuando el iPad está en modo oscuro:** es lo que hace Notas,
  pero el mismo dibujo cambiaría de aspecto solo, y no se podría tener un
  dibujo oscuro y otro claro a la vez.
- **Dibujar el patrón dentro del `PKDrawing`** (como trazos): saldría en la
  exportación sin trabajo extra, pero el borrador lo borraría y cambiar de
  papel obligaría a reescribir el dibujo.
- **Un solo ajuste con ocho valores** (cuadrícula clara, cuadrícula oscura…):
  menos tipos, pero mezcla dos ideas y complica el menú.
- **Guardar el papel en `UserDefaults`** como preferencia global: más simple,
  pero el papel es parte de cada dibujo.

## Consecuencias

- Cada dibujo se ve siempre igual, sea cual sea el modo del iPad, y la
  imagen exportada coincide con la pantalla.
- Cambiar a papel oscuro **no modifica los trazos**: es PencilKit quien
  muestra la tinta adaptada. Un trazo negro se ve blanco en papel oscuro y
  vuelve a verse negro en papel claro. Los colores intermedios también se
  ajustan; es el comportamiento estándar de PencilKit.
- El lienzo transparente obliga al sistema a componer dos capas; el coste es
  inapreciable en un iPad, pero existe.
- El patrón no se desplaza con el contenido. Cuando se añada zoom y
  desplazamiento habrá que mover el papel junto con el lienzo.
- Las miniaturas de la galería van sobre papel liso (claro u oscuro), sin
  patrón.
