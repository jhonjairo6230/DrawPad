# DrawPad

App de dibujo básica para iPad con Apple Pencil, hecha para **aprender**:
se compila **sin Mac** (en GitHub Actions) y se instala en un iPad propio
desde Windows. No está pensada para publicarse en el App Store.

[![Compilar IPA](https://github.com/jhonjairo6230/DrawPad/actions/workflows/build.yml/badge.svg)](https://github.com/jhonjairo6230/DrawPad/actions/workflows/build.yml)

## Qué hace

- Lienzo con **PencilKit**: presión, inclinación y la paleta de herramientas
  de Apple (lápiz, rotulador, borrador, regla, colores, grosor).
- **Cuadernos**: cada cuaderno agrupa sus hojas. Se crean, renombran y
  eliminan desde la galería.
- **Portada** de cada cuaderno: tres estilos de tapa y ocho colores.
- **Hojas a demanda**: dentro de un cuaderno se añaden hojas, se pasa de una
  a otra y se eliminan.
- **Base de datos local** (SwiftData): todo se guarda en el iPad, con
  autoguardado mientras dibujas.
- **Papel de fondo** por hoja: blanco, cuadrícula, líneas o puntos, en
  claro u **oscuro**. La app sigue el modo claro/oscuro del iPad.
- **Zoom** con pellizco (hasta 4×) y desplazamiento por la hoja.
- **Texto e imágenes** en la hoja: cuadros de texto escritos con el teclado
  y texto o imágenes pegados del portapapeles, para dibujar encima.
- **Suavizar trazos**: quita el temblor de lo dibujado (se puede deshacer).
- Deshacer y rehacer.
- **Dibujar con el dedo** (opcional; por defecto solo dibuja el Pencil).
- Borrar todo, con confirmación.
- **Guardar en Fotos** y **compartir** como imagen (PNG) o PDF: AirDrop,
  Archivos, Mensajes, imprimir…

Requiere iPadOS 17 o posterior.

## Instalar en tu iPad

1. Ve a [Actions → Compilar IPA](https://github.com/jhonjairo6230/DrawPad/actions/workflows/build.yml)
   y descarga el artefacto **DrawPad-ipa** de la última ejecución en verde.
2. Fírmalo e instálalo con [Sideloadly](https://sideloadly.io) desde Windows.

Guía completa: [docs/compilacion-e-instalacion.md](docs/compilacion-e-instalacion.md).

## Cómo está hecho

- **SwiftUI + PencilKit + SwiftData**, Swift 5, iPadOS 17.
- **Clean Architecture + MVVM**: `Domain`, `Data`, `Presentation`, `App`.
- **XcodeGen**: el proyecto de Xcode se genera desde `project.yml`.
- **GitHub Actions**: pruebas en simulador y `.ipa` sin firmar en cada push.
- **Git Flow**: `main`, `develop`, `feature/`, `release/`, `backport/`, `hotfix/`.

## Documentación

Todo está en [`docs/`](docs/README.md):

- [Compilación e instalación](docs/compilacion-e-instalacion.md)
- [Arquitectura](docs/arquitectura.md) (capas, clases y diagramas de secuencia)
- [Conceptos de iOS](docs/conceptos-ios.md)
- [Flujo de trabajo](docs/flujo-de-trabajo.md)
- [Decisiones de arquitectura (ADR)](docs/adr/README.md)
