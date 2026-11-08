import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetdosis_pro/modules/production/domain/porcino_reference.dart';
import 'package:vetdosis_pro/modules/production/presentation/porcino_panels.dart';
import 'package:vetdosis_pro/vet_ui.dart';

/// Un dato clinico suele tener mas de una referencia legitima: la frecuencia
/// cardiaca del cachorro no es la del adulto, y la lactancia porcina son 21
/// dias en NRC 2012 y 28 en el ciclo de clase.
///
/// Lo que esta tarjeta tiene que garantizar no es que se vean las citas, sino
/// que cada cita quede pegada a SU valor. Con una sola nota al pie no se sabe
/// que dato viene de donde, y eso es justo lo que hay que poder distinguir
/// cuando las fuentes no concuerdan.
void main() {
  testWidgets('Cada cita se pinta junto al valor al que pertenece', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VetReferenceCard(
              title: 'Rangos fisiológicos de canino',
              rows: [
                VetReferenceRow(
                  label: 'Frecuencia cardíaca',
                  values: [
                    VetReferenceValue(
                      '60 – 140 lpm',
                      qualifier: 'Adulto',
                      source: 'Fuente A',
                    ),
                    VetReferenceValue(
                      '180 – 200 lpm',
                      qualifier: 'Cachorro',
                      source: 'Fuente B',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Las dos referencias del mismo dato, con su matiz y su cita.
    for (final texto in ['Fuente A', 'Fuente B', 'Adulto: ', 'Cachorro: ']) {
      expect(
        find.textContaining(texto, findRichText: true),
        findsOneWidget,
        reason: 'falta «$texto»',
      );
    }

    // Y cada cita debajo de su propio valor, no agrupadas al final: la de la
    // primera referencia tiene que quedar por encima del segundo valor.
    final citaA = tester.getRect(find.text('Fuente A'));
    final citaB = tester.getRect(find.text('Fuente B'));
    final segundoValor = tester.getRect(
      find.textContaining('Cachorro: ', findRichText: true),
    );
    expect(
      citaA.bottom,
      lessThanOrEqualTo(segundoValor.top),
      reason: 'la cita del primer valor cae por debajo del segundo valor',
    );
    expect(citaB.top, greaterThan(segundoValor.top));
  });

  testWidgets('Un dato con una sola referencia hereda la cita del bloque', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PorcinoReferenceCard(
              title: 'Referencias de reproducción',
              rows: porcinoReproductionReference,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // La lactancia trae sus dos supuestos, cada uno con su fuente distinta.
    expect(find.textContaining('NRC 2012'), findsOneWidget);
    expect(
      find.textContaining('21 días', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('28 días', findRichText: true),
      findsOneWidget,
    );
    // Y una fila sin referencias propias cita la fuente del bloque.
    expect(find.textContaining('Pork School'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
