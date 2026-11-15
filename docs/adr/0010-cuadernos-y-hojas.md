# 0010. Cuadernos con hojas

- **Estado:** Aceptada
- **Fecha:** 2026-11-15

## Contexto

Hasta ahora la galería mostraba dibujos sueltos, cada uno con su título. Se
quiere que funcione como **cuadernos**: cada cuaderno agrupa varias hojas y
se pueden ir añadiendo hojas a demanda, como al pasar página.

Ya hay una base de datos instalada con dibujos
([ADR 0007](0007-swiftdata.md)), así que cualquier cambio de esquema tiene
que poder aplicarse solo, sin perder nada.

## Decisión

1. **Dos entidades:** `Notebook` (título y fecha) y `Drawing`, que pasa a
   ser **una hoja** y gana `notebookID`. El título deja de ser de la hoja y
   pasa al cuaderno; las hojas se nombran por su posición ("Hoja 2 de 5").
2. **Las hojas se ordenan por fecha de creación.** Añadir una hoja la pone
   al final. No hay reordenación.
3. **Un cuaderno nunca está vacío:** crear un cuaderno crea su primera hoja
   y no se puede eliminar la última. Son reglas de los casos de uso
   (`CreateNotebookUseCase`, `DeletePageUseCase`).
4. **Una hoja nueva hereda el papel de la última** (patrón y tema).
5. **Base de datos:** tabla nueva `NotebookRecord` y columna opcional
   `notebookID` en `DrawingRecord`, relacionadas por una clave ajena
   explícita. Ambos cambios son migraciones ligeras.
6. **Migración de datos al arrancar** (`adoptOrphanDrawings`): cada dibujo
   sin cuaderno recibe uno propio que hereda su título. Así, tras actualizar,
   la galería se ve igual: cada dibujo es ahora un cuaderno de una hoja.
7. **Una sola clase, `SwiftDataLibrary`, implementa los dos repositorios**,
   porque comparten el mismo `ModelContext`.
8. **Navegación:** la galería abre un cuaderno; dentro, la barra muestra
   `‹ Título · Hoja 2 de 5 ›` con flechas y un menú para añadir o eliminar
   hojas. `NotebookViewModel` decide qué hoja se ve y habla con la hoja
   abierta a través del protocolo `PageSession`.
9. Se **elimina** `LegacyDrawingFileImporter` (importaba el archivo único de
   la primera versión): ese paso ya se hizo en las instalaciones existentes.

## Alternativas consideradas

- **Renombrar `Drawing` a `Page` en todo el código:** el nombre sería más
  exacto, pero obliga a renombrar la tabla (migración no ligera) o a tener
  nombres distintos en el código y en la base de datos. Se mantiene
  `Drawing` y se documenta la equivalencia.
- **Relación de SwiftData (`@Relationship`) entre cuaderno y hojas:** da
  borrado en cascada y navegación entre objetos, pero las entidades de
  dominio son `struct` y habría que deshacer esa relación al mapear. La
  clave ajena explícita es más directa y fácil de probar.
- **Un único cuaderno "Mis dibujos" con todos los dibujos existentes:** se
  perderían los títulos que ya tenían.
- **Un campo de orden (`position`) en cada hoja:** necesario para reordenar;
  mientras no se pueda, la fecha de creación basta y evita renumerar.
- **Pantalla intermedia con la cuadrícula de hojas** entre la galería y el
  lienzo: útil para cuadernos largos; por ahora añade un paso más para
  empezar a dibujar. Se puede añadir después sin cambiar el modelo.
- **Mantener un solo lienzo y cambiarle el contenido al pasar de hoja:** más
  rápido, pero mezcla en un mismo ViewModel el estado de varias hojas
  (autoguardado pendiente, papel). Un lienzo y un ViewModel por hoja abierta
  mantiene cada uno simple.

## Consecuencias

- La galería muestra cuadernos con su portada (primera hoja), el número de
  hojas y la última actividad.
- Los dibujos existentes se conservan como cuadernos de una hoja con su
  título. La columna `title` de `DrawingRecord` queda solo para esa
  migración.
- Eliminar un cuaderno borra todas sus hojas; el repositorio lo hace a mano
  al no haber relación con cascada.
- Al borrar una hoja intermedia, las siguientes cambian de número.
- Cambiar de hoja crea un lienzo nuevo: el zoom vuelve a 1× y el historial
  de deshacer empieza de cero. El lápiz elegido y "dibujar con el dedo" se
  mantienen (paleta compartida y `CanvasPreferences`).
- Para ir de la hoja 1 a la 20 hay que pasar una a una: no hay salto directo.
- Listar cuadernos hace una consulta de hojas por cuaderno. Con decenas de
  cuadernos es inapreciable; con miles habría que resumir de otra forma.
