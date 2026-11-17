# 0013. Textos e imágenes en una capa bajo los trazos

- **Estado:** Aceptada
- **Fecha:** 2026-11-16

## Contexto

Se quiere poder escribir texto con el teclado, pegar texto y pegar imágenes
en una hoja, y después **rayar encima** con el Pencil (anotar una foto,
subrayar un texto).

PencilKit solo sabe de trazos: un `PKDrawing` no puede contener texto ni
imágenes, y `PKCanvasView` no permite añadir contenido propio dentro. Además
el lienzo ocupa toda la pantalla y recibe todos los toques.

## Decisión

1. **Nueva entidad `PageElement`**: un texto o una imagen con su posición y
   tamaño en coordenadas de la hoja. Pertenece a una hoja (`pageID`).
2. **Capa propia bajo los trazos.** `PencilKitCanvas` apila papel,
   `PageElementsLayer` (vistas de UIKit) y el lienzo transparente. La capa
   sigue el zoom y el desplazamiento igual que el papel
   ([ADR 0009](0009-zoom-y-tamano-de-hoja.md)).
3. **Mover es un modo aparte** ("Mover texto e imágenes"). Mientras dura, el
   lienzo no atiende toques: se arrastra para mover, se pellizca una imagen
   para cambiar su tamaño y una barra ofrece "Editar texto", "Eliminar" y
   "Listo". Al insertar algo se entra solo en ese modo, con el elemento
   seleccionado.
4. **Se insertan desde el menú "Insertar"**: "Cuadro de texto" abre un editor
   con el teclado; "Pegar" toma del portapapeles una imagen o, si no hay, un
   texto. Lo nuevo aparece en el centro de lo que se está viendo.
5. **El portapapeles es un puerto** (`Clipboard`). La implementación real
   reduce las imágenes a 2048 px de lado como máximo.
6. **Persistencia:** tabla nueva `PageElementRecord` (migración ligera). Cada
   cambio se guarda al momento. Borrar una hoja o un cuaderno borra sus
   elementos.
7. **Exportar** (Fotos, imagen, PDF, miniatura) dibuja papel, elementos y
   trazos, en ese orden. Una hoja con solo texto ya no cuenta como vacía.
8. Para hacer sitio en la barra, "Dibujar con el dedo" pasa al menú "Más".

## Alternativas consideradas

- **Convertir el texto en trazos** (dibujar las letras como `PKStroke`): todo
  sería un único dibujo, pero el texto dejaría de ser editable y el borrador
  lo borraría.
- **Elementos encima de los trazos:** más fácil de tocar, pero no se podría
  dibujar sobre una imagen, que es el objetivo.
- **Sin modo aparte, distinguiendo el gesto** (por ejemplo, pulsación larga
  sobre un elemento): más directo, pero compite con los gestos de PencilKit
  (dibujar con el dedo, desplazar, ampliar) y es difícil de acertar sin
  poder probarlo en un dispositivo.
- **Editar el texto directamente sobre la hoja** (un `UITextView` por
  cuadro): más natural, pero el teclado tapa media pantalla y hay que mover
  la hoja; un editor en una hoja aparte es más simple y predecible.
- **`PasteButton` de SwiftUI:** evita el aviso de permiso de iOS, pero no se
  puede poner como una opción más dentro de un menú con el mismo aspecto.
- **Selector de fotos del sistema** para insertar imágenes: útil, y se puede
  añadir después sobre el mismo `AddImageElementUseCase`; lo pedido fue pegar.
- **Guardar los elementos dentro de la hoja** (una columna con todos en
  JSON): menos tablas, pero cada movimiento reescribiría todas las imágenes.

## Consecuencias

- Se puede anotar sobre texto e imágenes, y ambos salen al exportar.
- Los elementos **no entran en el historial de deshacer**: mover o eliminar
  un texto no se deshace con el botón (que es de PencilKit). Eliminar es
  inmediato y definitivo.
- En el modo de mover no se puede dibujar, ampliar ni desplazar la hoja.
- Los cuadros de texto tienen ancho y tipografía fijos (320 puntos, 20 pt);
  el alto se ajusta al contenido. No hay negrita, tamaños ni colores.
- Las imágenes se guardan como PNG en la base de datos (almacenamiento
  externo). Muchas imágenes grandes harán crecer el espacio que ocupa la app.
- La primera vez que se pega, iOS puede mostrar su aviso de permiso para leer
  el portapapeles.
- "Borrar todo" y "Suavizar trazos" solo afectan a los trazos.
- La capa de UIKit y los gestos no tienen pruebas unitarias; los cubren
  pruebas de interfaz (insertar, arrastrar, editar, eliminar, pegar, reabrir
  la hoja, compartir). **Pegar imágenes y el pellizco para cambiar su tamaño
  solo se pueden comprobar en un iPad real.**
