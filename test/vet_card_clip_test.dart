import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetdosis_pro/vet_ui.dart';

/// «Tu agenda» llegaba al telefono como «Íu agenda»: a la T le faltaba el
/// extremo izquierdo del travesano.
///
/// El Text de appointment_summary.dart es plano, sin recorte ni transformacion.
/// El recorte venia de la tarjeta: VetCard ponia el Material DENTRO del padding
/// y lo recortaba con el radio EXTERIOR, asi que la curva de la esquina caia
/// sobre la caja de contenido en vez de sobre el borde de la tarjeta.
///
/// Medido en el arbol de render, con radio 24 y padding 16:
///
///   RenderPadding        size=(280,160)  padding=EdgeInsets.all(17)
///     RenderPhysicalShape size=(246,126)  clipper=ShapeBorderClipper
///
/// El padding efectivo es 17 y no 16 porque el Border.all de la decoracion
/// suma 1 px. El recorte se aplicaba a esos 246x126 con radio 24.
///
/// La cuna que la curva se come es ancha arriba y nula abajo: a la primera
/// fila del contenido quita los 24 px enteros, a 4 px de profundidad unos 11,
/// y a 24 px ya nada. El titulo es el primer hijo del Column, asi que su
/// primera linea cae donde la cuna es mas ancha. Sobre una T mayuscula de 22 px
/// eso se lleva la mitad izquierda del travesano y deja una forma de Í.
///
/// Afecta a toda tarjeta cuyo primer hijo sea texto, no solo a Agenda.
///
/// La prueba no mide un ayudante ni la geometria declarada: saca el camino de
/// recorte que el RenderPhysicalShape usa al pintar y comprueba que contiene
/// al contenido. Dos sondas anteriores no servian y quedan anotadas para que
/// nadie las repita: `toImage()` se cuelga en prueba de widget, y
/// `TestRecordingCanvas` es ciega a este recorte porque no pasa por una orden
/// de lienzo.
void main() {
  const radius = 24.0;
  const marca = Color(0xFF00FF00);

  /// El recorte efectivo y el rectangulo del contenido, en coordenadas del
  /// propio recorte.
  Future<(ui.Path, Rect)> recorteYContenido(WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              height: 160,
              child: VetCard(
                radius: radius,
                child: SizedBox.expand(child: ColoredBox(color: marca)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    RenderPhysicalShape? recorte;
    void buscar(RenderObject nodo) {
      if (recorte == null) {
        if (nodo is RenderPhysicalShape) {
          recorte = nodo;
          return;
        }
        nodo.visitChildren(buscar);
      }
    }

    buscar(tester.renderObject(find.byType(VetCard)));
    expect(
      recorte,
      isNotNull,
      reason: 'VetCard deberia recortar con un RenderPhysicalShape',
    );
    final forma = recorte!;
    expect(
      forma.clipBehavior,
      isNot(Clip.none),
      reason: 'si dejara de recortar, esta prueba ya no vigila nada',
    );

    final contenido = tester.renderObject<RenderBox>(
      find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == marca,
      ),
    );
    final origen = forma.localToGlobal(Offset.zero);
    final caja = contenido.localToGlobal(Offset.zero) - origen;
    return (
      forma.clipper!.getClip(forma.size),
      caja & contenido.size,
    );
  }

  testWidgets('El recorte de VetCard contiene el contenido que el padding reserva', (
    tester,
  ) async {
    final (camino, contenido) = await recorteYContenido(tester);

    // Las cuatro esquinas del contenido tienen que caer dentro del recorte.
    final fuera = <String>[];
    for (final (nombre, punto) in [
      ('arriba-izquierda', contenido.topLeft),
      ('arriba-derecha', contenido.topRight - const Offset(1, 0)),
      ('abajo-izquierda', contenido.bottomLeft - const Offset(0, 1)),
      ('abajo-derecha', contenido.bottomRight - const Offset(1, 1)),
    ]) {
      if (!camino.contains(punto)) fuera.add('$nombre $punto');
    }
    expect(
      fuera,
      isEmpty,
      reason:
          'El recorte deja fuera ${fuera.length} esquina(s) del contenido: '
          '${fuera.join('; ')}. La curva de la esquina muerde la caja de '
          'contenido, y el primer hijo del Column pierde su esquina superior '
          'izquierda: «Tu agenda» se pinta como «Íu agenda».',
    );
  });

  testWidgets('La primera linea de texto no pierde pixeles por la izquierda', (
    tester,
  ) async {
    final (camino, contenido) = await recorteYContenido(tester);

    // Alto de una linea de titleLarge con su interlineado: ~26 px. Se recorre
    // el borde izquierdo de esa primera linea fila a fila.
    final perdidas = <String>[];
    for (var dy = 0; dy < 26; dy++) {
      final punto = contenido.topLeft + Offset(0, dy.toDouble());
      if (!camino.contains(punto)) perdidas.add('y+$dy');
    }
    expect(
      perdidas,
      isEmpty,
      reason:
          '${perdidas.length} de las 26 filas de la primera linea quedan '
          'fuera del recorte (${perdidas.take(8).join(', ')}...). Ahi es '
          'donde se pierde el travesano de la T.',
    );
  });
}
