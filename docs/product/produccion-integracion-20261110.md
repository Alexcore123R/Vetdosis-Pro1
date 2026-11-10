# Producción: integración y lo que falta (10 nov 2026)

Rama `ccr-e3f37de5-wj9n98`, desde `main` (fb29b2a). Une dos ramas que tocaban el mismo menú y no se habían juntado.

## Qué se integró
- `feature/porcino-calculadoras-20261108` (PR #5): ventilación, capacidad inversa, bioseguridad, nitrógeno/huella gris/NCA y el estimador de inversión con su pantalla en Planeación financiera.
- `feature/produccion-unidades-20261107` (no tenía PR): unidades de producción (hato, lote, parvada, apiario) guardadas en la base local del dispositivo, para las siete especies.

## Cómo se resolvió el choque en `production_menu.dart`
- Se conserva el menú de tarjetas de `main`; la sección «Unidades» se reescribió con esos mismos componentes.
- El catálogo queda en `domain/production_catalog.dart` e incluye las dos actividades porcinas nuevas.
- «Bioseguridad y ambiente» y «Planeación financiera» son herramientas de cálculo, no grupos de animales: no ofrecen unidades y `isKnownProductionArea` rechaza guardarlas ahí.
- `test/production_menu_units_test.dart` cubre esa costura.

## Verificado
Flutter 3.47.6 (el del CI): `flutter analyze` sin hallazgos y `flutter test` completo en verde (800 pruebas, 1 omitida que ya lo estaba). No probado en teléfono. No desplegado. Sin revisión de CodeRabbit todavía.

## Lo que falta en Producción
| Área | Estado |
|---|---|
| Porcinos | Calculadoras de sesión en las cinco actividades y unidades guardadas. Faltan los registros: reproductores y servicios, camadas, alimentación, engorda e indicadores. |
| Aves | Postura (capacidad) e incubación tienen herramienta. Engorda no tiene ninguna. Faltan parvadas/ciclos y registros productivos. |
| Peces | Solo biomasa y ración de tilapia. Faltan calidad de agua, lotes y ciclos. |
| Bovinos, ovinos/caprinos, abejas, equinos | Solo unidades guardadas. Ninguna calculadora ni registro propio. |
| Todas | Las unidades viven solo en el dispositivo: no se sincronizan ni se respaldan en Supabase, y no se pueden editar ni borrar desde la pantalla (el almacén sí lo permite). |

## Decisiones pendientes de Ale
- Lactancia de 21 d (NRC 2012) o 28 d (ciclo de clase).
- NCA: confirmar la lectura de unidades en la p. 84 del dictamen. No está autorizado como cálculo regulatorio.
- Tablas de ventilación que no coinciden entre sí (engorda y destete cálido): se muestran ambas.
- El estimador de inversión depende de precios capturados a mano; la búsqueda de precios es la propuesta 15K (PR #6), sin aplicar.
- Quién lleva las tablas de Supabase para producción (las notas del 7 nov citan `supabase/proposed/15L_porcino_produccion.sql`, pero ese archivo no está en este repositorio).

## Tablón
El tablón (issue #31) está en otro repositorio al que esta sesión no tiene acceso; no se publicó nada ahí. Esta nota es el registro local a trasladar.
