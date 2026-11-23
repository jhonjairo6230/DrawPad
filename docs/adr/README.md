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
| [0011](0011-suavizar-trazos.md) | Suavizar trazos con un algoritmo propio | Aceptada |
| [0012](0012-portada-disenada.md) | Portada del cuaderno como tapa diseñada | Aceptada |
| [0013](0013-textos-e-imagenes.md) | Textos e imágenes en una capa bajo los trazos | Aceptada |
| [0014](0014-ipa-y-pruebas-en-paralelo.md) | IPA y pruebas en paralelo en el workflow | Aceptada; cambiada por 0023 |
| [0015](0015-portada-dibujada.md) | Portada dibujada a mano | Aceptada |
| [0016](0016-figuras-de-diagrama.md) | Figuras de diagrama unidas con flechas | Aceptada |
| [0017](0017-exportar-importar-cuadernos.md) | Exportar e importar cuadernos en archivos `.drawpad` | Aceptada |
| [0018](0018-iphone-solo-lectura.md) | La app en el iPhone, en solo lectura | Aceptada; cambiada por 0021 y 0022 |
| [0019](0019-hojas-mermaid.md) | Diagramas Mermaid con WebKit, sin conexión | Aceptada |
| [0020](0020-hojas-markdown.md) | Hojas Markdown con marked y WebKit | Aceptada |
| [0021](0021-markdown-en-iphone.md) | Escribir hojas Markdown en el iPhone | Aceptada |
| [0022](0022-diagramas-en-iphone.md) | Diagramas en el iPhone, sin trazos | Aceptada |
| [0023](0023-ipa-solo-al-fusionar.md) | El `.ipa` solo al fusionar en `develop` o `main` | Aceptada |

## Cómo añadir un ADR

1. Copia [`0000-plantilla.md`](0000-plantilla.md) con el siguiente número y un
   nombre corto: `0007-nombre-de-la-decision.md`.
2. Rellénalo y añádelo a la tabla de arriba.
3. Un ADR aceptado **no se reescribe**. Si la decisión cambia, se crea uno
   nuevo y el anterior pasa a estado *Reemplazada por 00NN*.
