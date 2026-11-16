# 0012. Portada del cuaderno como tapa diseñada

- **Estado:** Aceptada
- **Fecha:** 2026-11-16

## Contexto

Con los cuadernos ([ADR 0010](0010-cuadernos-y-hojas.md)), la galería
mostraba como portada la miniatura de la primera hoja. Eso mezclaba dos
cosas: la primera hoja era a la vez contenido y carátula, y un cuaderno
recién creado no tenía portada (hoja en blanco).

Se quiere que la portada sea una función propia y que las hojas sirvan solo
para dibujar.

## Decisión

1. La portada es una **tapa diseñada**: `NotebookCover`, con un color
   (`CoverColor`, ocho opciones) y un estilo (`CoverStyle`: lisa, etiqueta,
   lomo). No es una hoja ni una imagen.
2. **Se pinta, no se guarda como imagen.** `NotebookCoverView` dibuja la
   tapa con el título del cuaderno encima. La tarjeta de la galería y la
   vista previa del editor usan esa misma vista.
3. Se cambia desde la galería: mantener pulsado el cuaderno, "Cambiar
   portada". El editor trabaja sobre una copia y solo guarda al confirmar.
4. **Cada cuaderno nuevo recibe el siguiente color** de la lista, para que
   la galería no sea uniforme. Los cuadernos que ya existían quedan con la
   tapa estándar (azul, etiqueta).
5. **Base de datos:** dos columnas opcionales en `NotebookRecord`
   (`coverColorRaw`, `coverStyleRaw`), migración ligera. Un valor vacío o
   desconocido se lee como la tapa estándar.
6. `NotebookSummary` deja de llevar la miniatura de la primera hoja y lleva
   la tapa.

## Alternativas consideradas

- **Tapa dibujada** (un lienzo aparte antes de la hoja 1): más libre, pero
  es otro dibujo que guardar, con su propio lienzo y autoguardado, y un
  cuaderno nuevo seguiría sin portada hasta dibujarla.
- **Elegir una hoja como portada:** poco código, pero la portada seguiría
  siendo contenido.
- **Guardar la tapa como imagen:** permitiría fotos o texturas, pero ocupa
  más y habría que regenerarla al renombrar el cuaderno.
- **Color libre** (selector de color del sistema): más opciones, pero algunos
  colores dejarían el título ilegible. Una lista corta de tonos probados lo
  evita.
- **Guardar el color como componentes RGB:** ata la base de datos a un tono
  concreto. Guardando el nombre (`"red"`), el tono se puede ajustar en la
  interfaz sin migrar nada.

## Consecuencias

- Todo cuaderno tiene portada desde que se crea, y el título va en la tapa.
- La galería ya no enseña el contenido del cuaderno: para ver qué hay dentro
  hay que abrirlo.
- Las miniaturas de las hojas se siguen generando al guardar, pero ahora
  ninguna pantalla las usa. Se conservan para una futura vista de "todas las
  hojas"; si esa vista no llega, conviene quitarlas.
- Añadir un color o un estilo es añadir un caso al `enum` y su aspecto en
  Presentation; quitar uno deja a los cuadernos que lo usaban con la tapa
  estándar.
- El aspecto de las tapas no tiene pruebas automáticas: las pruebas de
  interfaz comprueban que la elección se guarda, no cómo se ve.
