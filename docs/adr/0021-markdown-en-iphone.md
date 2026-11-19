# 0021. Escribir hojas Markdown en el iPhone

- **Estado:** Aceptada
- **Fecha:** 2026-11-19
- **Cambia:** el punto 2 de [ADR 0018](0018-iphone-solo-lectura.md) (solo
  lectura en el iPhone), para las hojas Markdown.

## Contexto

En el iPhone la app solo leía ([ADR 0018](0018-iphone-solo-lectura.md)):
sin Apple Pencil y con poca pantalla, dibujar no tiene sentido. Pero las
hojas Markdown ([ADR 0020](0020-hojas-markdown.md)) son **solo texto**, y en
el iPhone sí hay teclado: tomar una nota o corregir un spec desde el teléfono
es útil.

## Decisión

1. **Lo que se puede cambiar deja de ser un sí/no** (`canEdit`) y pasa a ser
   `EditingCapabilities`, con un permiso por área:
   - `canManageNotebooks`: crear, renombrar y cambiar la portada de cuadernos.
   - `canDraw`: dibujar y todo lo de las hojas de dibujo (añadirlas,
     borrarlas, herramientas, papel, textos, imágenes, figuras).
   - `canWriteMarkdown`: crear, editar, importar y borrar hojas Markdown.
2. **iPad = `.full`** (todo). **iPhone = `.phone`**: solo `canWriteMarkdown`.
3. En el iPhone, el **+** del cuaderno ofrece *Hoja Markdown* e *Importar
   Markdown…* (no *Hoja de dibujo*); una hoja Markdown tiene *Ver / Editar* y
   se puede borrar. Las hojas de dibujo se siguen leyendo sin cambios y **no se
   pueden borrar** desde el iPhone (no se podrían rehacer allí).
4. Sigue sin poder **crear cuadernos** en el iPhone: se escribe dentro de los
   que vienen del iPad.
5. `AppContainer` lo decide una vez y lo reparte por el entorno de SwiftUI
   (`\.editing`). Los ViewModel y los casos de uso no cambian.
6. Las pruebas de interfaz de este modo usan `-phoneMode` en el simulador de
   iPad (antes `-readOnly`) y están en `PhoneUITests`.

## Alternativas consideradas

- **Seguir con un `Bool` y excepciones por pantalla** (`canEdit || esMarkdown`):
  más corto hoy, pero cada permiso nuevo (por ejemplo, figuras en el iPhone)
  añadiría otra condición suelta en varias vistas.
- **Abrir todo en el iPhone:** dibujar con el dedo y las herramientas no caben
  bien en la pantalla, que fue la razón de [ADR 0018](0018-iphone-solo-lectura.md).

## Consecuencias

- Las notas escritas en el iPhone quedan en el iPhone hasta que se **exporta**
  el cuaderno y se importa en el iPad (que lo reemplaza por la versión
  importada, [ADR 0017](0017-exportar-importar-cuadernos.md)). No hay
  sincronización: si se cambia el mismo cuaderno en los dos, gana el último
  que se importa.
- Cada permiso nuevo es un campo de `EditingCapabilities`, con su prueba.
