# Documentación de DrawPad

Orden sugerido para estudiar el proyecto:

| # | Documento | Qué responde |
| - | --------- | ------------ |
| 1 | [Compilación e instalación](compilacion-e-instalacion.md) | ¿Cómo llega el código al iPad sin un Mac? |
| 2 | [Arquitectura](arquitectura.md) | ¿Cómo está organizado el código y cómo fluye cada acción? |
| 3 | [Conceptos de iOS](conceptos-ios.md) | ¿Qué es cada pieza de Swift, SwiftUI, PencilKit, SwiftData y WebKit que aparece? |
| 4 | [Flujo de trabajo](flujo-de-trabajo.md) | ¿Cómo se usan las ramas y las versiones? |
| 5 | [Decisiones (ADR)](adr/README.md) | ¿Por qué se hizo así y qué se descartó? |

Además, cada tipo del código tiene un comentario `///` que explica su papel.
Un buen recorrido de lectura:

1. `DrawPad/App/DrawPadApp.swift` y `AppContainer.swift` — cómo se monta todo.
2. `DrawPad/Domain/` — las reglas, sin frameworks.
3. `DrawPad/Presentation/Gallery/GalleryViewModel.swift` y
   `DrawPad/Presentation/Canvas/CanvasViewModel.swift` — la lógica de pantalla.
4. `DrawPad/Presentation/Canvas/PencilKitCanvas.swift` — PencilKit.
5. `DrawPad/Presentation/Notebook/NotebookViewModel.swift` y
   `AppContainer.makeSession` — cómo un cuaderno abre cada hoja según su
   tipo (dibujo o Markdown).
6. `DrawPad/Presentation/Mermaid/WebKitMermaidPreview.swift` y
   `Presentation/Markdown/WebKitMarkdownRenderer.swift` — JavaScript
   (Mermaid, marked) dentro de WebKit, sin red.
7. `DrawPad/Presentation/Common/EditingCapability.swift` — qué se puede
   cambiar en el iPad y en el iPhone.
8. `DrawPad/Data/` — base de datos (SwiftData), archivos `.drawpad` y Fotos.
9. `DrawPadTests/` y `DrawPadUITests/` — cómo se prueba cada capa con dobles,
   y la app real en el simulador (también en modo iPhone).
