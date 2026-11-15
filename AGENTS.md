# DrawPad — notas del proyecto

App de dibujo para iPad (SwiftUI + PencilKit) con fines de estudio. Se compila
solo en GitHub Actions: **no hay Mac ni compilador de Swift en local**.
Documentación en `docs/`; decisiones en `docs/adr/`.

## Reglas de arquitectura

- `DrawPad/Domain` solo importa `Foundation`. Nada de `SwiftUI`, `UIKit`,
  `PencilKit`, `SwiftData` ni `Photos`.
- `Presentation` no conoce `Data`: el ViewModel recibe casos de uso.
- PencilKit solo se toca en `PencilKitCanvas.swift` y `PencilCanvasView.swift`.
  El ViewModel usa el protocolo `DrawingCanvas`.
- Las implementaciones concretas solo se crean en `App/AppContainer.swift`.
- No crees vistas de UIKit (`PKCanvasView`…) en `DrawPadApp.init()`: aún no
  existe `UIApplication` y la app se cierra al tocar. En `AppContainer` todo
  es `lazy`.
- `Data` convierte sus errores a `DrawingError`.
- `DrawingRecord` (`@Model` de SwiftData) no sale de `Data`: el resto usa la
  entidad `Drawing`. Si cambias sus propiedades, piensa en la migración de la
  base de datos ya instalada (ver `docs/adr/0007-swiftdata.md`).
- Cada tipo lleva un comentario `///` que explica su papel (el porqué).
- Interfaz, comentarios y documentación en español; identificadores en inglés.
- Lógica nueva → pruebas en `DrawPadTests` con los dobles de `Doubles/`.
- Pantallas o flujos nuevos → prueba en `DrawPadUITests` (arrancan con
  `-uiTesting`: base de datos vacía en memoria).

## Proyecto de Xcode

- La fuente de verdad es `project.yml` (XcodeGen). No se guardan en git ni el
  `.xcodeproj` ni `DrawPad/Resources/Info.plist`.
- Permisos y claves de `Info.plist` van en `project.yml` → `info.properties`.
- Los archivos Swift nuevos se incluyen solos (XcodeGen lee las carpetas).

## Comprobar un cambio

Push a la rama y mirar el workflow **Compilar IPA**
(`.github/workflows/build.yml`): ejecuta las pruebas unitarias y de interfaz en un simulador de iPad y
publica `DrawPad-unsigned.ipa`. Si falla, el error de compilación está en el
log del paso correspondiente.

## Documentación

- Si cambia un flujo o una capa, actualiza los diagramas de
  `docs/arquitectura.md`.
- Una decisión importante (librería, estructura, proceso) → nuevo ADR en
  `docs/adr/` y su fila en `docs/adr/README.md`. Los ADR aceptados no se
  reescriben.

## Flujo de ramas (Git Flow)

| Rama | Sale de | PR hacia | Para qué |
| ---- | ------- | -------- | -------- |
| `feature/<nombre>` | `develop` | `develop` | Cualquier funcionalidad, arreglo o documentación. |
| `release/<x.y.z>` | `develop` | `main` | Preparar una versión: subir `MARKETING_VERSION` en `project.yml`. |
| `backport/<x.y.z>` | `main` (tras la release) | `develop` | Igualar `develop` con `main`. |
| `hotfix/<x.y.z>` | `main` | `main` | Arreglo urgente. Después, `backport/<x.y.z>` a `develop`. |

- **Nunca** un PR de `develop` a `main` ni commits directos en `develop` o `main`.
- **No uses ramas `claude/…`** ni otros prefijos.
- Versionado semántico: funcionalidad sube `y`, arreglos suben `z`.
