# Documentación de DrawPad

Orden sugerido para estudiar el proyecto:

| # | Documento | Qué responde |
| - | --------- | ------------ |
| 1 | [Compilación e instalación](compilacion-e-instalacion.md) | ¿Cómo llega el código al iPad sin un Mac? |
| 2 | [Arquitectura](arquitectura.md) | ¿Cómo está organizado el código y cómo fluye cada acción? |
| 3 | [Conceptos de iOS](conceptos-ios.md) | ¿Qué es cada pieza de Swift, SwiftUI y PencilKit que aparece? |
| 4 | [Flujo de trabajo](flujo-de-trabajo.md) | ¿Cómo se usan las ramas y las versiones? |
| 5 | [Decisiones (ADR)](adr/README.md) | ¿Por qué se hizo así y qué se descartó? |

Además, cada tipo del código tiene un comentario `///` que explica su papel.
Un buen recorrido de lectura:

1. `DrawPad/App/DrawPadApp.swift` y `AppContainer.swift` — cómo se monta todo.
2. `DrawPad/Domain/` — las reglas, sin frameworks.
3. `DrawPad/Presentation/Canvas/CanvasViewModel.swift` — la lógica de pantalla.
4. `DrawPad/Presentation/Canvas/PencilKitCanvas.swift` — PencilKit.
5. `DrawPad/Data/` — archivo y Fotos.
6. `DrawPadTests/` — cómo se prueba cada capa con dobles.
