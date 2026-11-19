# 0020. Hojas Markdown con marked y WebKit

- **Estado:** Aceptada
- **Fecha:** 2026-11-19

## Contexto

Además de dibujar, se quiere guardar texto largo con formato en un cuaderno:
un spec, una documentación, notas técnicas. Markdown es el formato más
cómodo para escribirlo y el que ya se usa fuera de la app (README, docs).

Los cuadros de texto de la hoja ([ADR 0013](0013-textos-e-imagenes.md)) son
para rótulos cortos sobre un dibujo, no para documentos de varias pantallas.

## Decisión

1. **Un tipo de hoja nuevo**, no un elemento: `Drawing.kind` es
   `PageKind.drawing` o `.markdown`. Una hoja Markdown ocupa toda la página,
   tiene su texto en `Drawing.markdown` y no tiene trazos ni elementos. Se
   pasa de hoja, se borra y se exporta con el cuaderno como cualquier otra.
2. **Se escribe en texto plano y se lee formateado**: dos modos, *Ver* y
   *Editar*. El texto se guarda solo, un segundo después de la última tecla y
   al salir de la hoja o de la app, como el autoguardado del lienzo.
3. **Formato con [marked](https://marked.js.org) 18.2.1** (JavaScript, MIT)
   en un `WKWebView` **sin conexión**, igual que Mermaid
   ([ADR 0019](0019-hojas-mermaid.md)): el archivo va en `Resources/Markdown`
   y se inyecta como `WKUserScript`. Sabe Markdown de GitHub: tablas, listas
   de tareas, tachado, bloques de código.
4. **Los bloques ` ```mermaid ` se dibujan** como diagramas con el Mermaid que
   ya trae la app. Si uno tiene un error, se muestra el error en su lugar y
   el resto del documento sigue.
5. **El HTML del documento no se ejecuta**: marked lo muestra como texto
   (`renderer.html` lo escapa). Los enlaces se abren en Safari, fuera de la
   app.
6. **Nueva hoja → menú** con *Hoja de dibujo*, *Hoja Markdown* (con una
   plantilla de spec) e *Importar Markdown…* (un `.md` de Archivos / iCloud
   Drive). Cada hoja Markdown se puede **exportar como `.md`**.
7. **Base de datos**: dos columnas opcionales en `DrawingRecord`
   (`pageKindRaw`, `markdownText`); `nil` es una hoja de dibujo, así las ya
   guardadas siguen igual sin migración ([ADR 0007](0007-swiftdata.md)).
8. **Archivo `.drawpad` versión 2**: cada hoja lleva `kind` y `markdown`
   opcionales. Un archivo de versión 1 se lee igual (todo hojas de dibujo).
9. **En el iPhone se lee** el documento formateado, sin modo *Editar*
   ([ADR 0018](0018-iphone-solo-lectura.md)).

## Alternativas consideradas

- **`AttributedString(markdown:)` de Foundation:** nativo y sin WebKit, pero
  solo entiende Markdown en línea (negrita, enlaces): ni títulos, ni tablas,
  ni listas de tareas, ni diagramas.
- **Librerías nativas en Swift** (swift-markdown + vistas propias): habría que
  dibujar cada tipo de bloque en SwiftUI y no dibujarían Mermaid.
- **Editor con formato en vivo** (WYSIWYG): más cómodo para unos, pero mucho
  más complejo, y el texto ya no sería el Markdown tal cual se escribe.
- **Markdown como elemento de la hoja de dibujo:** permitiría anotarlo con el
  Pencil, pero un documento largo no cabe en una hoja de tamaño fijo.

## Consecuencias

- Los specs y la documentación viven junto a los dibujos del mismo cuaderno
  y viajan con él al iPhone.
- La app pesa unos 50 KB más (marked); Mermaid ya estaba.
- Abrir una hoja Markdown crea una vista web: tarda un momento la primera vez.
- Sobre una hoja Markdown no se dibuja con el Pencil.
- Cambiar de versión de marked es reemplazar el archivo y escribir un ADR
  nuevo; el CI comprueba con WebKit real que se formatean títulos, tablas,
  tareas y diagramas, y que no se ejecuta HTML del documento.
