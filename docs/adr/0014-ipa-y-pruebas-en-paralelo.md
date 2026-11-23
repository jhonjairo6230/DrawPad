# 0014. IPA y pruebas en paralelo en el workflow

- **Estado:** Aceptada; cuándo se genera el `.ipa`, cambiado por [0023](0023-ipa-solo-al-fusionar.md)
- **Fecha:** 2026-11-16

## Contexto

El workflow hacía todo en serie: pruebas (unitarias y de interfaz) y, solo
si pasaban, el `.ipa`. Con las pruebas de interfaz, cada ejecución llegó a
más de 15 minutos, de los que compilar la app son unos 3.

La comprobación que más vale en este proyecto es **instalar la app en el
iPad y usarla**: el Pencil, los gestos y el aspecto no se pueden verificar en
el simulador. Esperar a las pruebas para poder instalar nada alargaba mucho
cada vuelta.

## Decisión

El workflow tiene **dos trabajos que corren a la vez**, cada uno en su
propio Mac:

- **IPA:** genera el proyecto, compila y publica `DrawPad-unsigned.ipa`
  (unos 3 minutos).
- **Pruebas:** pruebas unitarias y de interfaz en un simulador de iPad
  (unos 25 minutos).

El `.ipa` ya no depende de que las pruebas pasen. Esto cambia el punto del
[ADR 0004](0004-compilar-sin-mac.md) que decía que las pruebas se ejecutan
antes de generar el `.ipa`.

## Qué no cambia

El flujo de ramas y cómo se fusiona siguen como en el
[ADR 0002](0002-git-flow.md) y en [flujo-de-trabajo.md](../flujo-de-trabajo.md).
Esta decisión solo trata de cómo está organizado el workflow.

## Alternativas consideradas

- **Dejarlo en serie:** el `.ipa` solo existe si las pruebas pasan, a costa de
  esperar todo el tiempo de las pruebas para poder instalar.
- **Quitar o reducir las pruebas de interfaz:** son lentas, pero han cazado
  fallos reales (la app se cerraba al tocar el lienzo con el dedo).
- **Pruebas de interfaz solo en `develop` y `main`:** ahorra minutos en las
  ramas, pero un fallo de interfaz se descubriría más tarde. No se adopta;
  queda como opción si el tiempo vuelve a ser un problema.

## Consecuencias

- Hay `.ipa` en unos 3 minutos y probar en el iPad no espera a las pruebas.
- Que exista un `.ipa` solo significa que la app **compila**; si las pruebas
  pasaron lo dice el otro trabajo.
- Cada ejecución usa dos Mac a la vez (más minutos de Actions en total,
  gratuitos al ser el repo público).
- El proyecto se compila dos veces por ejecución (una en cada trabajo).
