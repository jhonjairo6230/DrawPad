# Registro de decisiones de arquitectura (ADR)

Un **ADR** (*Architecture Decision Record*) es una nota corta que explica una
decisión importante: qué problema había, qué se eligió, qué se descartó y qué
consecuencias tiene. Sirve para que, al volver al proyecto meses después, se
entienda **por qué** el código es como es.

| N.º | Decisión | Estado |
| --- | -------- | ------ |
| [0001](0001-registrar-decisiones-con-adr.md) | Registrar las decisiones con ADR | Aceptada |
| [0002](0002-git-flow.md) | Usar Git Flow como flujo de ramas | Aceptada |
| [0003](0003-clean-architecture-mvvm.md) | Clean Architecture con MVVM | Aceptada |
| [0004](0004-compilar-sin-mac.md) | Compilar sin Mac: GitHub Actions, XcodeGen e IPA sin firmar | Aceptada |
| [0005](0005-pencilkit.md) | PencilKit como motor de dibujo | Aceptada |
| [0006](0006-documentacion.md) | Documentar con Markdown + Mermaid y comentarios DocC | Aceptada |
| [0007](0007-swiftdata.md) | SwiftData como base de datos local | Aceptada |
| [0008](0008-papel-y-tema-por-dibujo.md) | Papel de fondo y tema claro/oscuro por dibujo | Aceptada |
| [0009](0009-zoom-y-tamano-de-hoja.md) | Zoom y tamaño de la hoja | Aceptada |
| [0010](0010-cuadernos-y-hojas.md) | Cuadernos con hojas | Aceptada |

## Cómo añadir un ADR

1. Copia [`0000-plantilla.md`](0000-plantilla.md) con el siguiente número y un
   nombre corto: `0007-nombre-de-la-decision.md`.
2. Rellénalo y añádelo a la tabla de arriba.
3. Un ADR aceptado **no se reescribe**. Si la decisión cambia, se crea uno
   nuevo y el anterior pasa a estado *Reemplazada por 00NN*.
