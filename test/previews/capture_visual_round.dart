// Capturas de revision visual: cuenta, clinica y actividad son sinteticas.
//
// Reproducir:
// flutter test test/previews/capture_visual_round.dart \
//   --dart-define=VISUAL_ROUND_DIR=review/visual-round-20261111
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetdosis_pro/core/app.dart';
import 'package:vetdosis_pro/modules/auth/domain/clinic_membership.dart';
import 'package:vetdosis_pro/modules/auth/presentation/auth_screen.dart';
import 'package:vetdosis_pro/modules/auth/presentation/auth_view_model.dart';
import 'package:vetdosis_pro/modules/core/data/settings_repository.dart';
import 'package:vetdosis_pro/modules/core/presentation/core_view_model.dart';
import '../support/fake_auth.dart';
import '../forms_test.dart' show FakeForms;
import '../hospital_test.dart' show FakeAlarms, FakeHospital;
import 'package:vetdosis_pro/modules/hospital/application/hospital_alerts.dart';
import '../patients_test.dart' show FakePatients;
import 'capture_home_pilot.dart' show PreviewOperations;

class _PreviewForms extends FakeForms {
  @override
  Future<Map<String, dynamic>> branding(String clinicId) async => {};
}

const _dir = String.fromEnvironment(
  'VISUAL_ROUND_DIR',
  defaultValue: 'review/visual-round-20261111',
);

Future<void> _fonts() async {
  await (FontLoader(
    'Roboto',
  )..addFont(rootBundle.load('assets/fonts/DejaVuSans.ttf'))).load();
  final jakarta = FontLoader('PlusJakartaSans');
  for (final weight in const [400, 500, 600, 700, 800]) {
    jakarta.addFont(rootBundle.load('assets/fonts/PlusJakartaSans-$weight.ttf'));
  }
  await jakarta.load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
}

/// Avanza el reloj un tramo fijo en vez de esperar a que todo se detenga:
/// hay pantallas con indicadores de progreso que nunca se asientan.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  tester.takeException();
}

Future<void> _shot(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    for (final asset in const [
      'assets/brand/vetdosis-logo.png',
      'assets/brand/app-icon-transparent.png',
    ]) {
      await precacheImage(AssetImage(asset), key.currentContext!);
    }
  });
  await _settle(tester);
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_dir/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  for (final dark in [false, true]) {
    final tone = dark ? 'oscuro' : 'claro';
    testWidgets('Ronda visual · sesion iniciada · $tone', (tester) async {
      tester.view.physicalSize = const Size(390, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      await _fonts();
      final repo = FakeAuth()
        ..rows = [
          const ClinicMembership(
            clinicId: 'a',
            userId: 'user-a',
            role: ClinicRole.admin,
            clinicName: 'DEMO · Datos ficticios',
          ),
        ];
      final auth = AuthViewModel(repo);
      await auth.start();
      final core = CoreViewModel(
        SettingsRepository(),
        AppSettings(visualStyle: 'neu', brightness: dark ? 'dark' : 'light'),
      );
      final key = GlobalKey();
      final previous = debugDisableShadows;
      debugDisableShadows = false;
      try {
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: VetDosisApp(
              model: core,
              auth: auth,
              operations: PreviewOperations(false),
              patients: FakePatients(),
              hospital: FakeHospital(),
              hospitalAlerts: HospitalAlerts(
                FakeAlarms(),
                await SharedPreferences.getInstance(),
              ),
              forms: _PreviewForms(),
            ),
          ),
        );
        await _settle(tester);
        await _shot(tester, key, 'inicio-$tone');
        for (final page in const [
          'Cálculos clínicos',
          'Cálculo rápido',
          'Cálculos',
          'Formatos',
          'Más',
          'Pacientes',
          'Hospitalización',
          'Inventario',
          'Ajustes',
          'Vademécum',
          'Agenda',
          'Receta',
          'Caja',
        ]) {
          core.navigate(page);
          await _settle(tester);
          tester.takeException();
          await _shot(
            tester,
            key,
            '${page.toLowerCase().replaceAll(' ', '-')}-$tone',
          );
        }
        core.navigate('Inicio');
        await _settle(tester);
        tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
        await _settle(tester);
        await _shot(tester, key, 'menu-$tone');
        await tester.pumpWidget(const SizedBox());
        core.dispose();
        auth.dispose();
        await repo.controller.close();
      } finally {
        debugDisableShadows = previous;
      }
    });

    testWidgets('Ronda visual · acceso · $tone', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      await _fonts();
      final repo = FakeAuth()..userId = null;
      final auth = AuthViewModel(repo);
      await auth.start();
      final core = CoreViewModel(
        SettingsRepository(),
        AppSettings(visualStyle: 'neu', brightness: dark ? 'dark' : 'light'),
      );
      final key = GlobalKey();
      final previous = debugDisableShadows;
      debugDisableShadows = false;
      try {
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: VetDosisApp(model: core, auth: auth, requireAuth: true),
          ),
        );
        await _settle(tester);
        await _shot(tester, key, 'bienvenida-$tone');
        final app = tester.widget<VetDosisApp>(find.byType(VetDosisApp));
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: app.theme(dark ? Brightness.dark : Brightness.light),
              home: AuthScreen(model: auth),
            ),
          ),
        );
        await _settle(tester);
        await _shot(tester, key, 'acceso-$tone');
        await tester.pumpWidget(const SizedBox());
        core.dispose();
        auth.dispose();
        await repo.controller.close();
      } finally {
        debugDisableShadows = previous;
      }
    });
  }
}
