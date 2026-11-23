# 0018. La app en el iPhone, en solo lectura

- **Estado:** Aceptada; las hojas Markdown, cambiado por [0021](0021-markdown-en-iphone.md)
- **Fecha:** 2026-11-19

## Contexto

Hasta ahora DrawPad era solo para iPad. Se quiere poder **leer en el iPhone**
lo escrito en el iPad: exportar el cuaderno a iCloud Drive e importarlo en el
iPhone ([ADR 0017](0017-exportar-importar-cuadernos.md)).

PencilKit funciona en el iPhone (con el dedo); lo que no hay es Apple Pencil,
y la pantalla es pequeña para todas las herramientas del lienzo.

## Decisión

1. **Un solo `.ipa` para iPad y iPhone** (`TARGETED_DEVICE_FAMILY: "1,2"`).
2. **En el iPhone, solo lectura**: galería, importar, exportar, eliminar
   cuadernos, abrir, pasar de hoja, desplazar, ampliar y compartir la hoja.
   No se crean cuadernos ni hojas, no se renombra, no se cambia la portada y
   no se dibuja ni se insertan elementos.
3. **Se decide una vez**: `AppContainer.canEdit` (falso si
   `userInterfaceIdiom == .phone`) se reparte con el entorno de SwiftUI
   (`\.canEdit`) y cada pantalla esconde lo que no aplica. El lienzo se crea
   en modo lectura: sin paleta, con el gesto de dibujo desactivado y la hoja
   ajustada al ancho de la pantalla mientras el usuario no amplíe a mano.
4. Los ViewModel y los casos de uso **no cambian**: solo leer no los llama
   para escribir.
5. Para probar este modo sin un iPhone en el CI, la app acepta
   `-readOnly` (y `-uiTestingSampleNotebook` para arrancar con un cuaderno de
   ejemplo) en el simulador de iPad.

## Alternativas consideradas

- **App completa en el iPhone, dibujando con el dedo:** más útil para
  apuntes rápidos, pero hay que rediseñar la barra de herramientas para una
  pantalla pequeña y probarlo a fondo en un iPhone.
- **Visor aparte (otra app o una extensión):** separa bien, pero es otro
  proyecto que compilar, instalar y mantener, y ocupa uno de los tres huecos
  de la cuenta gratuita.
- **Leer los PDF exportados** en la app Archivos: no hace falta código, pero
  se pierden las hojas, la portada y la posibilidad de volver a importar.
- **Comprobar el modo en cada ViewModel:** repetiría la regla en muchos
  sitios; en el entorno de SwiftUI se decide una vez.

## Consecuencias

- El mismo `.ipa` se instala en los dos dispositivos con Sideloadly; en el
  iPhone también caduca a los 7 días y cuenta para el límite de 3 apps.
- En el iPhone, **eliminar un cuaderno sí está permitido** (para limpiar
  copias importadas), aunque sea un cambio.
- Las hojas hechas en el iPad se ven reducidas para caber a lo ancho; hay
  que ampliar para leer letra pequeña.
- La disposición en el iPhone (barra, galería) **no se prueba en el CI**, que
  usa un simulador de iPad con `-readOnly`: solo se puede juzgar en el
  iPhone.
- Si un día se quiere editar en el iPhone, el punto de partida es quitar
  `canEdit` pantalla a pantalla y adaptar la barra del lienzo.
