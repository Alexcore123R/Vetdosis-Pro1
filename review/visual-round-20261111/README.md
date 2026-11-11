# Ronda visual Neu · 11 nov 2026

Base: `integracion/apk-completo-20261111` (3d21e08), que es de donde sale el APK
que Ale tiene en el teléfono. Encargo de Ale con capturas del estado actual,
de las versiones anteriores que daba por buenas y de las maquetas objetivo.

Solo cambia el estilo Neu. El Clásico, los cálculos, permisos, textos clínicos
y la estructura de las calculadoras no se tocan.

- **Glow**: fuera de la tarjeta entera; queda solo en la franja de cabecera y
  muy tenue (0.55). La franja usa el tono de la sección apagado, como en las
  cabeceras anteriores. Vale para Inicio y para las calculadoras, que conservan
  sus divisiones y su contenido.
- **Cabecera de pantalla**: banda aqua → lila en la barra y hoja de contenido
  con esquinas redondeadas encima. El cajón abre con la misma banda.
- **Botón principal**: recorrido aqua → violeta de «Ingresar» / «Calcular».
  Blanco sobre el recorrido: 4.0:1 en el extremo aqua, 4.6:1 en el violeta.
- **Inicio**: módulos con placa en relieve y línea de apoyo (dato consultado o
  pista, nunca una cifra inventada), barras del gráfico con degradado y citas
  como renglones con barra de color y etiqueta de hora.
- **Barra inferior**: la pestaña activa es una placa clara redondeada.
- **Acceso y bienvenida**: velo de marca al fondo, título centrado, campos con
  icono y Google en placa oscura.
- **Pasos numerados** (Formatos y los demás que usan `VetSectionHeader` con
  `step`): pasan a tarjeta con el cuadro y el título arriba.

Capturas con cuenta y datos ficticios: [Inicio](inicio-claro.png) ·
[Inicio oscuro](inicio-oscuro.png) · [Cálculos clínicos](calculos-clinicos-claro.png) ·
[Formatos](formatos-claro.png) · [Secciones](secciones-claro.png) ·
[Menú](menu-claro.png) · [Acceso](acceso-claro.png) · [Bienvenida](bienvenida-claro.png).
El logotipo y la animación de bienvenida no cargan en el arnés de pruebas; en
el teléfono sí.

Reproducir:
`flutter test test/previews/capture_visual_round.dart --dart-define=VISUAL_ROUND_DIR=review/visual-round-20261111`

Validación: `flutter analyze` limpio y 816 pruebas pasan, 1 omitida (Flutter
3.47.6). Implementado; **no** revisado por CodeRabbit, **no** integrado, **no**
desplegado y **no** probado en teléfono.

Pendiente respecto a las maquetas: Laboratorio, Perfil MVZ, Hospitalización con
constantes y Vademécum rápido son pantallas con contenido propio, no solo
estilo; heredan la cabecera, tarjetas y botones nuevos pero su maquetación no
se rehízo en esta ronda.

Tablón: el issue #31 vive en otro repositorio, fuera del alcance de la sesión
que hizo este trabajo. Esta nota queda como registro local; nadie fue
notificado allí.
