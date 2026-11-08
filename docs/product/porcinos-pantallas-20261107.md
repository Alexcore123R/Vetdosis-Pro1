# Porcinos: pantallas de cálculo y referencias (7 nov 2026)

Rama local: `feature/porcino-pantallas-20261107`, desde `main` (486b526). Sin commit ni push.
Alcance autorizado por Ale (7 nov): pantallas de Porcinos con datos locales. No toca Supabase.

## Qué agrega
- `domain/porcino_reference.dart`: tablas de referencia (consumo por fase, densidades por peso y piso, filas informativas).
- `domain/porcino_capacity.dart`: `SwineFlowPlan` (vientres → partos/semana, lechones, jaulas y lugares), `SiloSizing`, `SpaceEstimate`.
- `presentation/porcino_panels.dart`: paneles por actividad. `production_menu.dart` los muestra bajo Porcinos y conserva el control de acceso por «Cálculos clínicos».
- `test/porcino_panels_test.dart`: reproduce el Modelo 2400 (2400 vientres, factor 25, 10 destetados → 96 partos/semana, 384 jaulas, 960 lechones/semana).

## Fuente y límites
- Valores de las tablas de Grok en Drive (`Coordinacion_Agentes_VetDosis`, 6-7 nov 2026), extraídas de material de clase Pork School ago-2026 y de la asignatura Producción de Cerdos. Sin validación externa; no son metas ni límites operativos.
- Lactancia: 21 d (NRC 2012) y 28 d (ciclo de clase) se muestran como supuestos distintos. La app no decide cuál usar hasta que Ale lo defina.
- Cálculos de sesión: no guardan lotes. El guardado depende de `supabase/proposed/15L_porcino_produccion.sql`, que sigue sin aplicar ni revisar.

## Sin probar
- No se compiló ni se corrió `flutter test` (el entorno no tiene Flutter). Solo se verificó la sintaxis de Dart con un parser.
- No se corrió `dart format`.
- Posible choque con `feature/produccion-unidades-20261107`, que reescribe `production_menu.dart`.

## Pendiente
Reproductores y servicios, camadas y alimentación, engorda e indicadores (registros persistentes); decidir 21 vs 28 d; cifra del vademécum (662 vs 668).
