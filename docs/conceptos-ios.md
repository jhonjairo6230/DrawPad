# Conceptos de iOS que usa DrawPad

Glosario para estudiar el código. Cada entrada dice qué es y dónde verlo.

## Swift y SwiftUI

| Concepto | Qué es | Dónde |
| -------- | ------ | ----- |
| `@main` + `App` | Punto de entrada de una app SwiftUI. | `App/DrawPadApp.swift` |
| `View` | Una pieza de interfaz. Es una descripción (un `struct`), no un objeto en pantalla: SwiftUI la vuelve a evaluar cuando cambia el estado. | `CanvasScreen.swift` |
| `@State` | Estado propio de una vista; SwiftUI lo conserva entre evaluaciones. | `isConfirmingClear` en `CanvasScreen` |
| `@Observable` | Macro (iOS 17) que hace observable una clase: las vistas que leen sus propiedades se repintan al cambiar. | `CanvasViewModel` |
| `@Bindable` | Permite crear enlaces de escritura (`$viewModel.x`) a un objeto `@Observable`. | `CanvasScreen` |
| `@Environment(\.scenePhase)` | Estado de la app: activa, inactiva o en segundo plano. | `CanvasScreen` |
| `UIViewRepresentable` | Protocolo para usar una vista de UIKit dentro de SwiftUI. | `PencilCanvasView.swift` |
| `Menu` + `Picker` | Menú desplegable con una opción marcada. | Menú "Fondo" en `CanvasScreen` |
| `UIColor(patternImage:)` | Un "color" que en realidad es una imagen pequeña repetida. | `CanvasBackgroundPattern.swift` |
| `UIGraphicsImageRenderer` | Dibuja en una imagen con Core Graphics. | Baldosas de fondo y exportación |
| `UIGraphicsPDFRenderer` | Lo mismo, pero el resultado es un PDF. | `renderPDF()` en `PencilKitCanvas` |
| `UIActivityViewController` | La hoja de compartir del sistema. | `ActivityView.swift` |
| `UIViewControllerRepresentable` | Como `UIViewRepresentable`, para un controlador de UIKit. | `ActivityView.swift` |
| `.sheet(item:)` | Presenta una hoja mientras un valor opcional no sea `nil`. | Hoja de compartir en `CanvasScreen` |
| `protocol` | Contrato sin implementación. Base de la inversión de dependencias. | `DrawingRepository`, `ImageLibrary`, `DrawingCanvas` |
| `async` / `await` | Código asíncrono que se lee como secuencial. | `export()` en el ViewModel |
| `Task` | Unidad de trabajo asíncrono; se puede cancelar. | Autoguardado en `CanvasViewModel` |
| `@MainActor` | Garantiza que el código corre en el hilo principal (obligatorio para la interfaz). | ViewModel y lienzo |
| `throws` / `do-catch` | Manejo de errores. | Repositorios y casos de uso |
| `lazy var` | Propiedad que se crea la primera vez que se usa. | `AppContainer` |
| `@testable import` | Deja a las pruebas ver los tipos `internal` de la app. | `DrawPadTests/*` |

## PencilKit

| Tipo | Qué es |
| ---- | ------ |
| `PKCanvasView` | La vista donde se dibuja. Captura el Apple Pencil con baja latencia, presión e inclinación. |
| `PKDrawing` | El dibujo como dato: una lista de trazos (`strokes`). Se serializa con `dataRepresentation()` y se convierte en imagen con `image(from:scale:)`. |
| `PKStroke` | Un trazo: tinta (`ink`), recorrido (`path`), transformación y máscara (lo que el borrador le quitó). |
| `PKStrokePath` | El recorrido de un trazo: una curva definida por puntos de control (`PKStrokePoint`), cada uno con posición, grosor, opacidad y presión. |
| `UndoManager` | El historial de deshacer. PencilKit apunta solo lo que dibuja el usuario; los cambios hechos por código hay que registrarlos con `registerUndo`. |
| `PKToolPicker` | La paleta flotante de herramientas (lápiz, rotulador, borrador, regla, colores). |
| `PKCanvasViewDelegate` | Avisa de cambios; DrawPad usa `canvasViewDrawingDidChange`. |
| Zoom | `PKCanvasView` es un `UIScrollView`: con `minimumZoomScale`, `maximumZoomScale` y `contentSize` ya amplía y se desplaza. |
| `drawingPolicy` | `.pencilOnly` (solo el Pencil dibuja) o `.anyInput` (también el dedo). |

Todo esto vive en un solo archivo: `Presentation/Canvas/PencilKitCanvas.swift`.

## SwiftData (base de datos local)

