# 0023. El `.ipa` solo al fusionar en `develop` o `main`

- **Estado:** Aceptada
- **Fecha:** 2026-11-23
- **Cambia:** cuándo se genera el `.ipa` en
  [ADR 0014](0014-ipa-y-pruebas-en-paralelo.md) (antes, en cada push y en cada
  pull request).

## Contexto

Con [ADR 0014](0014-ipa-y-pruebas-en-paralelo.md), cada push a cualquier rama
y cada pull request generaban un `.ipa`, además de correr las pruebas. Al
abrir varias ramas a la vez (por ejemplo, PR encadenados) se juntaban muchas
ejecuciones; los Mac de GitHub hacían cola y las pruebas tardaban mucho más en
dar resultado. Y la mayoría de esos `.ipa` no se instalaban nunca.

El `.ipa` que de verdad se instala es el de lo **ya fusionado**: lo que hay en
`develop` (para probar en el iPad) o en `main` (la versión publicada).

## Decisión

1. El trabajo **IPA** solo corre en un **push a `develop` o a `main`**, es
   decir, al fusionar un pull request en ellas.
2. El trabajo **Pruebas** sigue corriendo en **cada push y cada pull
   request**: es lo que dice si una rama se puede fusionar.
3. Sigue existiendo **Run workflow** (Actions → Compilar IPA): lanzado a mano
   sobre cualquier rama, genera también el `.ipa`, por si hace falta probar
   algo en el iPad antes de fusionarlo.
4. Los dos trabajos siguen siendo independientes y en paralelo, como en
   [ADR 0014](0014-ipa-y-pruebas-en-paralelo.md).

## Alternativas consideradas

- **Dejarlo como estaba:** un `.ipa` por rama, a costa de más cola en los Mac.
- **El `.ipa` solo en `main`:** aún menos ejecuciones, pero no se podría
  probar en el iPad lo fusionado en `develop` antes de una versión.
- **Que el `.ipa` espere a las pruebas en `develop` y `main`:** solo habría
  `.ipa` con pruebas en verde, pero se vuelve a esperar 25 minutos para
  instalar ([ADR 0014](0014-ipa-y-pruebas-en-paralelo.md) lo descartó).

## Consecuencias

- Un pull request ya no trae `.ipa`: en su ejecución el trabajo IPA aparece
  como omitido. Para revisar en el iPad antes de fusionar, se usa Run
  workflow sobre la rama.
- Que la app **compila** lo sigue comprobando el trabajo Pruebas, que la
  compila para el simulador.
- Menos ejecuciones de IPA y menos cola en los Mac de GitHub.
