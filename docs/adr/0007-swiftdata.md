# 0007. SwiftData como base de datos local

- **Estado:** Aceptada
- **Fecha:** 2026-11-14

## Contexto

La primera versión guardaba **un único dibujo** en un archivo
(`current.drawing`). Con la galería hay muchos dibujos, cada uno con título,
fechas y miniatura, y hace falta listarlos ordenados, renombrarlos y
borrarlos. Se quiere que todo quede **guardado en el propio iPad**, sin
servidores ni cuentas.

Hay una restricción fuerte: el proyecto se mantiene **sin Xcode**
([ADR 0004](0004-compilar-sin-mac.md)), así que cualquier cosa que necesite
un editor visual de Xcode queda descartada.

## Decisión

Usar **SwiftData**, el framework de persistencia de Apple (iOS 17):

- El modelo `DrawingRecord` (`@Model`) se define **en código Swift**, sin
  archivos de esquema.
- Los trazos y la miniatura usan `@Attribute(.externalStorage)` para no
  engordar la base de datos.
- `SwiftDataDrawingRepository` implementa el puerto `DrawingRepository` y es
  el único que conoce SwiftData. Convierte `DrawingRecord` ↔ `Drawing`.
- Las vistas **no** usan `@Query` ni `@Environment(\.modelContext)`: piden
  los datos a su ViewModel, que usa casos de uso.
- El repositorio usa un `ModelContext` propio, siempre desde el hilo
  principal.
- Las pruebas usan una base de datos **en memoria**
  (`isStoredInMemoryOnly`). Las de interfaz arrancan la app con `-uiTesting`
  para lo mismo.
- El archivo de la versión anterior se importa una vez al arrancar
  (`LegacyDrawingFileImporter`).

## Alternativas consideradas

- **Un archivo por dibujo + un índice JSON:** sin dependencias y fácil de
  entender, pero hay que programar a mano el orden, la consistencia entre
  índice y archivos y las escrituras parciales.
- **Core Data:** maduro y con más control, pero el esquema se define en un
  archivo `.xcdatamodeld` que se edita con Xcode. Inviable sin Mac.
- **SQLite directo o GRDB:** control total del SQL, a cambio de escribir
  consultas y migraciones a mano, o de añadir una dependencia externa.
- **SwiftData "a la manera de Apple"** (`@Query` en las vistas y el `@Model`
  como modelo de toda la app): mucho menos código, pero acopla vistas y
  lógica a la base de datos y rompe la regla de dependencias
  ([ADR 0003](0003-clean-architecture-mvvm.md)).
- **iCloud / CloudKit:** sincronizaría entre dispositivos, pero necesita una
  cuenta de pago de Apple Developer y no hace falta para un solo iPad.

## Consecuencias

- Consultas ordenadas, unicidad y escrituras seguras sin programarlas.
- Todo queda en el iPad, dentro del contenedor de la app
  (`Application Support/default.store`). **Desinstalar la app borra los
  dibujos**; reinstalar encima con Sideloadly los conserva.
- Hay código de mapeo entre `DrawingRecord` y `Drawing`, y la galería se
  refresca a mano (`load()`) en lugar de sola con `@Query`. Es el precio de
  mantener el dominio limpio.
- **Cambiar el esquema tiene consecuencias.** Añadir una propiedad opcional o
  con valor por defecto es una migración automática. Renombrar o cambiar
  tipos necesita un `SchemaMigrationPlan`; sin él, la app no abre la base de
  datos ya instalada. Cualquier cambio en `DrawingRecord` hay que pensarlo
  con eso en mente.
- Si la base de datos no se puede abrir, la app termina con un `fatalError`
  explícito: sin ella no puede hacer nada útil.
- Los dibujos no salen del iPad si no se exportan (Guardar en Fotos).
