# 0001. Registrar las decisiones con ADR

- **Estado:** Aceptada
- **Fecha:** 2026-11-14

## Contexto

DrawPad es un proyecto personal para aprender desarrollo en iOS. No se va a
publicar, pero sí se quiere **volver a él para estudiarlo**. Sin un registro,
el motivo de cada decisión (por qué XcodeGen, por qué estas capas) se olvida.

## Decisión

Cada decisión de arquitectura o de proceso se escribe como un ADR corto en
`docs/adr/`, numerado y en español, con la
[plantilla](0000-plantilla.md): contexto, decisión, alternativas y
consecuencias.

## Alternativas consideradas

- **Explicarlo todo en el README:** crece sin orden y mezcla el "cómo se usa"
  con el "por qué se hizo así".
- **Mensajes de commit o pull requests:** se pierden en el historial y no se
  leen como documentación.
- **Wiki de GitHub:** queda fuera del repo y no se versiona junto al código.

## Consecuencias

- Cada decisión se puede leer en dos minutos, con sus alternativas.
- Hay que acordarse de escribir un ADR cuando se decide algo importante.
- Los ADR no se editan: si algo cambia, se añade uno nuevo que reemplaza al
  anterior. Así queda la historia completa.
