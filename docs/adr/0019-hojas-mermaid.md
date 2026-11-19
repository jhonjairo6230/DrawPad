# 0019. Diagramas Mermaid con WebKit, sin conexión

- **Estado:** Aceptada
- **Fecha:** 2026-11-19

## Contexto

Se quiere escribir un diagrama en sintaxis [Mermaid](https://mermaid.js.org)
(flowchart, secuencia, clases…) y que se dibuje en la hoja, para anotarlo
encima con el Pencil y exportarlo con el resto.

Mermaid es una librería de JavaScript. Una investigación previa comparó:
ejecutarla en WebKit dentro de la app, servicios en línea (mermaid.ink,
Kroki) y librerías nativas en Swift.

## Decisión

1. **Mermaid dentro de la app**, ejecutado en un `WKWebView` **sin
   conexión**: `mermaid.min.js` va en `Resources/Mermaid` y se inyecta como
   `WKUserScript`; la página se carga desde texto, con datos no persistentes.
   El texto del usuario no sale del dispositivo.
2. **Versión fijada: 11.17.2.** La 12 exige Safari 17.4 (usa
   `Object.groupBy`) y la app admite iPadOS 17.0. Se incluye su licencia (MIT).
3. **Nuevo tipo de elemento** `.mermaid(MermaidDiagram)` con el **texto** (lo
   que se edita) y la **imagen** PNG ya dibujada (lo que se muestra y se
   exporta). Va bajo los trazos, se mueve, se amplía y se une con flechas
   como los demás.
4. **La imagen sale de la vista previa visible** del editor: WebKit da un PDF
   del recuadro del diagrama, que se convierte en PNG; si falla, una captura
   de lo visible. Capturar una vista web fuera de pantalla no es fiable.
5. **El dominio no conoce WebKit**: recibe el texto y el PNG ya hechos
   (`AddMermaidElementUseCase`, `UpdateMermaidElementUseCase`). El motor está
   detrás del puerto de presentación `MermaidPreview`, como el lienzo detrás
   de `DrawingCanvas`.
6. **Editor**: texto arriba, vista previa abajo; se vuelve a dibujar cuando
   se deja de teclear 0,4 s; los errores de Mermaid se muestran tal cual. Un
   diagrama nuevo empieza con un ejemplo de arquitectura. Se dibuja con el
   tema de la hoja (oscuro en papel oscuro).
7. **Base de datos y archivo `.drawpad`**: tipo `"mermaid"` que reutiliza las
   columnas de texto e imagen. No hace falta migración.

## Alternativas consideradas

- **mermaid.ink o Kroki:** sin JavaScript en la app, pero el texto viaja a un
  servidor de terceros y no funciona sin conexión.
- **Librerías nativas en Swift** (BeautifulMermaid, swift-mermaid): sin
  WebKit, pero son jóvenes y no cubren todos los tipos de diagrama. Al estar
  el motor detrás de `MermaidPreview`, se podrían probar más adelante sin
  tocar el resto.
- **Mermaid 12:** más nueva, pero obligaría a subir el mínimo a iPadOS 17.4.
- **Guardar solo el texto** y dibujar al abrir la hoja: menos datos, pero
  abrir una hoja exigiría WebKit y tardaría; tampoco se vería en el iPhone
  sin dibujar.
- **Dibujar el diagrama como trazos o figuras:** se podría editar con el
  Pencil, pero habría que reimplementar el diseño automático de Mermaid.

## Consecuencias

- Se pueden hacer diagramas complejos escribiendo texto, sin red.
- La app pesa unos 3,6 MB más (el JavaScript).
- Abrir el editor crea una vista web: tarda un momento la primera vez y usa
  memoria mientras está abierto.
- **El diagrama en la hoja es una imagen**: al ampliar mucho se pixela, y no
  cambia si luego se pasa la hoja a papel oscuro (hay que volver a guardarlo).
- Cambiar de versión de Mermaid es reemplazar el archivo, revisar que
  funcione en iPadOS 17.0 y escribir un ADR nuevo.
- El resultado visual (tamaño, nitidez, colores) y la captura a imagen solo
  se pueden juzgar en el iPad; el CI prueba con WebKit y Mermaid reales que un
  diagrama se dibuja, da imagen y que los errores se muestran.
