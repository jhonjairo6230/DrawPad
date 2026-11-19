# 0022. Diagramas en el iPhone, sin trazos

- **Estado:** Aceptada
- **Fecha:** 2026-11-19
- **Cambia:** el punto 2 de [ADR 0018](0018-iphone-solo-lectura.md) (solo
  lectura en el iPhone), para figuras, conexiones y diagramas Mermaid.

## Contexto

Con [ADR 0021](0021-markdown-en-iphone.md) el iPhone ya escribe hojas
Markdown. Las **figuras y conexiones** ([ADR 0016](0016-figuras-de-diagrama.md))
y los **diagramas Mermaid** ([ADR 0019](0019-hojas-mermaid.md)) tampoco
necesitan el Apple Pencil: se insertan desde un menú, se mueven con el dedo
y su texto se escribe con el teclado. Lo que no encaja en el iPhone son los
**trazos**: dibujar con el dedo en una pantalla pequeña y la paleta de
herramientas.

## Decisión

1. **Nuevo permiso `canEditDiagrams`** en `EditingCapabilities`: insertar,
   mover, conectar, girar, editar y eliminar figuras, conexiones y diagramas
   Mermaid; y añadir hojas de dibujo para ellos. El iPad y el iPhone lo
   tienen.
2. En el iPhone **sigue sin haber trazos** (`canDraw` falso): ni dibujar con
   el dedo, ni paleta, ni deshacer/rehacer (son de los trazos), ni papel,
   suavizar o borrar todo. Tampoco cuadros de texto ni pegar, que son del
   flujo de dibujo del iPad.
3. **Barra del lienzo según el permiso**: en el iPhone queda *Insertar*
   (*Diagrama Mermaid*, *Figura*, *Mover y conectar*) y *Compartir*.
4. La barra del modo de mover va en **una línea si cabe**; si no, el aviso
   arriba y los botones debajo (`ViewThatFits`).
5. El lienzo del iPhone sigue en modo sin trazos (gesto de dibujo apagado y
   hoja ajustada al ancho); los elementos se mueven en el modo de mover, que
   ya desactiva el lienzo mientras dura.
6. En el iPhone se **añaden** hojas de dibujo (para diagramas) pero **no se
   borran** (podrían tener trazos del iPad que allí no se rehacen).

## Alternativas consideradas

- **Dibujar con el dedo en el iPhone:** posible con PencilKit, pero en una
  pantalla pequeña y sin Pencil el resultado es pobre, y la paleta ocupa
  media pantalla.
- **Una pantalla aparte para diagramas en el iPhone:** más código para lo
  mismo; con el permiso, la misma pantalla esconde lo que no aplica.

## Consecuencias

- Un diagrama de arquitectura se puede empezar o retocar desde el teléfono y
  terminarlo con el Pencil en el iPad (exportando e importando el cuaderno,
  [ADR 0017](0017-exportar-importar-cuadernos.md)).
- Las hojas de dibujo creadas por error en el iPhone se borran en el iPad.
