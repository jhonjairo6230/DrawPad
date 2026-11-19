# 0015. Portada dibujada a mano

- **Estado:** Aceptada
- **Fecha:** 2026-11-19

## Contexto

La portada de un cuaderno es una tapa diseñada: color y estilo, con el título
encima ([ADR 0012](0012-portada-disenada.md)). Se quiere poder ir más allá y
**dibujar la portada con el Pencil**, sin perder el color de la tapa ni el
título.

## Decisión

1. Nuevo estilo de tapa **"Dibujo"** (`CoverStyle.drawn`): el color de la
   tapa, encima el dibujo y el título en una franja abajo.
2. `NotebookCover` gana un dibujo opcional, `CoverDrawing`, con dos datos:
   - los **trazos** (`PKDrawing` serializado), para seguir editándolo;
   - una **imagen PNG transparente**, para mostrarlo en la galería.
3. El dibujo **se conserva aunque se cambie a otro estilo**: se puede probar
   "Lisa" y volver a "Dibujo" sin perderlo. Se quita con "Quitar dibujo".
4. Se dibuja en una **pantalla completa** con un lienzo de **tamaño fijo**
   (420 × 560 puntos, proporción 3:4), con el color de la tapa como papel.
   Reutiliza `PencilKitCanvas` con dos operaciones nuevas en `DrawingCanvas`:
   pintar el papel con un color de tapa y exportar solo los trazos.
5. La pantalla de dibujo **no guarda**: devuelve el dibujo al editor de
   portada, que sigue trabajando sobre una copia hasta "Guardar".
6. **Base de datos:** dos columnas opcionales en `NotebookRecord`
   (`coverStrokesData`, `coverImageData`, almacenamiento externo). Migración
   ligera.

## Alternativas consideradas

- **Guardar solo los trazos** y dibujar la imagen al mostrar la galería:
  menos datos, pero cada tarjeta necesitaría PencilKit para pintarse.
- **Guardar solo la imagen:** no se podría volver a editar el dibujo.
- **Imagen con el color incluido:** cambiar el color obligaría a redibujar.
- **Lienzo del tamaño de la pantalla:** el dibujo cambiaría de posición y de
  proporción según la orientación con la que se edite.
- **Dibujar en el sitio de la tapa, dentro del editor:** la vista previa es
  pequeña para dibujar con detalle.

## Consecuencias

- La galería muestra el dibujo sin coste extra de PencilKit.
- El título siempre se ve en la franja, aunque el dibujo lo tape en parte.
- Cada cuaderno con portada dibujada guarda dos copias del dibujo (trazos e
  imagen). Son pequeñas, pero ocupan espacio.
- Si al editar se dibuja fuera del área visible (por ejemplo, con zoom), la
  imagen pierde la proporción 3:4 y se recorta al mostrarla.
- El aspecto del dibujo en la tapa solo se puede comprobar en el iPad; las
  pruebas de interfaz comprueban que se dibuja, se guarda y se conserva.
