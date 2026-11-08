# Mapa de integración y evidencia — 2026-11-08

> **Tipo:** auditoría técnica de solo lectura materializada como documento.
> **Alcance:** snapshot del repositorio GitLab `vetdosis/vetdosispro` al 2026-11-08.
> **No es autorización para fusionar ramas ni aplicar SQL.** No se modificó código de la aplicación, configuración de CI ni esquema de Supabase.

## Resumen ejecutivo

La rama `apk/beta-20261108` avanzó después del último APK verificado. El pipeline exitoso más reciente que pude asociar a esa rama compiló el commit `91d7b146`, mientras que el head actual observado es `07078f37`. Por tanto, la compilación aprobada no valida el estado actual de la rama.

La evidencia de CI sí es mejor de lo que indicaba el resumen estructurado de pruebas: el log del job de APK muestra `flutter analyze` limpio y `772` pruebas aprobadas, con `1` omitida. El pipeline de precios muestra `748` aprobadas y `1` omitida. Ambas ejecuciones son reales, pero corresponden a SHA anteriores a sus respectivos heads actuales.

## Evidencia verificada

| Referencia | SHA probado | Resultado observado | Límite |
|---|---|---|---|
| `apk/beta-20261108` | `91d7b146` | Pipeline 3042284697 exitoso; analyze limpio; 772 tests aprobados, 1 omitido; artefacto APK ARM64 | No valida el head actual `07078f37` |
| `propuesta/precios-busqueda-20261108` | `e62afe95` | Pipeline 3042557800 exitoso; analyze limpio; 748 tests aprobados, 1 omitido | La rama avanzó después a `63e4ed50`; no se aplicó la propuesta SQL |
| `main` | `43239205` | Rama por defecto y protegida | No contiene los cambios posteriores de las ramas de trabajo |

Los registros de job se inspeccionaron directamente. La ausencia de un reporte estructurado de pruebas no debe confundirse con ausencia de ejecución: los logs contienen el resumen final de Flutter Test.

## Mapa de ramas y dependencias

### Integración ya presente en la rama APK

- `feature/porcino-calculadoras-20261108` aporta la corrección del parser de precios mediante el commit `ff1f4a38`, que es padre del head APK `07078f37`.
- `tema/morado-primario-20261108` y `texto/jerarquia-visual-20261108` ya están representadas en la historia de trabajo que alimenta la rama APK.
- La rama APK también incorpora una corrección del parser: rechaza importes con más de dos decimales en vez de reinterpretarlos silenciosamente.

### Cambios que requieren integración deliberada

- `feature/produccion-unidades-20261107`: modelo y almacenamiento local Sembast; el aislamiento por cuenta es parte del diseño. No equivale a sincronización remota con Supabase.
- `feature/notificaciones-personales-20261106`: requiere revisar junto con producción los puntos de inicialización y navegación compartidos. No asumir sincronización entre dispositivos ni alarmas garantizadas con la app cerrada.
- `feature/visita-campo-y-analiticas-20261108`: el head observado es `38c0b6b5`. El cambio de laboratorio conserva lecturas separadas por fuente cuando los rangos discrepan; el propio commit indica que no fue compilado en su entorno. Debe pasar CI y revisión de presentación antes de integrarse.
- `propuesta/precios-busqueda-20261108`: contiene una propuesta SQL y cambios de caché; no aplicarla hasta revisar aislamiento por clínica/tenant, permisos, cuotas y estrategia de fallo del proveedor.

## Riesgos y criterios de aceptación

1. **Deriva entre head y artefacto:** lanzar CI sobre el SHA exacto que se pretende distribuir. No etiquetar el APK de `91d7b146` como build de `07078f37`.
2. **Producción + notificaciones:** revisar conflictos de `main.dart`, `app.dart`, rutas, inicialización y dependencias. Ejecutar pruebas de aislamiento con dos cuentas y dos espacios de trabajo.
3. **Laboratorio:** comprobar resultados con rangos coincidentes, divergentes, unidades distintas y ausencia de rango; confirmar que la UI muestra cada fuente junto a su valor y no inventa un rango combinado.
4. **Porcinos:** mantener trazabilidad de fuentes y unidades; no elevar parámetros de material didáctico a valores clínicos validados sin revisión externa.
5. **Precios:** no aplicar SQL hasta demostrar aislamiento por clínica y límites de consumo; probar entradas ambiguas y fallos de búsqueda.
6. **Beta:** además de analyze/tests/build, falta evidencia de walkthrough en dispositivo, restauración de respaldo y pruebas integradas de Auth/RLS/Storage/Edge Functions en dos clínicas ficticias.

## Orden propuesto (no ejecutado)

1. Congelar un SHA candidato de la rama APK y volver a ejecutar CI completo.
2. Revisar y probar producción y notificaciones como un conjunto, resolviendo los archivos compartidos antes de abrir una integración.
3. Integrar analíticas/laboratorio en una rama candidata, ejecutar CI y revisar la UI con datos de rangos múltiples.
4. Tratar SQL de precios como cambio independiente, con revisión de RLS/cuotas y pruebas específicas antes de cualquier aplicación.
5. Generar un APK desde el SHA integrado final y hacer pruebas en dispositivo y de flujos remotos antes de llamarlo beta validada.

## Límites de esta auditoría

- No se ejecutó ningún merge.
- No se modificaron ramas existentes ni archivos de aplicación.
- No se aplicaron migraciones ni se tocaron secretos, variables CI o datos de Supabase.
- Los resultados de CI prueban únicamente el SHA y los jobs concretos indicados; no prueban por sí solos comportamiento clínico ni funcionamiento en dispositivos reales.
- Este documento es un mapa de trabajo, no una certificación de seguridad, clínica ni de publicación.