| Concepto | Qué es | Dónde |
| -------- | ------ | ----- |
| SwiftData | Framework de Apple (iOS 17) para guardar objetos en una base de datos local (SQLite por debajo). | `Data/` |
| `@Model` | Macro que convierte una clase en una tabla: cada propiedad es una columna. | `NotebookRecord.swift`, `DrawingRecord.swift` |
| Clave ajena | Una columna que guarda el `id` de otra tabla para relacionarlas. | `DrawingRecord.notebookID` |
| Migración ligera | SwiftData adapta sola la base de datos ya instalada si el cambio es simple (una tabla nueva, una columna opcional). | `DrawingRecord`, ADR 0007 y 0010 |
| `@Attribute(.unique)` | No puede haber dos registros con el mismo valor. | `DrawingRecord.id` |
| `@Attribute(.externalStorage)` | Guarda datos grandes en archivos aparte; la base de datos solo guarda la referencia. | Trazos y miniatura |
| `ModelContainer` | La base de datos: sabe qué modelos existen y dónde está el archivo. | `SwiftDataLibrary.makeContainer` |
| `ModelContext` | La "sesión de trabajo": se insertan, cambian y borran objetos, y `save()` lo escribe a disco. No se comparte entre hilos. | `SwiftDataLibrary` |
| `FetchDescriptor` | Una consulta: filtro, orden y límite. | `SwiftDataLibrary` |
| `#Predicate` | Macro para escribir el filtro en Swift; se traduce a SQL. | `SwiftDataLibrary` |
| `isStoredInMemoryOnly` | Base de datos que no toca el disco; ideal para pruebas. | Pruebas y `-uiTesting` |

## Navegación

| Concepto | Qué es | Dónde |
| -------- | ------ | ----- |
| `NavigationStack` | Contenedor que apila pantallas con botón "atrás". | `GalleryScreen` |
| `navigationDestination(item:)` | Navega mientras un valor opcional no sea `nil`; al volver atrás lo pone a `nil`. | `GalleryScreen` |
| `LazyVGrid` | Cuadrícula que solo crea las celdas visibles. | `GalleryScreen` |
| `.id(_:)` | Da identidad a una vista: si cambia, SwiftUI la desmonta y monta otra nueva. | Cambio de hoja en `NotebookScreen` |
| `ToolbarItem(placement: .principal)` | Contenido propio en el centro de la barra, en lugar del título. | Controles de hojas en `NotebookScreen` |
| `contextMenu` | Menú al mantener pulsado. | Renombrar / Eliminar |
| `ContentUnavailableView` | Vista estándar de "no hay nada que mostrar". | Galería vacía |

## Almacenamiento y permisos

| Concepto | Qué es | Dónde |
| -------- | ------ | ----- |
| *Sandbox* | Cada app solo puede leer y escribir en su propio contenedor. | — |
| `Application Support` | Carpeta del contenedor para datos de la app que el usuario no gestiona. Ahí vive la base de datos. | — |
| `Info.plist` | Metadatos de la app (nombre, orientaciones, textos de permisos). Aquí lo genera XcodeGen desde `project.yml`. | `project.yml` → `info` |
| `NSPhotoLibraryAddUsageDescription` | Texto que iOS muestra al pedir permiso para añadir fotos. Sin él, la app se cierra al pedirlo. | `project.yml` |
| `PHPhotoLibrary` | API de la fototeca. `.addOnly` = permiso solo para añadir. | `PhotoLibraryImageExporter.swift` |

## Compilación y distribución

| Concepto | Qué es |
| -------- | ------ |
| `.xcodeproj` | El proyecto de Xcode. Aquí no se guarda en git: lo genera XcodeGen. |
| *Target* | Un producto que se compila: `DrawPad` (app) y `DrawPadTests` (pruebas). |
| *Scheme* | Receta que dice qué targets compilar y probar. |
| `xcodebuild` | Xcode desde la línea de comandos; lo usa el CI. |
| *Bundle identifier* | Identificador único de la app (`com.jhonjairo6230.drawpad`). |
| `.app` | La app compilada (en realidad, una carpeta). |
| `.ipa` | Un `.zip` con la `.app` dentro de `Payload/`. Es el formato para instalar. |
| Firma de código | iOS solo ejecuta apps firmadas con un certificado de Apple. |
| Perfil de aprovisionamiento | Archivo que une certificado + app + dispositivos permitidos. |
| *Sideloading* | Instalar una app sin pasar por el App Store. |

## Documentación en el código

Apple documenta con **comentarios `///`** (formato DocC). Xcode los muestra
con Opción + clic sobre cualquier símbolo. Ejemplos de sintaxis usados aquí:

```swift
/// Resumen en una línea.
///
/// Explicación más larga, con enlaces a otros símbolos: ``DrawingError``.
/// - Parameter pngData: qué es el parámetro.
/// - Returns: qué devuelve.
/// - Throws: qué errores lanza.
```

Ver [ADR 0006](adr/0006-documentacion.md) para saber por qué los diagramas
están en `docs/` y no en un catálogo DocC.
