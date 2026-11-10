import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetdosis_pro/modules/auth/domain/clinic_membership.dart';
import 'package:vetdosis_pro/modules/production/domain/production_unit.dart';
import 'package:vetdosis_pro/modules/production/domain/production_unit_repository.dart';
import 'package:vetdosis_pro/modules/production/presentation/production_menu.dart';
import 'package:vetdosis_pro/modules/production/presentation/production_units_screen.dart';

/// El menu y las unidades llegaron por ramas distintas. Esto comprueba la
/// costura: que el menu nuevo ofrece las unidades donde hay animales y no
/// donde la actividad es solo una herramienta de calculo.
class _RepoVacio implements ProductionUnitRepository {
  @override
  Future<List<ProductionUnit>> list(
    String userId,
    String clinicId, {
    String? species,
    String? activity,
  }) async => const [];

  @override
  Future<void> save(String userId, ProductionUnit unit) async {}

  @override
  Future<void> remove(String userId, String id) async {}
}

const _admin = ClinicMembership(
  clinicId: 'c1',
  clinicName: 'Granja',
  role: ClinicRole.admin,
  userId: 'ana',
);

Widget _app({ProductionUnitRepository? units}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: ProductionMenu(member: _admin, units: units, onNavigate: (_) {}),
    ),
  ),
);

Future<void> _elige(WidgetTester tester, String texto) async {
  await tester.ensureVisible(find.text(texto));
  await tester.tap(find.text(texto));
  await tester.pumpAndSettle();
}

void main() {
  test('El catalogo separa actividades con animales de las de calculo', () {
    expect(isKnownProductionArea('Porcinos', 'Maternidad y destete'), true);
    expect(isKnownProductionArea('Porcinos', 'Bioseguridad y ambiente'), false);
    expect(isKnownProductionArea('Porcinos', 'Planeación financiera'), false);
    // Toda actividad sin unidades tiene que existir en el catalogo: si se
    // renombra una y no la otra, el menu volveria a ofrecerle unidades.
    final todas = productionSpecies.values.expand((a) => a).toSet();
    expect(todas.containsAll(productionActivitiesWithoutUnits), true);
  });

  testWidgets('Una actividad con animales abre sus unidades', (tester) async {
    await tester.pumpWidget(_app(units: _RepoVacio()));
    await _elige(tester, 'Porcinos');
    expect(find.text('Abrir unidades'), findsNothing);
    await _elige(tester, 'Maternidad y destete');
    expect(find.text('Unidades de Maternidad y destete'), findsOneWidget);
    await _elige(tester, 'Abrir unidades');
    expect(find.byType(ProductionUnitsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Las actividades de calculo no ofrecen unidades', (tester) async {
    await tester.pumpWidget(_app(units: _RepoVacio()));
    await _elige(tester, 'Porcinos');
    for (final actividad in productionActivitiesWithoutUnits) {
      await _elige(tester, actividad);
      expect(find.text('Abrir unidades'), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sin almacen el menu sigue y no promete guardado', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await _elige(tester, 'Bovinos');
    await _elige(tester, 'Leche');
    expect(find.text('Abrir unidades'), findsNothing);
    expect(find.textContaining('aún no permiten guardar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
