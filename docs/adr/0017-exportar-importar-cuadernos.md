# 0017. Exportar e importar cuadernos en archivos `.drawpad`

- **Estado:** Aceptada
- **Fecha:** 2026-11-19

## Contexto

Se quiere sacar un cuaderno del iPad y abrirlo en otro dispositivo (en
concreto, el iPhone), pasándolo por iCloud Drive. Los cuadernos viven en una
base de datos SwiftData dentro de la app ([ADR 0007](0007-swiftdata.md)).

La sincronización automática con iCloud (CloudKit) necesita capacidades de
una cuenta de pago de Apple Developer; la app se instala con un Apple ID
gratuito ([ADR 0004](0004-compilar-sin-mac.md)).

## Decisión

1. **Un archivo por cuaderno, `.drawpad`**: un JSON con todo el cuaderno
   (tapa, hojas con sus trazos y papel, y todos los elementos). Los datos
   binarios van en Base64.
2. **Formato propio y versionado**: el JSON lleva `format: "drawpad-notebook"`
   y `version: 1`, y usa tipos propios (`ArchiveFile`, `NotebookDTO`,
   `PageDTO`, `ElementDTO`) en lugar de las entidades. Esta app lee su
   versión y las anteriores; una más nueva da un error propio.
3. **El dominio no conoce el formato**: `NotebookBundle` es el cuaderno
   completo, y el puerto `NotebookArchiveCoder` lo convierte. La lectura del
   archivo es otro puerto (`ImportedFileReader`), por el acceso temporal que
   pide iOS a los archivos de fuera de la app.
4. **Importar reemplaza el cuaderno si ya está** (mismo identificador): se
   borra con sus hojas y elementos y se guarda la versión del archivo. Si no
   está, se añade. Antes de tocar nada se comprueba que el archivo es
   coherente (al menos una hoja, todas del cuaderno, cada elemento en una).
5. **Exportar**: mantener pulsado el cuaderno en la galería → "Exportar", que
   abre la hoja de compartir ("Guardar en Archivos" → iCloud Drive).
6. **Importar de dos formas**: el botón "Importar" de la galería (selector
   de archivos) y tocar un `.drawpad` en la app Archivos, que abre DrawPad.
   Para lo segundo se declara el tipo de archivo en `project.yml`
   (`UTExportedTypeDeclarations`, `CFBundleDocumentTypes`).
7. Valores desconocidos (un color o un papel de una versión futura) caen en
   el valor por defecto; un elemento de un tipo desconocido se omite.

## Alternativas consideradas

- **Sincronización con iCloud (CloudKit o SwiftData con iCloud):** sería
  automática, pero necesita una cuenta de pago para las capacidades de iCloud.
- **Un paquete `.zip` con un archivo por hoja e imágenes sueltas:** ocupa
  menos (sin Base64) y se puede inspeccionar, pero iOS no trae una forma
  sencilla de crear zips sin librerías externas.
- **`Codable` directamente sobre las entidades:** menos código, pero cualquier
  cambio en una entidad cambiaría el formato y rompería los archivos viejos.
- **Importar siempre como copia nueva:** nunca se pierde nada, pero el ida y
  vuelta entre dispositivos llenaría la galería de copias.
- **Exportar a PDF para leer en el iPhone:** se lee en cualquier sitio, pero
  no se puede volver a importar ni seguir editando.

## Consecuencias

- Un cuaderno se puede llevar a otro iPad o al iPhone, y hacer copias de
  seguridad a mano.
- **Importar un cuaderno que ya está borra los cambios locales** de ese
  cuaderno y deja la versión del archivo. Es lo esperado para leer en el
  iPhone lo escrito en el iPad, pero si se edita en los dos sitios, gana el
  último que se importa.
- Los archivos pesan un tercio más que los datos (Base64); un cuaderno con
  muchas imágenes pegadas puede ocupar varios megas.
- No hay sincronización automática: hay que exportar e importar cada vez.
- Cambiar el formato en el futuro exige subir `version` y seguir leyendo las
  anteriores.
