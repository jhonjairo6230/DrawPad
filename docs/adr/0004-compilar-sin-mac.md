# 0004. Compilar sin Mac: GitHub Actions, XcodeGen e IPA sin firmar

- **Estado:** Aceptada
- **Fecha:** 2026-11-14

## Contexto

Compilar una app de iOS exige Xcode, que solo existe para macOS. El autor
trabaja en Windows, no tiene Mac ni cuenta de pago de Apple Developer, y la
app es solo para su propio iPad.

Hay tres problemas que resolver:

1. **Dónde compilar** sin un Mac.
2. **Cómo mantener el proyecto de Xcode** sin poder abrir Xcode: el
   `.xcodeproj` es un formato interno difícil de editar a mano.
3. **Cómo firmar e instalar** sin cuenta de pago.

## Decisión

1. **Compilar en GitHub Actions** con un runner `macos-latest`, que ya trae
   Xcode. El repo es público, así que los minutos son gratuitos.
2. **Generar el proyecto con XcodeGen** a partir de `project.yml`. El
   `.xcodeproj` y el `Info.plist` no se guardan en git.
3. **Publicar un `.ipa` sin firmar** como artefacto del workflow, y **firmarlo
   e instalarlo con Sideloadly** desde Windows usando un Apple ID gratuito.
4. El mismo workflow **ejecuta las pruebas** en un simulador de iPad antes de
   generar el `.ipa`.

Guía práctica: [compilacion-e-instalacion.md](../compilacion-e-instalacion.md).

## Alternativas consideradas

- **Guardar el `.xcodeproj` en git:** imposible de crear o modificar con
  fiabilidad sin Xcode, y genera conflictos de fusión.
- **Swift Package + Swift Playgrounds en el iPad:** permite programar en el
  propio iPad, pero sin pruebas en CI ni control total del proyecto.
- **Firmar en el CI con cuenta de pago (99 USD/año):** la app duraría un año
  y se instalaría sin PC, pero es un gasto que no hace falta para probar.
- **AltStore en lugar de Sideloadly:** renueva la firma sola, pero necesita un
  servidor siempre encendido en el PC. Sigue siendo válida: usa el mismo
  `.ipa`.
- **Alquilar un Mac en la nube:** de pago y sin ventajas sobre el runner.
- **Flutter o React Native:** siguen necesitando Xcode para compilar, y el
  soporte de Apple Pencil es peor que con PencilKit.

## Consecuencias

- No hace falta ni Mac ni pagar nada.
- `project.yml` es legible y se revisa bien en un pull request.
- **No hay compilador en local:** cada cambio se comprueba con un push y unos
  minutos de espera. Los errores de compilación se leen en el log del
  workflow.
- **La firma gratuita caduca a los 7 días:** hay que reinstalar con Sideloadly
  cada semana. Límite de 3 apps por dispositivo.
- Sin Xcode no hay depurador ni vistas previas de SwiftUI.
- El workflow depende de la versión de Xcode del runner (`macos-latest`
  cambia con el tiempo). Si un día deja de compilar, se puede fijar una
  versión concreta del runner.
- El objetivo mínimo es **iPadOS 17** (por `@Observable`).
