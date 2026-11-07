import 'package:flutter/material.dart';

import 'neu_identity.dart' show neuShadows;

/// Marca de VetDosis Pro: el arte real, con su transparencia intacta.
///
/// Antes se repintaba a mano con un `CustomPainter`, lo que estampaba un
/// mosaico opaco propio en lugar de usar el arte entregado. Ahora se muestra
/// el PNG de marca tal cual, sin fondo añadido, para que se apoye sobre
/// cualquier superficie —degradado, tarjeta de vidrio o tema oscuro— sin
/// recortar un rectángulo encima.
class VetDosisMark extends StatelessWidget {
  const VetDosisMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    // El arte es de 1024 px y aquí se dibuja a 34 o 132: se decodifica a la
    // medida real de pantalla para no mantener en memoria un mapa de bits
    // mucho mayor que el hueco donde se pinta.
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    final dark = Theme.of(context).brightness == Brightness.dark;
    // El relieve del sistema neumorfico, que al arte le faltaba: sin el, la
    // marca quedaba plana entre tarjetas que si lo llevan. Son las mismas
    // sombras del resto de la interfaz, no unas propias.
    //
    // El radio sale de medir el arte: su esquina redondeada es del 22.5% del
    // lado, asi que la sombra sigue su silueta en vez de un rectangulo.
    // Se pinta detras del PNG, cuyo alfa sigue mandando.
    //
    // La profundidad acompana al tamano: a 34 px de la barra un relieve
    // pensado para 132 quedaria desproporcionado.
    final depth = (size / 44).clamp(.5, 1.2);
    return Semantics(
      label: 'Logo VetDosis Pro',
      image: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * .225),
          boxShadow: neuShadows(dark, depth: depth),
        ),
        child: Image.asset(
          'assets/brand/app-icon-transparent.png',
          width: size,
          height: size,
          cacheWidth: pixels,
          cacheHeight: pixels,
          filterQuality: FilterQuality.medium,
          // Sin `color` ni fondo opaco: el alfa del PNG es el que manda.
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
