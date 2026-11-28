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
- WebKit solo se toca en `Presentation/Mermaid/WebKitMermaidPreview.swift`,
  `MermaidPreviewView.swift`, `Presentation/Markdown/WebKitMarkdownRenderer.swift`
  y `MarkdownWebView.swift`; el ViewModel de Mermaid usa el protocolo
  `MermaidPreview`. Mermaid y marked van dentro de la app (`Resources/Mermaid`,
  11.x; `Resources/Markdown`, 18.x; versiones fijadas): no se cargan de
  internet. El HTML de un documento Markdown nunca se ejecuta.
- Las implementaciones concretas solo se crean en `App/AppContainer.swift`.
- No crees vistas de UIKit (`PKCanvasView`…) en `DrawPadApp.init()`: aún no
  existe `UIApplication` y la app se cierra al tocar. En `AppContainer` todo
  es `lazy`.
- `Data` convierte sus errores a `DrawingError`.
- Los `@Model` de SwiftData (`NotebookRecord`, `DrawingRecord`) no salen de
  `Data`: el resto usa las entidades `Notebook` y `Drawing`. Toda propiedad
  nueva en un `@Model` debe ser **opcional**, o la base de datos ya instalada
  no abrirá (ver `docs/adr/0007-swiftdata.md`).
- En la interfaz se dice **cuaderno** y **hoja**; en el código, `Notebook` y
  `Drawing`. Un cuaderno nunca se queda sin hojas (regla en los casos de uso).
  Una hoja es de dibujo o Markdown (`Drawing.kind`); `AppContainer` elige su
  pantalla en `makeSession`.
- Textos, imágenes, figuras y conexiones (`PageElement`) van en
  `PageElementsLayer`, bajo los trazos. Se guardan al momento por sus casos
  de uso, no con el autoguardado. Borrar una hoja o un cuaderno debe borrar
  sus elementos; borrar un elemento, sus conexiones.
- Lo que se puede cambiar depende del dispositivo: `EditingCapabilities` en
  el entorno (`\.editing`). En el iPad, todo (`.full`); en el iPhone
  (`.phone`), cuadernos, hojas Markdown y diagramas, sin trazos. Toda
  acción nueva que edite se esconde según su permiso (`canManageNotebooks`,
  `canDraw`, `canEditDiagrams`, `canWriteMarkdown`); un área nueva es un
  campo nuevo, no un `if` suelto. Las pruebas de ese modo usan `-phoneMode`
  en el simulador de iPad (`PhoneUITests`).
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
(`.github/workflows/build.yml`). Tiene dos trabajos en paralelo: **Pruebas**
corre las unitarias y de interfaz en un simulador de iPad (unos 25 minutos)
en cada push y pull request; **IPA** compila y publica
`DrawPad-unsigned.ipa` (unos 3) **solo al fusionar en `develop` o `main`**, o
con Run workflow sobre una rama (ver `docs/adr/0023-ipa-solo-al-fusionar.md`).
Si falla, el error está en el log del paso correspondiente.

El `.ipa` no espera a las pruebas (ver `docs/adr/0014-ipa-y-pruebas-en-paralelo.md`);
que haya `.ipa` solo significa que la app compila, no que las pruebas hayan
pasado.

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
- **No uses ramas `claude/…`** ni otros prefijos: solo `feature/`, `release/`,
  `backport/` y `hotfix/`.
- **Los PR los fusiona el dueño, o los fusiono yo cuando él lo pide.** Tampoco
  se añaden reglas de proceso (ramas nuevas, cuándo se fusiona) sin que lo
  pida: el proceso es el de este documento.
- Versionado semántico: funcionalidad sube `y`, arreglos suben `z`.
