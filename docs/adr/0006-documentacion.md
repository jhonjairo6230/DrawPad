# 0006. Documentar con Markdown + Mermaid y comentarios DocC

- **Estado:** Aceptada
- **Fecha:** 2026-11-14

## Contexto

El proyecto es material de estudio: la documentación importa tanto como el
código. Tiene que incluir diagramas (capas, clases, secuencias) y leerse
**desde Windows y desde GitHub**, sin Xcode.

La herramienta oficial de Apple es **DocC**: comentarios `///` en el código
más un catálogo `.docc` con artículos, que Xcode compila en un sitio de
documentación. Pero DocC tiene dos límites aquí: hace falta Xcode para
compilarlo y verlo, y no dibuja diagramas Mermaid (habría que exportarlos como
imágenes).

## Decisión

Combinar dos niveles:

1. **En el código:** comentarios `///` con sintaxis DocC en cada tipo y en los
   métodos que lo merecen. Es la convención oficial de Apple y Xcode los
   muestra en *Quick Help*. Explican el **porqué**, no repiten el código.
2. **En `docs/`:** guías en Markdown con diagramas **Mermaid**, que GitHub
   dibuja directamente:
   - `arquitectura.md` — capas, clases y diagramas de secuencia.
   - `compilacion-e-instalacion.md` — del push al iPad.
   - `flujo-de-trabajo.md` — Git Flow.
   - `conceptos-ios.md` — glosario.
   - `adr/` — decisiones.

Idioma: documentación, comentarios e interfaz en **español**; nombres de
tipos, funciones y pruebas en **inglés**, como las API de Apple.

## Alternativas consideradas

- **Solo un catálogo DocC:** es lo "oficial", pero no se puede leer sin
  compilar y pierde los diagramas en texto.
- **DocC publicado en GitHub Pages desde el CI:** viable, pero añade un
  despliegue que mantener en un proyecto que no se publica.
- **Diagramas como imágenes (draw.io, capturas):** no se pueden revisar en un
  diff y se quedan desactualizados.
- **Wiki de GitHub:** fuera del repo.

## Consecuencias

- Toda la documentación se lee en GitHub sin instalar nada, y los diagramas
  se editan como texto en el mismo pull request que el código.
- Los comentarios `///` ya están listos por si algún día se añade un catálogo
  DocC.
- No hay un sitio de referencia de API generado: se navega por el código.
- Los diagramas hay que actualizarlos a mano cuando cambia el diseño.
