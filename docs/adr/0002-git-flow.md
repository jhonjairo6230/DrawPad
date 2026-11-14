# 0002. Usar Git Flow como flujo de ramas

- **Estado:** Aceptada
- **Fecha:** 2026-11-14

## Contexto

Hace falta una forma ordenada de trabajar con ramas. El proyecto lo desarrolla
una persona, a veces con ayuda de un asistente de IA, y se quiere el mismo
flujo que en los otros proyectos del autor para no tener que recordar reglas
distintas. Además, cada rama produce un `.ipa` instalable, así que conviene
distinguir "lo que estoy probando" de "la versión que funciona".

## Decisión

Se usa **Git Flow**:

- `main`: versiones publicadas. `develop`: integración.
- Ramas de trabajo con prefijo `feature/`, `release/`, `backport/` y
  `hotfix/`, en minúsculas y con guiones.
- No se hace commit directo en `main` ni en `develop`; todo entra por pull
  request con el workflow en verde.
- No se abre un pull request de `develop` a `main`: se pasa por `release/`.
- **No se usan otros prefijos** (por ejemplo `claude/…`), tampoco cuando el
  trabajo lo hace un asistente.
- Versionado semántico en `project.yml` (`MARKETING_VERSION`).

El detalle y los diagramas están en
[flujo-de-trabajo.md](../flujo-de-trabajo.md).

## Alternativas consideradas

- **GitHub Flow** (solo `main` + ramas cortas): más simple, pero no separa lo
  que está en pruebas de la versión estable, y es distinto del flujo de los
  otros proyectos.
- **Trunk-based** (commits directos a `main`): mínimo esfuerzo, pero sin
  historial de versiones claro para estudiar.

## Consecuencias

- `main` siempre tiene una versión que funcionó en el iPad.
- El historial muestra qué entró en cada versión.
- Más pasos para un proyecto personal: una release necesita dos pull requests
  (release y backport).
- La rama de producción se llama `main` (el nombre por defecto de GitHub), no
  `master` como en la descripción clásica de Git Flow. Es solo el nombre.
