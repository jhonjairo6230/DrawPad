# 0024. Crear y arreglar cuadernos en el iPhone

- **Estado:** Aceptada
- **Fecha:** 2026-11-23
- **Cambia:** el punto 4 de [ADR 0021](0021-markdown-en-iphone.md) (en el
  iPhone no se crean cuadernos).

## Contexto

Con [ADR 0021](0021-markdown-en-iphone.md) y [ADR 0022](0022-diagramas-en-iphone.md)
el iPhone ya escribe hojas Markdown y hace diagramas, pero solo dentro de
cuadernos traídos del iPad. Para empezar algo nuevo desde el teléfono (una
nota, un spec, un diagrama) hacía falta pasar antes por el iPad.

Crear, renombrar o cambiar la portada de un cuaderno no necesita el Pencil.
La única excepción es la portada con estilo **"Dibujo"**, que se dibuja a
mano ([ADR 0015](0015-portada-dibujada.md)).

## Decisión

1. En el iPhone, `canManageNotebooks` pasa a ser **verdadero**: se crean,
   renombran y cambian la portada de los cuadernos.
2. El estilo de portada **"Dibujo" solo se ofrece con `canDraw`**
   (`EditingCapabilities.coverStyles(current:)`). Si un cuaderno ya tiene una
   portada dibujada en el iPad, el iPhone la muestra y la conserva al guardar,
   pero no la deja redibujar ("El dibujo de la portada se hace en el iPad").
3. Un cuaderno nuevo empieza, como en el iPad, con una **hoja de dibujo**:
   en el iPhone sirve para diagramas, y con **+** se añaden hojas Markdown.

## Alternativas consideradas

- **Que en el iPhone la primera hoja sea Markdown:** encaja mejor si el
  cuaderno es solo de texto, pero el caso de uso se comportaría distinto según
  el dispositivo. Se deja para más adelante si hace falta.
- **Esconder también el estilo "Dibujo" ya puesto:** al cambiar el color en
  el iPhone se perdería el dibujo hecho en el iPad.

## Consecuencias

- Se puede empezar un cuaderno en el iPhone y seguirlo en el iPad (exportando
  e importando, [ADR 0017](0017-exportar-importar-cuadernos.md)).
- La hoja de dibujo inicial no se puede borrar en el iPhone
  ([ADR 0022](0022-diagramas-en-iphone.md)); se queda vacía si no se usa.
