# 0009. Zoom y tamaño de la hoja

- **Estado:** Aceptada
- **Fecha:** 2026-11-15

## Contexto

Se quiere poder ampliar el dibujo con un pellizco para trabajar los detalles
y moverse por él. Hay que decidir cuánto mide la hoja, qué pasa con el papel
de fondo (que vive en una vista aparte, ver
[ADR 0008](0008-papel-y-tema-por-dibujo.md)) y si el zoom se guarda.

Los trazos se guardan en coordenadas de pantalla del momento en que se
dibujaron. Un dibujo hecho con el iPad en horizontal tiene trazos que, en
vertical, quedan fuera de la pantalla.

## Decisión

1. Se usa el zoom propio de `PKCanvasView` (es un `UIScrollView`): de **1×
   a 4×**. No se permite alejar por debajo de 1×.
2. **La hoja mide lo que la pantalla y crece si hay trazos más allá**, para
   que siempre se pueda llegar a ellos desplazándose. No hay un tamaño de
   página fijo.
3. **El papel acompaña a los trazos**: en cada desplazamiento o cambio de
   zoom se recoloca y escala la vista del papel.
4. **El zoom no se guarda** ni pasa por el dominio o el ViewModel: es estado
   de la vista. Cada vez que se abre un dibujo empieza en 1×.
5. Las cuentas están en `CanvasGeometry`, un tipo sin UIKit con pruebas
   unitarias.
6. **Exportar usa la hoja completa**, sin importar el zoom ni la parte
   visible.

## Alternativas consideradas

- **Hoja de tamaño fijo** (por ejemplo, A4) escalada para caber en pantalla:
  daría el mismo resultado en cualquier orientación y encajaría con la idea
  de "hojas de cuaderno", pero los dibujos ya guardados están en coordenadas
  de pantalla y habría que convertirlos.
- **Lienzo infinito:** cómodo para esquemas grandes, pero complica exportar
  (¿qué rectángulo?) y el papel de fondo.
- **Dibujar el papel dentro del lienzo** para que el zoom lo mueva solo:
  PencilKit no permite añadir contenido propio bajo los trazos.
- **Guardar zoom y posición por dibujo:** útil en dibujos muy grandes; aquí
  añade columnas a la base de datos para poco beneficio.

## Consecuencias

- Con el dedo desactivado (por defecto), un dedo desplaza y dos amplían; el
  Pencil dibuja. Con "Dibujar con el dedo", un dedo dibuja y hacen falta dos
  para desplazar y ampliar.
- El patrón del papel se escala como imagen: muy ampliado, las líneas se ven
  más gruesas y algo suaves.
- La hoja solo crece hacia la derecha y hacia abajo; no se puede añadir
  espacio a la izquierda o arriba del dibujo.
- La imagen exportada puede ser mayor que la pantalla si el dibujo se hizo en
  otra orientación.
- El comportamiento del zoom no tiene pruebas unitarias (es de UIKit); lo
  cubre una prueba de interfaz que pellizca, desplaza y dibuja.
