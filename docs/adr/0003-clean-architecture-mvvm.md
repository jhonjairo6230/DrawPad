# 0003. Clean Architecture con MVVM

- **Estado:** Aceptada
- **Fecha:** 2026-11-14

## Contexto

La app es pequeña (una pantalla), pero su objetivo principal es **servir de
material de estudio**. Se quiere un ejemplo real de código limpio: capas
claras, dependencias invertidas y lógica que se pueda probar sin iPad ni
PencilKit.

## Decisión

Organizar el código en cuatro capas, con dependencias solo hacia dentro:

- **Domain:** entidades, errores, protocolos y casos de uso. Solo `Foundation`.
- **Data:** implementaciones de los protocolos (archivo, Fotos).
- **Presentation:** SwiftUI con **MVVM**. El ViewModel usa `@Observable` y
  habla con el lienzo a través del protocolo `DrawingCanvas`.
- **App:** `AppContainer` como *composition root* con inyección de
  dependencias manual.

Todo vive en un único target de Xcode; las capas son carpetas. El detalle está
en [arquitectura.md](../arquitectura.md).

## Alternativas consideradas

- **Todo en la vista** (lo típico en un ejemplo de SwiftUI): cabría en 80
  líneas, pero no enseña nada de arquitectura ni se puede probar.
- **MVVM sin capa de dominio:** suficiente para esta app, pero el ViewModel
  acabaría conociendo archivos y Fotos.
- **Un paquete Swift por capa:** el compilador impediría importar lo que no
  toca. Es lo más estricto, pero complica el proyecto y la compilación en CI
  para una app de este tamaño.
- **TCA (The Composable Architecture):** potente, pero añade una dependencia
  externa y muchos conceptos nuevos a la vez.
- **VIPER:** pensado para UIKit y con demasiadas piezas por pantalla.

## Consecuencias

- La lógica (autoguardado, exportación, errores) tiene pruebas unitarias con
  dobles, sin PencilKit.
- Cambiar el almacenamiento o el motor de dibujo afecta a una sola capa.
- Hay más archivos y más indirección de la que una app tan pequeña necesita.
  Es un coste asumido a cambio del valor didáctico.
- Al ser carpetas y no módulos, **nada impide** saltarse las reglas de
  dependencia: hay que respetarlas por disciplina (están en `AGENTS.md`).
