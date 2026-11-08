import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetdosis_pro/core/app.dart';
import 'package:vetdosis_pro/modules/core/data/settings_repository.dart';
import 'package:vetdosis_pro/modules/core/presentation/core_view_model.dart';
import 'package:vetdosis_pro/vet_ui/vet_theme.dart';

/// Los controles de seleccion llevaban un borde gris fijo que pesaba mas que
/// su propia palabra y los dejaba planos. La regla nueva: linea solo cuando
/// esta elegido, y del primario.
void main() {
  ThemeData tema(Brightness brightness) => VetDosisApp(
    model: CoreViewModel(SettingsRepository(), const AppSettings()),
  ).theme(brightness);

  for (final brightness in Brightness.values) {
    final modo = brightness.name;

    test('En $modo el chip no lleva linea en reposo y si al elegirlo', () {
      final t = tema(brightness);
      final side = t.chipTheme.side! as WidgetStateBorderSide;
      expect(
        side.resolve(const <WidgetState>{}),
        BorderSide.none,
        reason: 'en reposo lo que separa el chip del fondo es el relieve',
      );
      final elegido = side.resolve(const {WidgetState.selected})!;
      expect(elegido.color, t.colorScheme.primary);
      expect(elegido.width, greaterThan(0));
    });

    test('En $modo el boton de linea sigue la misma regla', () {
      final t = tema(brightness);
      final side = t.outlinedButtonTheme.style!.side!;
      expect(side.resolve(const <WidgetState>{}), BorderSide.none);
      expect(
        side.resolve(const {WidgetState.pressed})!.color,
        t.colorScheme.primary,
      );
      expect(side.resolve(const {WidgetState.disabled}), BorderSide.none);
    });

    test('En $modo el boton de linea se levanta y se hunde al pulsar', () {
      final elevacion = tema(brightness).outlinedButtonTheme.style!.elevation!;
      final reposo = elevacion.resolve(const <WidgetState>{})!;
      expect(reposo, greaterThan(0), reason: 'en reposo va levantado');
      expect(
        elevacion.resolve(const {WidgetState.pressed})!,
        lessThan(reposo),
        reason: 'al pulsar se hunde, como una tecla',
      );
      expect(elevacion.resolve(const {WidgetState.disabled}), 0);
    });

    test('En $modo el tema usa la familia empaquetada', () {
      // Si la familia no llega al tema, la app vuelve a la del sistema sin
      // avisar y el cambio pasa inadvertido hasta verlo en el telefono.
      final t = tema(brightness);
      expect(t.textTheme.titleLarge!.fontFamily, VetTheme.fontFamily);
      expect(t.textTheme.bodyMedium!.fontFamily, VetTheme.fontFamily);
    });

    test('En $modo la indicacion va mas chica y en otro tono', () {
      final scale = VetTheme.textTheme(
        brightness,
        ColorScheme.fromSeed(
          seedColor: VetColors.purple,
          brightness: brightness,
        ),
      );
      expect(
        scale.bodySmall!.fontSize!,
        lessThan(scale.bodyMedium!.fontSize!),
      );
      expect(scale.bodySmall!.color, isNot(scale.bodyMedium!.color));
      expect(scale.labelSmall!.color, scale.bodySmall!.color);
    });
  }
}
