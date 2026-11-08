import 'package:flutter_test/flutter_test.dart';
import 'package:vetdosis_pro/modules/laboratory/domain/lab_result.dart';

LabReferenceRange range({
  String analyte = 'hematocrito',
  String species = 'Canino',
  String unit = '%',
  double low = 37,
  double high = 55,
  String source = 'Fuente de prueba',
}) => LabReferenceRange(
  analyteKey: analyte,
  species: species,
  unit: unit,
  low: low,
  high: high,
  source: source,
);

LabResult result(double v, {String unit = '%', String key = 'hematocrito'}) =>
    LabResult(analyteKey: key, value: v, unit: unit);

void main() {
  group('Lectura contra rango', () {
    final ranges = [range()];
    test('dentro, debajo, arriba y límites incluidos', () {
      expect(result(45).evaluate('Canino', ranges), LabFlag.withinRange);
      expect(result(37).evaluate('Canino', ranges), LabFlag.withinRange);
      expect(result(55).evaluate('Canino', ranges), LabFlag.withinRange);
      expect(result(36.9).evaluate('Canino', ranges), LabFlag.below);
      expect(result(55.1).evaluate('Canino', ranges), LabFlag.above);
    });

    test('sin rango para la especie no se juzga', () {
      expect(result(10).evaluate('Felino', ranges), LabFlag.noReference);
      expect(result(10).evaluate('Canino', const []), LabFlag.noReference);
    });

    test('unidad distinta no se convierte ni se juzga', () {
      expect(
        result(0.45, unit: 'L/L').evaluate('Canino', ranges),
        LabFlag.unitMismatch,
      );
    });

    test('mayúsculas y espacios no cambian la coincidencia', () {
      expect(
        result(45, key: ' Hematocrito ').evaluate(' canino', ranges),
        LabFlag.withinRange,
      );
    });

    test('dos fuentes: se usa el rango más amplio', () {
      final two = [range(low: 37, high: 55), range(low: 35, high: 57, source: 'Otra')];
      expect(result(36).evaluate('Canino', two), LabFlag.withinRange);
      expect(result(58).evaluate('Canino', two), LabFlag.above);
      expect(result(45).sourcesFor('Canino', two), ['Fuente de prueba', 'Otra']);
    });
  });

  group('Validaciones', () {
    test('un rango sin fuente no existe', () {
      expect(() => range(source: '  '), throwsFormatException);
    });
    test('rango invertido', () {
      expect(() => range(low: 60, high: 50), throwsFormatException);
    });
    test('valor negativo o unidad vacía', () {
      expect(() => result(-1), throwsFormatException);
      expect(
        () => LabResult(analyteKey: 'x', value: 1, unit: ' '),
        throwsFormatException,
      );
    });
    test('lectura de texto: punto decimal, la coma se rechaza', () {
      expect(LabResult.parseValue('45.2'), 45.2);
      expect(LabResult.parseValue('1200'), 1200);
      expect(LabResult.parseValue('0.123'), 0.123);
      // En Mexico «1,200» son mil doscientos. Leyendo la coma como decimal
      // entraba como 1.2: mil veces menos, en silencio y en un dato clinico.
      expect(() => LabResult.parseValue('1,200'), throwsFormatException);
      expect(() => LabResult.parseValue('4,5'), throwsFormatException);
      expect(() => LabResult.parseValue('1,200.5'), throwsFormatException);
      expect(() => LabResult.parseValue('abc'), throwsFormatException);
    });
  });

  group('Toma de muestra', () {
    test('cuenta los resultados sin juicio', () {
      final panel = LabPanel(
        patientId: 'p1',
        species: 'Canino',
        collectedAt: DateTime(2026, 11, 8),
        results: [
          result(45),
          result(7, key: 'albumina', unit: 'g/dL'),
          result(0.4, unit: 'L/L', key: 'hematocrito2'),
        ],
      );
      final flags = panel.evaluate([range()]);
      expect(flags['hematocrito'], LabFlag.withinRange);
      expect(flags['albumina'], LabFlag.noReference);
      expect(panel.unjudged([range()]), 2);
    });

    test('no admite analito repetido ni toma vacía', () {
      expect(
        () => LabPanel(
          patientId: 'p',
          species: 'Canino',
          collectedAt: DateTime(2026),
          results: [result(40), result(41)],
        ),
        throwsFormatException,
      );
      expect(
        () => LabPanel(
          patientId: 'p',
          species: 'Canino',
          collectedAt: DateTime(2026),
          results: const [],
        ),
        throwsFormatException,
      );
    });
  });
}
