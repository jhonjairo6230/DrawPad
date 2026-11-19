# 0016. Figuras de diagrama unidas con flechas

- **Estado:** Aceptada
- **Fecha:** 2026-11-19

## Contexto

Se quiere hacer **diagramas de arquitectura de software** al estilo de
Excalidraw: figuras predefinidas (cuadrado, círculo, rombo y cilindro), unirlas
con flechas o líneas, y girar el cilindro para que represente una base de
datos (de pie) o una cola de mensajes (acostado).

La hoja ya tiene elementos colocados bajo los trazos (textos e imágenes,
[ADR 0013](0013-textos-e-imagenes.md)), con un modo aparte para moverlos.

## Decisión

1. **Las figuras son un tipo más de `PageElement`** (`DiagramShape`): tipo,
   texto centrado (opcional) y giro. Viven en la misma capa y el mismo modo
   que textos e imágenes, se insertan desde "Insertar" → "Figura" y se
   amplían con un pellizco.
2. **Giro de 90 en 90°** ("Girar"): se guarda en cuartos de vuelta y el
   marco intercambia ancho y alto alrededor del centro. El cilindro se dibuja
   de pie o acostado según el giro.
3. **Las conexiones también son `PageElement`** (`Connector`), pero **solo
   guardan qué dos elementos unen** y si es flecha o línea. Se dibujan de
   borde a borde, calculadas en cada repintado a partir de los marcos
   actuales: siguen a las figuras al moverlas, girarlas o cambiarlas de
   tamaño, también durante el arrastre.
4. **Para unir**: con un elemento seleccionado, "Conectar" → "Con flecha" o
   "Con línea", y tocar el destino. Tocar el fondo o el mismo elemento
   cancela. Unir el mismo par otra vez cambia el estilo en lugar de duplicar.
   Una conexión se selecciona tocando cerca de la línea.
5. **Regla de dominio:** quitar un elemento quita las conexiones que lo
   tocan (`DeleteElementUseCase`).
6. Las cuentas (borde de caja, elipse y rombo; puntas de flecha; distancia de
   un toque a una línea) están en `DiagramGeometry`, sin UIKit, con pruebas.
   El dibujo (`DiagramRenderer`) es el mismo en pantalla y al exportar.
7. **Base de datos:** columnas opcionales nuevas en `PageElementRecord`
   (tipo de figura, giro, extremos y estilo de la conexión). Migración ligera.

## Alternativas consideradas

- **Giro libre con dos dedos:** más flexible, pero las flechas tendrían que
  cortar figuras inclinadas y el texto giraría con ellas; para diagramas de
  arquitectura bastan los 90°.
- **Flechas libres** (de un punto a otro, sin unirlas): más simples, pero
  habría que recolocarlas a mano cada vez que se mueve una figura.
- **Conexiones con puntos de anclaje** (arriba, abajo, izquierda, derecha):
  más ordenado en diagramas grandes, pero más interfaz; de borde a borde en
  dirección al centro es lo que hace Excalidraw por defecto.
- **Tabla aparte para las conexiones:** más limpio en la base de datos, pero
  habría que repetir listado, borrado en cascada y migración; como
  `PageElement` reutilizan todo eso.
- **Dibujar las figuras como trazos de PencilKit:** se borrarían con el
  borrador y no se podrían mover, girar ni unir.

## Consecuencias

- Se pueden hacer diagramas de cajas y flechas y anotarlos a mano encima.
- Las conexiones cortan el cilindro como si fuera una caja: en las esquinas
  de un cilindro, la punta puede quedar un poco separada del borde curvo.
- Si dos figuras se tocan o se solapan, su conexión no se dibuja (no hay
  hueco), pero sigue guardada y reaparece al separarlas.
- No hay flechas curvas ni con codos, ni flechas sueltas sin figuras.
- Las conexiones no entran en el historial de deshacer, igual que el resto de
  elementos.
- El aspecto (grosor, puntas, cilindro acostado) y los gestos solo se pueden
  juzgar en el iPad; las pruebas de interfaz construyen un diagrama pequeño
  (insertar, mover, girar, poner texto, unir, reabrir).
